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
import ProcessLogger_Swift

extension CCImageProcess {
    public class ImageProcess: NSObject, CCComponentProtocol {

        private let imageProcessQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCImageProcess.ImageProcess.process")

        // MARK: - CCComponentProtocol
        public let setup: CCImageProcess.ImageProcess.Setup = CCImageProcess.ImageProcess.Setup()
        public let triger: CCImageProcess.ImageProcess.Triger = CCImageProcess.ImageProcess.Triger()
        public let pipe: CCImageProcess.ImageProcess.Pipe = CCImageProcess.ImageProcess.Pipe()
        public var debug: CCComponentDebug?

        fileprivate let errorType: CCImageProcess.ErrorType = CCImageProcess.ErrorType.render
        fileprivate let hasMPS: Bool = MPSSupportsMTLDevice(MCCore.device)
        fileprivate let filter: MPSImageLanczosScale = MPSImageLanczosScale(device: MCCore.device)
        fileprivate var counter: CMTimeValue = 0

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        //

        public var renderLayers: CCVariable<[RenderLayerProtocol]> = CCVariable([])

        fileprivate(set) var isProcess: CCVariable<Bool> = CCVariable(false)
        fileprivate(set) var processTimeStamp: CCVariable<CMTime> = CCVariable(CMTime.zero)
        fileprivate(set) var inferenceUserInfo: CCVariable<[ String : Any]> = CCVariable([ : ])
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        fileprivate(set) var captureSize: Settings.PresetSize = Settings.PresetSize.p1280x720

        public init(captureSize: MCSize = MCSize(1.0, 1.0)) throws {
            super.init()
            try self.pipe.updateOutTexture(captureSize: captureSize, mtlPixelFormat: MTLPixelFormat.bgra8Unorm)
            self.setup.imageProcess = self
            self.triger.imageProcess = self
            self.pipe.imageProcess = self
        }

        deinit {
            self.dispose()
            ProcessLogger.deinitLog(self)
        }
    }
}


extension CCImageProcess.ImageProcess {
    func update(renderLayers: [RenderLayerProtocol]) {
        self.imageProcessQueue.async { [weak self] in
            self?.renderLayers.value = renderLayers
        }
    }

    func process(captureData: CCCapture.VideoCapture.CaptureData) {
        guard
            self.isProcess.value != true,
            self.processTimeStamp.value != captureData.presentationTimeStamp,
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer)
        else { /* 画像データではないBuffer */ return }

        let presentationTimeStamp: CMTime = captureData.presentationTimeStamp
        self.processTimeStamp.value = presentationTimeStamp
        self.isProcess.value = true

        //////////////////////////////////////////////////////////
        // renderSize
        let width: Int = CVPixelBufferGetWidth(pixelBuffer)
        let height: Int = CVPixelBufferGetHeight(pixelBuffer)
        let renderSize: MCSize = MCSize(w: width, h: height)
        //////////////////////////////////////////////////////////

        self.imageProcessQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                ///////////////////////////////////////////////////////////////////////////////////////////////////
                // renderLayerCompositionInfo
                var userInfo: [ String : Any] = self.inferenceUserInfo.value
                userInfo[ RenderLayerCompositionInfo.Key.depthData.rawValue ] = captureData.depthData
                userInfo[ RenderLayerCompositionInfo.Key.videoCaptureData.rawValue ] = captureData

                var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo(
                    compositionTime: CMTime(value: self.counter, timescale: captureData.captureInfo.frameRate),
                    presentationTimeStamp: captureData.presentationTimeStamp,
                    timeRange: CMTimeRange.zero,
                    percentComplete: 0.0,
                    renderSize: renderSize,
                    metadataObjects: captureData.metadataObjects,
                    userInfo: userInfo
                )
                ///////////////////////////////////////////////////////////////////////////////////////////////////

                try self.process(pixelBuffer: pixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
            } catch {
                self.isProcess.value = false
                ProcessLogger.log("CCRenderer.PostProcess: process error")
            }
        }
    }

    func process(texture: CCTexture) throws {
        guard
            self.isProcess.value != true,
            self.processTimeStamp.value != texture.presentationTimeStamp,
            let pixelBuffer: CVPixelBuffer = texture.pixelBuffer
        else { /* 画像データではないBuffer */ return }
        
        let presentationTimeStamp: CMTime = texture.presentationTimeStamp
        self.processTimeStamp.value = presentationTimeStamp
        self.isProcess.value = true

        self.imageProcessQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                ///////////////////////////////////////////////////////////////////////////////////////////////////
                // renderLayerCompositionInfo
                var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo(
                    compositionTime: CMTime(value: self.counter, timescale: 60),
                    presentationTimeStamp: texture.presentationTimeStamp,
                    timeRange: CMTimeRange.zero,
                    percentComplete: 0.0,
                    renderSize: texture.size,
                    metadataObjects: [],
                    userInfo: self.inferenceUserInfo.value
                )
                ///////////////////////////////////////////////////////////////////////////////////////////////////

                try self.process(pixelBuffer: pixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
            } catch {
                self.isProcess.value = false
                ProcessLogger.log("CCRenderer.PostProcess: process error")
            }
        }
    }

}

