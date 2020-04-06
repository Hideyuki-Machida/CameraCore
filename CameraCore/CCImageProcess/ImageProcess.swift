//
//  ImageProcess.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/03/22.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import CoreVideo
import Foundation
import MetalCanvas
import MetalPerformanceShaders
import ARKit

extension CCImageProcess {
    public class ImageProcess: NSObject, CCComponentProtocol {

        // MARK: - CCComponentProtocol
        public let setup: CCImageProcess.ImageProcess.Setup = CCImageProcess.ImageProcess.Setup()
        public let triger: CCImageProcess.ImageProcess.Triger = CCImageProcess.ImageProcess.Triger()
        public let pipe: CCImageProcess.ImageProcess.Pipe = CCImageProcess.ImageProcess.Pipe()
        public var debug: CCComponentDebug?

        private let imageProcessQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRenderer.PostProcess")
        private let imageProcessCompleteQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRenderer.PostProcess.Complete")

        //private let imageProcessQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRenderer.PostProcess", attributes: DispatchQueue.Attributes.concurrent)
        //private let imageProcessCompleteQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRenderer.PostProcess.Complete", attributes: DispatchQueue.Attributes.concurrent)
        
        
        fileprivate let errorType: CCRenderer.ErrorType = CCRenderer.ErrorType.render
        fileprivate let hasMPS: Bool = MPSSupportsMTLDevice(MCCore.device)
        fileprivate let filter: MPSImageLanczosScale = MPSImageLanczosScale(device: MCCore.device)
        fileprivate var counter: CMTimeValue = 0

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        //

        private var _renderLayers: [RenderLayerProtocol] = []
        public var renderLayers: [RenderLayerProtocol] {
            get {
                objc_sync_enter(self)
                let renderLayers: [RenderLayerProtocol] = self._renderLayers
                objc_sync_exit(self)
                return renderLayers
            }
            set {
                objc_sync_enter(self)
                self._renderLayers = newValue
                objc_sync_exit(self)
            }
        }

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

        ///////////////////////////////////////////////////////////////////////////////////////////////////

        fileprivate(set) var captureSize: Settings.PresetSize = Settings.PresetSize.p1280x720

        public init(isDisplayLink: Bool) {
            super.init()
            self.setup.imageProcess = self
            self.triger.imageProcess = self
            self.pipe.imageProcess = self
            self.pipe.isDisplayLink = isDisplayLink
        }

        deinit {
            self.dispose()
            MCDebug.deinitLog(self)
        }
    }
}

extension CCImageProcess.ImageProcess {
    func update(renderLayers: [RenderLayerProtocol]) {
        self.imageProcessQueue.async { [weak self] in
            self?.renderLayers = renderLayers
        }
    }

