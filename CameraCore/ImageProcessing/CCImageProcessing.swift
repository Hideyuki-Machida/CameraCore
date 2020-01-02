//
//  CCImageProcessing.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/01.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import CoreVideo
import Foundation
import MetalCanvas
import MetalPerformanceShaders

public struct CCImageProcessing {
    private init() {} // このstructはnamespace用途なのでインスタンス化防止

    public class PostProcess: NSObject {
        public var renderLayers: [RenderLayerProtocol] = []

        fileprivate let errorType: CCRenderer.ErrorType = CCRenderer.ErrorType.render
        fileprivate let hasMPS: Bool = MCTools.shard.hasMPS
        fileprivate let filter: MPSImageLanczosScale = MPSImageLanczosScale(device: MCCore.device)
        fileprivate var counter: CMTimeValue = 0

        fileprivate(set) var outTexture: MCTexture?
        fileprivate(set) var presentationTimeStamp: CMTime = CMTime()
        fileprivate(set) var isProcess: Bool = false

        var onUpdate: ((_ texture: MCTexture, _ presentationTimeStamp: CMTime) -> Void)?
        var onUpdatePixelBuffer: ((_ pixelBuffer: CVPixelBuffer, _ presentationTimeStamp: CMTime) -> Void)?
        
        deinit {
            MCDebug.deinitLog(self)
        }
    }
}

extension CCImageProcessing.PostProcess {
    func update(renderLayers: [RenderLayerProtocol]) {
        self.renderLayers = renderLayers
    }

    func process(captureData: CCRenderer.VideoCapture.CaptureData, queue: DispatchQueue) throws {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
        let presentationTimeStamp: CMTime = CMSampleBufferGetPresentationTimeStamp(captureData.sampleBuffer)

        if self.renderLayers.count == 0 {
            self.onUpdatePixelBuffer?(pixelBuffer, presentationTimeStamp)
            return
        }

        self.isProcess = true
        do {
            try self.process(pixelBuffer: pixelBuffer, captureData: captureData, presentationTimeStamp: presentationTimeStamp, queue: queue)
        } catch {
            self.isProcess = false
            throw self.errorType
        }
    }
    
    func updateOutTexture(captureSize: CGSize, colorPixelFormat: MTLPixelFormat) -> MCTexture? {
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // 描画用テクスチャを生成
        guard
            CGFloat(self.outTexture?.width ?? 0) != captureSize.width,
            var pixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: captureSize),
            let tex: MCTexture = try? MCTexture.init(pixelBuffer: &pixelBuffer, colorPixelFormat: colorPixelFormat, planeIndex: 0)
        else { return nil }
        self.outTexture = tex
        return tex
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

private extension CCImageProcessing.PostProcess {
    func process(pixelBuffer: CVPixelBuffer, captureData: CCRenderer.VideoCapture.CaptureData, presentationTimeStamp: CMTime, queue: DispatchQueue) throws {
        var pixelBuffer: CVPixelBuffer = pixelBuffer
        guard var outTexture: MCTexture = self.outTexture else { return }

        //////////////////////////////////////////////////////////
        // renderSize
        let width: Int = CVPixelBufferGetWidth(pixelBuffer)
        let height: Int = CVPixelBufferGetHeight(pixelBuffer)
        let renderSize: CGSize = CGSize(width: width, height: height)
        //////////////////////////////////////////////////////////

        if outTexture.size.toCGSize() == renderSize {
        } else {
            guard let outTex = updateOutTexture(captureSize: renderSize, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else {
                throw self.errorType
            }
            outTexture = outTex
        }
        
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
                self?.presentationTimeStamp = presentationTimeStamp
                self?.onUpdate?(outTexture, presentationTimeStamp)
                self?.isProcess = false
            }
        }

        try self.processRenderLayer(commandBuffer: commandBuffer, source: &pixelBuffer, destination: &outTexture,frameRate: captureData.frameRate, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

private extension CCImageProcessing.PostProcess {
    func processRenderLayer(commandBuffer: MTLCommandBuffer, source: inout CVPixelBuffer, destination: inout MCTexture, frameRate: Int32, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        let sourceTexture: MCTexture = try MCTexture.init(pixelBuffer: &source, colorPixelFormat: MTLPixelFormat.bgra8Unorm, planeIndex: 0)
        for index in self.renderLayers.indices {
            guard self.renderLayers.indices.contains(index) else { continue }
            do {
                try self.renderLayers[index].process(commandBuffer: commandBuffer, source: sourceTexture, destination: &destination, renderLayerCompositionInfo: &renderLayerCompositionInfo)
            } catch {
                MCDebug.log(error)
            }
        }
    }

    func updateTexture(commandBuffer: MTLCommandBuffer, source: MTLTexture, destination: MTLTexture, renderSize: CGSize) {
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