private extension CCImageProcess.ImageProcess {
    func process(pixelBuffer: CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        var pixelBuffer: CVPixelBuffer = pixelBuffer
        guard var outTexture: CCTexture = self.pipe.outTexture else { throw self.errorType }

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // outTexture
        let renderSize: MCSize = renderLayerCompositionInfo.renderSize
        if outTexture.size != renderSize {
            outTexture = try self.pipe.updateOutTexture(captureSize: renderSize, mtlPixelFormat: MTLPixelFormat.bgra8Unorm)
        }
        outTexture.presentationTimeStamp = renderLayerCompositionInfo.presentationTimeStamp
        //outTexture.captureVideoOrientation =
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        self.counter += 1

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // process
        guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { throw self.errorType }
        commandBuffer.label = "@CommandBuffer: CCImageProcess.ImageProcess.process: \(outTexture.presentationTimeStamp.value)"
        defer {
            commandBuffer.commit()
        }

        commandBuffer.addCompletedHandler { [weak self] _ in
            guard let self = self else { return }
            self.pipe.outUpdate(outTexture: outTexture)
            self.debug?.update()
            self.isProcess.value = false
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

        for index in self.renderLayers.value.indices {
            guard self.renderLayers.value.indices.contains(index) else { continue }
            do {
                try self.renderLayers.value[index].process(commandBuffer: commandBuffer, source: sourceTexture, destination: &destination, renderLayerCompositionInfo: &renderLayerCompositionInfo)

                if index < self.renderLayers.value.count - 1 {
                    // 各レイヤー処理の後に destination の BitmapDataを sourceTextureにコピーする。
                    try self.textureBlitEncoder(commandBuffer: commandBuffer, source: destination, destination: &sourceTexture)
                }
            } catch {
                ProcessLogger.errorLog(error)
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

        for index in self.renderLayers.value.indices {
            guard self.renderLayers.value.indices.contains(index) else { continue }
            self.renderLayers.value[index].dispose()
        }
        self.renderLayers.dispose()
    }
}


// MARK: - Setup
extension CCImageProcess.ImageProcess {
    public class Setup: CCComponentSetupProtocol {
        fileprivate var imageProcess: CCImageProcess.ImageProcess?
        fileprivate func _dispose() {
            self.imageProcess = nil
        }
        }
}


// MARK: - Triger
extension CCImageProcess.ImageProcess {
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var imageProcess: CCImageProcess.ImageProcess?

        public func dispose() {
            self.imageProcess?.dispose()
        }

        fileprivate func _dispose() {
            self.imageProcess = nil
        }
    }
}


// MARK: - Pipe
extension CCImageProcess.ImageProcess {
    public class Pipe: NSObject, CCComponentPipeProtocol {

        private let completeQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRenderer.PostProcess.Complete")

        fileprivate var counter: CMTimeValue = 0
        fileprivate let errorType: CCImageProcess.ErrorType = CCImageProcess.ErrorType.render

        private var _currentCaptureItem: CCCapture.VideoCapture.CaptureData?
        fileprivate(set) var currentCaptureItem: CCCapture.VideoCapture.CaptureData? {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._currentCaptureItem
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
                defer { objc_sync_exit(self) }
                return self._outTexture
            }
            set {
                objc_sync_enter(self)
                self._outTexture = newValue
                objc_sync_exit(self)
            }
        }

        public var texture: CCVariable<CCTexture?> = CCVariable(nil)

        fileprivate var imageProcess: CCImageProcess.ImageProcess?
        fileprivate var observations: [NSKeyValueObservation] = []

        fileprivate func _dispose() {
            self.imageProcess = nil
            self.texture.dispose()
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
        }


        // MARK: - Pipe - input

        // MARK: input - CCCapture.Camera
        func input(camera: CCCapture.Camera) throws -> CCImageProcess.ImageProcess {
            camera.pipe.videoCaptureItem.bind() { [weak self] (captureData: CCCapture.VideoCapture.CaptureData?) in
                guard
                    let self = self,
                    let captureData: CCCapture.VideoCapture.CaptureData = captureData
                else { return }

                if (self.imageProcess?.renderLayers.value.isEmpty ?? true) {
                    // レンダーレイヤーが無い
                    self.passThrough(captureData: captureData)
                } else {
                    self.imageProcess?.process(captureData: captureData)
                }
            }

            return self.imageProcess!
        }


        // MARK: input - CCVision.Inference
        func input(inference: CCVision.Inference) throws -> CCImageProcess.ImageProcess {
            inference.pipe.userInfo.bind() { [weak self] (userInfo: [String : Any]) in
                self?.imageProcess?.inferenceUserInfo.value = userInfo
            }
            return self.imageProcess!
        }

        
        // MARK: input - CCPlayer
        func input(player: CCPlayer) throws -> CCImageProcess.ImageProcess {

            player.pipe.outTexture.bind() { [weak self] (outTexture: CCTexture?) in
                guard
                    let self = self,
                    let outTexture: CCTexture = outTexture
                else { return }

                do {
                    try self.imageProcess?.process(texture: outTexture)
                } catch {
                        
                }
            }

            return self.imageProcess!
        }


        // MARK: input - CCARCapture.cARCamera
        @available(iOS 13.0, *)
        func input(camera: CCARCapture.cARCamera) throws -> CCImageProcess.ImageProcess {
            try self.updateOutTexture(captureSize: MCSize.init(1440, 1080), mtlPixelFormat: MTLPixelFormat.bgra8Unorm)
            let observation: NSKeyValueObservation = camera.pipe.observe(\.ouTimeStamp, options: [.new]) { [weak self] (object: CCARCapture.cARCamera.Pipe, change) in
                guard
                    let self = self,
                    let captureData: CCARCapture.CaptureData = object.captureData,
                    var outTexture: CCTexture = self.outTexture
                else { return }

                do {
                    let renderSize = MCSize.init(1440, 1080)
                    if outTexture.size != renderSize {
                        outTexture = try self.updateOutTexture(captureSize: renderSize, mtlPixelFormat: captureData.mtlPixelFormat)
                    }

                    ///////////////////////////////////////////////////////////////////////////////////////////////////
                    // renderLayerCompositionInfo
                    var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo(
                        compositionTime: CMTime(value: self.counter, timescale: 60),
                        presentationTimeStamp: captureData.presentationTimeStamp,
                        timeRange: CMTimeRange.zero,
                        percentComplete: 0.0,
                        renderSize: renderSize,
                        metadataObjects: [],
                        userInfo: [ RenderLayerCompositionInfo.Key.arFrame.rawValue : captureData.arFrame ]
                    )
                    ///////////////////////////////////////////////////////////////////////////////////////////////////

                    self.counter += 1

                    ///////////////////////////////////////////////////////////////////////////////////////////////////
                    // process
                    guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
                    defer {
                        commandBuffer.commit()
                    }

                    commandBuffer.addCompletedHandler { [weak self] _ in
                        guard let self = self else { return }
                        //self.isProcess = false
                        self.completeQueue.async { [weak self] in
                            guard let self = self else { return }
                            outTexture.presentationTimeStamp = captureData.presentationTimeStamp
                            outTexture.captureVideoOrientation = captureData.captureVideoOrientation
                            outTexture.presetSize = captureData.captureInfo.presetSize

                            //self.debug?.update()

                            self.outTexture = outTexture
                            //self.outPresentationTimeStamp = captureData.presentationTimeStamp
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


        // MARK: - Pipe - private

        fileprivate func passThrough(captureData: CCCapture.VideoCapture.CaptureData) {
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { return }
            do {
                var outTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: captureData.mtlPixelFormat, planeIndex: 0)
                outTexture.presentationTimeStamp = captureData.presentationTimeStamp
                outTexture.captureVideoOrientation = captureData.captureVideoOrientation
                outTexture.presetSize = captureData.captureInfo.presetSize
                self.outUpdate(outTexture: outTexture)
            } catch {
                ProcessLogger.log("CCRenderer.PostProcess: process error")
            }
        }

        @discardableResult
        fileprivate func updateOutTexture(captureSize: MCSize, mtlPixelFormat: MTLPixelFormat) throws -> CCTexture {
            ///////////////////////////////////////////////////////////////////////////////////////////////////
            // 描画用テクスチャを生成
            guard
                Float(self.outTexture?.size.w ?? 0) != captureSize.w,
                let pixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: captureSize),
                var tex: CCTexture = try? CCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: mtlPixelFormat, planeIndex: 0)
            else { throw self.errorType }
            self.outTexture = tex
            return tex
            ///////////////////////////////////////////////////////////////////////////////////////////////////
        }
        
        fileprivate func outUpdate(outTexture: CCTexture) {
            self.texture.value = outTexture
            self.completeQueue.async { [weak self] in
                self?.texture.dispatch()
                self?.texture.value = nil
            }
        }

    }
}