    func process(captureData: CCCapture.VideoCapture.CaptureData, queue: DispatchQueue) throws {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
        let presentationTimeStamp: CMTime = captureData.presentationTimeStamp
        let presetSize: Settings.PresetSize = captureData.captureInfo.presetSize

        if self.renderLayers.isEmpty {
            self.presentationTimeStamp = presentationTimeStamp
            var outTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: captureData.mtlPixelFormat, planeIndex: 0)
            outTexture.presentationTimeStamp = presentationTimeStamp
            outTexture.presetSize = presetSize
            self.pipe.outTexture = outTexture
            self.pipe.outPresentationTimeStamp = captureData.presentationTimeStamp
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
}

private extension CCImageProcess.ImageProcess {
    func process(pixelBuffer: CVPixelBuffer, captureData: CCCapture.VideoCapture.CaptureData, queue: DispatchQueue) throws {
        var pixelBuffer: CVPixelBuffer = pixelBuffer
        guard var outTexture: CCTexture = self.pipe.outTexture else { return }

        //////////////////////////////////////////////////////////
        // renderSize
        let width: Int = CVPixelBufferGetWidth(pixelBuffer)
        let height: Int = CVPixelBufferGetHeight(pixelBuffer)
        let renderSize: MCSize = MCSize(w: width, h: height)
        //////////////////////////////////////////////////////////

        if outTexture.size != renderSize {
            outTexture = try self.pipe.updateOutTexture(captureSize: renderSize, mtlPixelFormat: captureData.mtlPixelFormat)
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
            self.imageProcessCompleteQueue.async { [weak self] in
                guard let self = self else { return }
                self.presentationTimeStamp = captureData.presentationTimeStamp
                outTexture.presentationTimeStamp = captureData.presentationTimeStamp
                outTexture.captureVideoOrientation = captureData.captureVideoOrientation
                outTexture.presetSize = captureData.captureInfo.presetSize

                self.debug?.update()

                self.pipe.outTexture = outTexture
                self.pipe.outPresentationTimeStamp = captureData.presentationTimeStamp
            }
        }

        try self.processRenderLayer(commandBuffer: commandBuffer, source: &pixelBuffer, destination: &outTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

private extension CCImageProcess.ImageProcess {
    func processRenderLayer(commandBuffer: MTLCommandBuffer, source: inout CVPixelBuffer, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        // CVPixelBufferからMetal処理用にCCTextureに変換
        var sourceTexture: CCTexture = try CCTexture(pixelBuffer: source, mtlPixelFormat: renderLayerCompositionInfo.pixelFormat, planeIndex: 0)
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

fileprivate extension CCImageProcess.ImageProcess {
    func dispose() {
        self.setup._dispose()
        self.triger._dispose()
        self.pipe._dispose()
        objc_sync_enter(self)
        for index in self.renderLayers.indices {
            guard self.renderLayers.indices.contains(index) else { continue }
            self.renderLayers[index].dispose()
        }
        objc_sync_exit(self)
    }
}

extension CCImageProcess.ImageProcess {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var imageProcess: CCImageProcess.ImageProcess?
        fileprivate func _dispose() {
            self.imageProcess = nil
        }
    }

    // MARK: - Triger
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var imageProcess: CCImageProcess.ImageProcess?

        public func dispose() {
            self.imageProcess?.dispose()
        }

        fileprivate func _dispose() {
            self.imageProcess = nil
        }
    }

    // MARK: - Pipe
    public class Pipe: NSObject, CCComponentPipeProtocol {
        fileprivate var counter: CMTimeValue = 0
        fileprivate let errorType: CCRenderer.ErrorType = CCRenderer.ErrorType.render

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

        private var _outTexture: CCTexture?
        public var outTexture: CCTexture? {
            get {
                objc_sync_enter(self)
                let outTexture: CCTexture? = self._outTexture
                objc_sync_exit(self)
                return outTexture
            }
            set {
                objc_sync_enter(self)
                self._outTexture = newValue
                objc_sync_exit(self)
            }
        }

        private var _outPresentationTimeStamp: CMTime = CMTime.zero
        @objc dynamic public var outPresentationTimeStamp: CMTime {
            get {
                objc_sync_enter(self)
                let presentationTimeStamp: CMTime = self._outPresentationTimeStamp
                objc_sync_exit(self)
                return presentationTimeStamp
            }
            set {
                objc_sync_enter(self)
                self._outPresentationTimeStamp = newValue
                objc_sync_exit(self)
            }
        }

        fileprivate var displayLink: CADisplayLink?
        fileprivate var isDisplayLink: Bool = false
        fileprivate var imageProcess: CCImageProcess.ImageProcess?
        fileprivate var observations: [NSKeyValueObservation] = []

        fileprivate func _dispose() {
            self.imageProcess = nil
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
            self.displayLink?.invalidate()
        }
    }
}


extension CCImageProcess.ImageProcess.Pipe {
    func input(camera: CCCapture.Camera) throws -> CCImageProcess.ImageProcess {

        let captureSize: MCSize = camera.property.captureInfo.presetSize.size(orientation: Configuration.shared.currentUIInterfaceOrientation)
        try self.updateOutTexture(captureSize: captureSize, mtlPixelFormat: MTLPixelFormat.bgra8Unorm)
        if self.isDisplayLink {
            self.displayLink = CADisplayLink(target: self, selector: #selector(updateDisplay))
            self.displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
            let observation: NSKeyValueObservation = camera.pipe.observe(\.outVideoCapturePresentationTimeStamp, options: [.new]) { [weak self] (object: CCCapture.Camera.Pipe, change) in
                guard let captureData: CCCapture.VideoCapture.CaptureData = object.currentVideoCaptureItem else { return }
                // CADisplayLinkのloopで参照されるのでQueueを揃える。
                self?.imageProcess?.imageProcessQueue.sync { [weak self] in
                    self?.currentCaptureItem = captureData
                }
            }
            self.observations.append(observation)
        } else {
            let observation: NSKeyValueObservation = camera.pipe.observe(\.outVideoCapturePresentationTimeStamp, options: [.new]) { [weak self] (object: CCCapture.Camera.Pipe, change) in
                guard let captureData: CCCapture.VideoCapture.CaptureData = object.currentVideoCaptureItem else { return }
                // CADisplayLinkのloopで参照されるのでQueueを揃える。
                self?.process(currentCaptureItem: captureData)
            }
            self.observations.append(observation)
        }

        return self.imageProcess!
    }
}

extension CCImageProcess.ImageProcess.Pipe {
    func input(player: CCPlayer) throws -> CCImageProcess.ImageProcess {

        /*
        //let captureSize: MCSize = camera.property.captureInfo.presetSize.size(orientation: Configuration.shared.currentUIInterfaceOrientation)
        try self.updateOutTexture(captureSize: captureSize, colorPixelFormat: MTLPixelFormat.bgra8Unorm)
        if self.isDisplayLink {
            self.displayLink = CADisplayLink(target: self, selector: #selector(updateDisplay))
            self.displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
            let observation: NSKeyValueObservation = player.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCPlayer.Pipe, change) in
                guard let texture: CCTexture = object.outTexture else { return }
                // CADisplayLinkのloopで参照されるのでQueueを揃える。
                self?.imageProcess?.imageProcessQueue.sync { [weak self] in
                    //self?.currentCaptureItem = captureData
                }
            }
            self.observations.append(observation)
        } else {
            let observation: NSKeyValueObservation = player.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCPlayer.Pipe, change) in
                guard let texture: CCTexture = object.outTexture else { return }
                // CADisplayLinkのloopで参照されるのでQueueを揃える。
                //self?.process(currentCaptureItem: captureData)
            }
            self.observations.append(observation)
        }
    */
        return self.imageProcess!
    }
}

extension CCImageProcess.ImageProcess.Pipe {
    func input(camera: CCARCapture.cARCamera) throws -> CCImageProcess.ImageProcess {
        try self.updateOutTexture(captureSize: MCSize.init(1920, 1440), mtlPixelFormat: MTLPixelFormat.bgra8Unorm)
        let observation: NSKeyValueObservation = camera.pipe.observe(\.ouTimeStamp, options: [.new]) { [weak self] (object: CCARCapture.cARCamera.Pipe, change) in
            guard let self = self else { return }
            guard let captureData: CCARCapture.CaptureData = object.captureData else { return }

            guard var outTexture: CCTexture = self.outTexture else { return }
            do {
                let renderSize = MCSize.init(1920, 1440)
                if outTexture.size != renderSize {
                    outTexture = try self.updateOutTexture(captureSize: renderSize, mtlPixelFormat: captureData.mtlPixelFormat)
                }

                ///////////////////////////////////////////////////////////////////////////////////////////////////
                // renderLayerCompositionInfo
                var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo(
                    compositionTime: CMTime(value: self.counter, timescale: 60),
                    captureInfo: captureData.captureInfo,
                    timeRange: CMTimeRange.zero,
                    percentComplete: 0.0,
                    renderSize: renderSize,
                    metadataObjects: [],
                    depthData: nil,
                    queue: self.imageProcess!.imageProcessQueue
                )
                ///////////////////////////////////////////////////////////////////////////////////////////////////
        self.counter += 1
                ///////////////////////////////////////////////////////////////////////////////////////////////////
                // process
                guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
                defer {
                    commandBuffer.commit()
                    commandBuffer.waitUntilCompleted()
                }

                commandBuffer.addCompletedHandler { [weak self] _ in
                    guard let self = self else { return }
                    //self.isProcess = false
                    self.imageProcess!.imageProcessCompleteQueue.async { [weak self] in
                        guard let self = self else { return }
                        self.imageProcess!.presentationTimeStamp = captureData.presentationTimeStamp
                        outTexture.presentationTimeStamp = captureData.presentationTimeStamp
                        outTexture.captureVideoOrientation = captureData.captureVideoOrientation
                        outTexture.presetSize = captureData.captureInfo.presetSize

                        //self.debug?.update()

                        self.outTexture = outTexture
                        self.outPresentationTimeStamp = captureData.presentationTimeStamp
                    }
                }

                var pixelBuffer: CVPixelBuffer = captureData.arFrame.capturedImage
                try self.imageProcess!.processRenderLayer(commandBuffer: commandBuffer, source: &pixelBuffer, destination: &outTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
            } catch {
                
            }
        }

        self.observations.append(observation)
        return self.imageProcess!
    }
}

extension CCImageProcess.ImageProcess.Pipe {
    @objc private func updateDisplay() {
        guard let currentCaptureItem: CCCapture.VideoCapture.CaptureData = self.currentCaptureItem else { return }
        guard
            let imageProcess: CCImageProcess.ImageProcess = self.imageProcess,
            !imageProcess.isProcess,
            currentCaptureItem.presentationTimeStamp != imageProcess.presentationTimeStamp
        else { return }
        imageProcess.imageProcessQueue.async { [weak self] in
            imageProcess.debug?.update(thred: Thread.current, queue: imageProcess.imageProcessQueue)
            do {
                try imageProcess.process(captureData: currentCaptureItem, queue: CCCapture.videoOutputQueue)
            } catch {
                MCDebug.log("CCRenderer.PostProcess: process error")
            }
        }
    }

    private func process(currentCaptureItem: CCCapture.VideoCapture.CaptureData) {
        guard
            let imageProcess: CCImageProcess.ImageProcess = self.imageProcess
        else { return }
        imageProcess.imageProcessQueue.async { [weak self] in
            //imageProcess.debugger?.update(thred: Thread.current, queue: imageProcess.imageProcessQueue)
            do {
                try imageProcess.process(captureData: currentCaptureItem, queue: CCCapture.videoOutputQueue)
            } catch {
                MCDebug.log("CCRenderer.PostProcess: process error")
            }
        }
    }

    @discardableResult
    func updateOutTexture(captureSize: MCSize, mtlPixelFormat: MTLPixelFormat) throws -> CCTexture {
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // 描画用テクスチャを生成
        guard
            Float(self.outTexture?.size.w ?? 0) != captureSize.w,
            let pixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: captureSize),
            let tex: CCTexture = try? CCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: mtlPixelFormat, planeIndex: 0)
        else { throw self.errorType }
        self.outTexture = tex
        return tex
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }

}
