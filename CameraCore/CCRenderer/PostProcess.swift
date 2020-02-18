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

import AVFoundation
import CoreVideo
import Foundation
import MetalCanvas
import MetalPerformanceShaders

extension CCRenderer {
    public class PostProcess: NSObject {
        private let postProcessQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRenderer.PostProcess")

        private let isDisplayLink: Bool
        public var renderLayers: [RenderLayerProtocol] = []

        fileprivate let errorType: CCRenderer.ErrorType = CCRenderer.ErrorType.render
        fileprivate let hasMPS: Bool = MPSSupportsMTLDevice(MCCore.device)
        fileprivate let filter: MPSImageLanczosScale = MPSImageLanczosScale(device: MCCore.device)
        fileprivate var counter: CMTimeValue = 0
        fileprivate var displayLink: CADisplayLink?

        fileprivate(set) var outTexture: CCTexture?

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        //

        private var _presentationTimeStamp: CMTime = CMTime()
        fileprivate(set) var presentationTimeStamp: CMTime {
            get {
                objc_sync_enter(self)
                let presentationTimeStamp: CMTime = self._presentationTimeStamp
                objc_sync_exit(self)
                return presentationTimeStamp
            }
            set {
                objc_sync_enter(self)
                self._presentationTimeStamp = newValue
                objc_sync_exit(self)
            }
        }

        private var _isProcess: Bool = false
        fileprivate(set) var isProcess: Bool {
            get {
                objc_sync_enter(self)
                let isProcess: Bool = self._isProcess
                objc_sync_exit(self)
                return isProcess
            }
            set {
                objc_sync_enter(self)
                self._isProcess = newValue
                objc_sync_exit(self)
            }
        }

        private var _currentCaptureItem: CCCapture.VideoCapture.CaptureData?
        fileprivate(set) var currentCaptureItem: CCCapture.VideoCapture.CaptureData? {
            get {
                objc_sync_enter(self)
                let currentCaptureItem: CCCapture.VideoCapture.CaptureData? = self._currentCaptureItem
                objc_sync_exit(self)
                return currentCaptureItem
            }
            set {
                objc_sync_enter(self)
                self._currentCaptureItem = newValue
                objc_sync_exit(self)
            }
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////

        fileprivate(set) var captureSize: Settings.PresetSize = Settings.PresetSize.p1280x720

        var onUpdate: ((_ texture: CCTexture) -> Void)?

        public init(isDisplayLink: Bool) {
            self.isDisplayLink = isDisplayLink
            super.init()
        }

        deinit {
            self.dispose()
            MCDebug.deinitLog(self)
        }
    }
}

public extension CCRenderer.PostProcess {
    func dispose() {
        self.displayLink?.invalidate()
        objc_sync_enter(self)
        for index in self.renderLayers.indices {
            guard self.renderLayers.indices.contains(index) else { continue }
            self.renderLayers[index].dispose()
        }
        objc_sync_exit(self)
    }
}

extension CCRenderer.PostProcess {
    func update(renderLayers: [RenderLayerProtocol]) {
        self.postProcessQueue.async { [weak self] in
            self?.renderLayers = renderLayers
        }
    }

    func process(captureData: CCCapture.VideoCapture.CaptureData, queue: DispatchQueue) throws {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
        let presentationTimeStamp: CMTime = captureData.presentationTimeStamp
        let presetSize: Settings.PresetSize = captureData.captureInfo.presetSize

        if self.renderLayers.isEmpty {
            self.presentationTimeStamp = presentationTimeStamp
            var outTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, colorPixelFormat: captureData.colorPixelFormat, planeIndex: 0)
            outTexture.presentationTimeStamp = presentationTimeStamp
            outTexture.presetSize = presetSize
            self.onUpdate?(outTexture)
            return
        }

        self.isProcess = true
        do {
            try self.process(pixelBuffer: pixelBuffer, captureData: captureData, queue: queue)
        } catch {
            self.isProcess = false
            throw self.errorType
        }
    }

