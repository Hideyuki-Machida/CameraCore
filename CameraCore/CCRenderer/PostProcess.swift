//
//  Process.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/12/26.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import CoreVideo
import Foundation
import MetalCanvas
import MetalPerformanceShaders

extension CCRenderer {
    public class PostProcess {
        fileprivate let errorType: CCRenderer.ErrorType = CCRenderer.ErrorType.render
        fileprivate let hasMPS: Bool = MCTools.shard.hasMPS
        fileprivate let filter: MPSImageLanczosScale = MPSImageLanczosScale(device: MCCore.device)
        fileprivate var counter: CMTimeValue = 0
        fileprivate var renderLayers: [RenderLayerProtocol] = []

        fileprivate(set) var presentationTimeStamp: CMTime = CMTime()
        fileprivate(set) var outTexture: MTLTexture?
        fileprivate(set) var isProcess: Bool = false

        var onUpdate: ((_ pixelBuffer: CVPixelBuffer) -> Void)?

        deinit {
            MCDebug.deinitLog(self)
        }
    }
}

extension CCRenderer.PostProcess {
    func update(renderLayers: [RenderLayerProtocol]) {
        self.renderLayers = renderLayers
    }

    func process(captureData: CCRenderer.VideoCapture.CaptureData, queue: DispatchQueue) throws {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
        let presentationTimeStamp: CMTime = CMSampleBufferGetPresentationTimeStamp(captureData.sampleBuffer)

        self.isProcess = true
        do {
            try self.process(pixelBuffer: pixelBuffer, captureData: captureData, presentationTimeStamp: presentationTimeStamp, queue: queue)
        } catch {
            self.isProcess = false
            throw self.errorType
        }
    }

    func updateOutTexture(captureSize: MCSize, colorPixelFormat: MTLPixelFormat) {
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // 描画用テクスチャを生成
        guard
            Float(self.outTexture?.width ?? 0) != captureSize.w,
            var pixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: captureSize)
        else { return }
        self.outTexture = MCCore.texture(pixelBuffer: &pixelBuffer, colorPixelFormat: colorPixelFormat)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

private extension CCRenderer.PostProcess {
    func process(pixelBuffer: CVPixelBuffer, captureData: CCRenderer.VideoCapture.CaptureData, presentationTimeStamp: CMTime, queue: DispatchQueue) throws {
        guard let outTexture: MTLTexture = self.outTexture else { return }

        var pixelBuffer: CVPixelBuffer = pixelBuffer

        //////////////////////////////////////////////////////////
        // renderSize
        let width: Int = CVPixelBufferGetWidth(pixelBuffer)
        let height: Int = CVPixelBufferGetHeight(pixelBuffer)
        let renderSize: MCSize = MCSize(w: width, h: height)
        //////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // renderLayerCompositionInfo
        var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo(
            compositionTime: CMTime(value: self.counter, timescale: captureData.frameRate),
            timeRange: CMTimeRange.zero,
            percentComplete: 0.0,
            renderSize: renderSize,
            metadataObjects: captureData.metadataObjects ?? [],
            depthData: captureData.depthData,
            queue: queue
        )
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        self.counter += 1

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // process
        guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { throw self.errorType }
        defer {
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        commandBuffer.addCompletedHandler { [weak self] _ in
            queue.async { [weak self] in
                self?.isProcess = false
                self?.presentationTimeStamp = presentationTimeStamp
                self?.outTexture = outTexture
                self?.onUpdate?(pixelBuffer)
            }
        }

        self.processRenderLayer(commandBuffer: commandBuffer, originalPixelBuffer: &pixelBuffer, frameRate: captureData.frameRate, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        guard let rgbTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, colorPixelFormat: captureData.colorPixelFormat) else { throw self.errorType }
        self.updateTexture(commandBuffer: commandBuffer, source: rgbTexture, destination: outTexture, renderSize: renderLayerCompositionInfo.renderSize)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

private extension CCRenderer.PostProcess {
    func processRenderLayer(commandBuffer: MTLCommandBuffer, originalPixelBuffer: inout CVPixelBuffer, frameRate: Int32, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) {
        /*
        for index in self.renderLayers.indices {
            guard self.renderLayers.indices.contains(index) else { continue }
            if var renderLayer: MetalRenderLayerProtocol = self.renderLayers[index] as? MetalRenderLayerProtocol {
                do {
                    try self.processMetalRenderLayer(renderLayer: &renderLayer, commandBuffer: commandBuffer, pixelBuffer: &originalPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
                } catch {
                    MCDebug.log(error)
                }
            } else if var renderLayer: CVPixelBufferRenderLayerProtocol = self.renderLayers[index] as? CVPixelBufferRenderLayerProtocol {
                do {
                    try renderLayer.process(commandBuffer: commandBuffer, pixelBuffer: &originalPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
                } catch {
                    MCDebug.log(error)
                }
            }
        }
 */
    }
/*
    func processMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard
            var textureCache: CVMetalTextureCache = MCCore.textureCache,
            let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm),
            var destinationTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat)
        else { throw self.errorType }
        try renderLayer.process(commandBuffer: commandBuffer, source: sourceTexture, destination: &destinationTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
    }
*/
    func updateTexture(commandBuffer: MTLCommandBuffer, source: MTLTexture, destination: MTLTexture, renderSize: MCSize) {
        ////////////////////////////////////////////////////////////
        //
        var commandBuffer: MTLCommandBuffer = commandBuffer
        ////////////////////////////////////////////////////////////
        if self.hasMPS {
            ////////////////////////////////////////////////////////////
            // previewScale encode
            let scale: Double = Double(destination.width) / Double(source.width)
            var transform: MPSScaleTransform = MPSScaleTransform(scaleX: scale, scaleY: scale, translateX: 0, translateY: 0)
            withUnsafePointer(to: &transform) { (transformPtr: UnsafePointer<MPSScaleTransform>) -> Void in
                self.filter.scaleTransform = transformPtr
                self.filter.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: destination)
            }
            ////////////////////////////////////////////////////////////
        } else {
            do {
                ////////////////////////////////////////////////////////////
                // previewScale encode
                let texture: MCTexture = try MCTexture(texture: source)
                var destinationTexture: MCTexture = try MCTexture(texture: destination)
                let scale: Float = Float(destinationTexture.width) / Float(texture.width)
                let canvas: MCCanvas = try MCCanvas(destination: &destinationTexture, orthoType: MCCanvas.OrthoType.topLeft)
                let imageMat: MCGeom.Matrix4x4 = MCGeom.Matrix4x4(scaleX: scale, scaleY: scale, scaleZ: 1.0)

                try canvas.draw(commandBuffer: &commandBuffer, objects: [
                    try MCPrimitive.Image(
                        texture: texture,
                        position: SIMD3<Float>(x: Float(destinationTexture.width) / 2.0, y: Float(destinationTexture.height) / 2.0, z: 0),
                        transform: imageMat,
                        anchorPoint: .center
                    ),
                ])
                ////////////////////////////////////////////////////////////
            } catch {
                MCDebug.log("updatePixelBuffer error")
            }
        }
    }
}