    @discardableResult
    func updateOutTexture(captureSize: MCSize, colorPixelFormat: MTLPixelFormat) throws -> CCTexture {
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // 描画用テクスチャを生成
        guard
            Float(self.outTexture?.size.w ?? 0) != captureSize.w,
            let pixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: captureSize),
            let tex: CCTexture = try? CCTexture(pixelBuffer: pixelBuffer, colorPixelFormat: colorPixelFormat, planeIndex: 0)
        else { throw self.errorType }
        self.outTexture = tex
        return tex
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

private extension CCRenderer.PostProcess {
    func process(pixelBuffer: CVPixelBuffer, captureData: CCCapture.VideoCapture.CaptureData, queue: DispatchQueue) throws {
        var pixelBuffer: CVPixelBuffer = pixelBuffer
        guard var outTexture: CCTexture = self.outTexture else { return }

        //////////////////////////////////////////////////////////
        // renderSize
        let width: Int = CVPixelBufferGetWidth(pixelBuffer)
        let height: Int = CVPixelBufferGetHeight(pixelBuffer)
        let renderSize: MCSize = MCSize(w: width, h: height)
        //////////////////////////////////////////////////////////

        if outTexture.size != renderSize {
            outTexture = try updateOutTexture(captureSize: renderSize, colorPixelFormat: captureData.colorPixelFormat)
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // renderLayerCompositionInfo
        var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo(
            compositionTime: CMTime(value: self.counter, timescale: captureData.captureInfo.frameRate),
            captureInfo: captureData.captureInfo,
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
            guard let self = self else { return }
            self.isProcess = false

            self.presentationTimeStamp = captureData.presentationTimeStamp
            outTexture.presentationTimeStamp = captureData.presentationTimeStamp
            outTexture.captureVideoOrientation = captureData.captureVideoOrientation
            outTexture.presetSize = captureData.captureInfo.presetSize
            self.onUpdate?(outTexture)
        }

        try self.processRenderLayer(commandBuffer: commandBuffer, source: &pixelBuffer, destination: &outTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

private extension CCRenderer.PostProcess {
    func processRenderLayer(commandBuffer: MTLCommandBuffer, source: inout CVPixelBuffer, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        // CVPixelBufferからMetal処理用にCCTextureに変換
        var sourceTexture: CCTexture = try CCTexture(pixelBuffer: source, colorPixelFormat: renderLayerCompositionInfo.pixelFormat, planeIndex: 0)
        // まず destinationTextureにsourceTextureをコピーする。
        try self.textureBlitEncoder(commandBuffer: commandBuffer, source: sourceTexture, destination: &destination)
        for index in self.renderLayers.indices {
            guard self.renderLayers.indices.contains(index) else { continue }
            do {
                try self.renderLayers[index].process(commandBuffer: commandBuffer, source: sourceTexture, destination: &destination, renderLayerCompositionInfo: &renderLayerCompositionInfo)

                // 各レイヤー処理の後に destination の BitmapDataを sourceTextureにコピーする。
                try self.textureBlitEncoder(commandBuffer: commandBuffer, source: destination, destination: &sourceTexture)
            } catch {
                MCDebug.log(error)
            }
        }
    }

    func textureBlitEncoder(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture) throws {
        guard
            source.size == destination.size,
            let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        else { throw RenderLayerErrorType.renderingError }
        blitEncoder.copy(from: source.texture,
                         sourceSlice: 0,
                         sourceLevel: 0,
                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSizeMake(source.texture.width, source.texture.height, source.texture.depth),
                         to: destination.texture,
                         destinationSlice: 0,
                         destinationLevel: 0,
                         destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder.endEncoding()
    }
}

// MARK: - pipe

extension CCRenderer.PostProcess {
    func pipe(camera: CCCapture.Camera) throws -> CCRenderer.PostProcess {
        let captureSize: MCSize = camera.property.captureInfo.presetSize.size(orientation: Configuration.shared.currentUIInterfaceOrientation)
        try self.updateOutTexture(captureSize: captureSize, colorPixelFormat: MTLPixelFormat.bgra8Unorm)
        if self.isDisplayLink {
            self.displayLink = CADisplayLink(target: self, selector: #selector(updateDisplay))
            self.displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
            camera.onUpdateCaptureData = { [weak self] (currentCaptureItem: CCCapture.VideoCapture.CaptureData) in
                // CADisplayLinkのloopで参照されるのでQueueを揃える。
                self?.postProcessQueue.sync { [weak self] in
                    self?.currentCaptureItem = currentCaptureItem
                }
            }
        } else {
            camera.onUpdateCaptureData = { [weak self] (currentCaptureItem: CCCapture.VideoCapture.CaptureData) in
                self?.process(currentCaptureItem: currentCaptureItem)
            }
        }

        return self
    }

    @objc private func updateDisplay() {
        guard let currentCaptureItem: CCCapture.VideoCapture.CaptureData = self.currentCaptureItem else { return }
        guard
            !self.isProcess,
            currentCaptureItem.presentationTimeStamp != self.presentationTimeStamp
        else { return }
        self.postProcessQueue.sync { [weak self] in
            do {
                try self?.process(captureData: currentCaptureItem, queue: CCCapture.videoOutputQueue)
            } catch {
                MCDebug.log("CCRenderer.PostProcess: process error")
            }
        }
    }

    private func process(currentCaptureItem: CCCapture.VideoCapture.CaptureData) {
        guard
            !self.isProcess,
            currentCaptureItem.presentationTimeStamp != self.presentationTimeStamp
        else { return }
        do {
            try self.process(captureData: currentCaptureItem, queue: CCCapture.videoOutputQueue)
        } catch {
            MCDebug.log("CCRenderer.PostProcess: process error")
        }
    }
}
