//
//  MetalVideoCaptureView.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MetalCanvas
import MetalKit

public enum VideoCaptureStatus {
    case setup
    case update
    case ready
    case play
    case pause
    case seek
    case dispose
}

public class VideoCaptureView: MCImageRenderView, VideoCaptureViewProtocol {
    
    private let renderQueue: DispatchQueue = DispatchQueue(label: "CameraCore.MetalVideoCaptureView.queue")
    private let drawQueue: DispatchQueue = DispatchQueue(label: "CameraCore.MetalVideoCaptureView.draw.queue")
    
    public var status: VideoCaptureStatus = .setup {
        willSet {
            self.event?.onStatusChange?(newValue)
        }
    }
    
    public var capture: CCRenderer.VideoCapture.VideoCapture?
    
    public var croppingRect: CGRect?
    public var renderSize: CGSize?
    public var isRecording: Bool {
        get{
            return CCRenderer.VideoCapture.CaptureWriter.isWritng
        }
    }
    
    public var event: VideoCaptureViewEvent?
    
    /// 描画時に適用されるフィルターを指定
    public var renderLayers: [RenderLayerProtocol] = []
    
    internal enum RecordingError: Error {
        case setupError
        case render
    }
    
    fileprivate var counter: CMTimeValue = 0
    fileprivate var drawCounter: CMTimeValue = 0
    fileprivate var textureCache: CVMetalTextureCache? = MCCore.createTextureCache()
    fileprivate var drawTexture: MTLTexture!

    public override func awakeFromNib() {
        super.awakeFromNib()
        self.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    public override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self.isPaused = false
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        self.isPaused = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func setup() throws {
        try super.setup()
        try self.setup(Configuration.defaultVideoCapturePropertys)
    }

    public func setup(_ propertys: CCRenderer.VideoCapture.Propertys) throws {
        self.status = .setup

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        do {
            self.capture = try CCRenderer.VideoCapture.VideoCapture(propertys: propertys)
        } catch {
            self.capture = nil
            throw CCRenderer.VideoCapture.ErrorType.setupError
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        self.updateDrawTexture()
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        self.capture?.onUpdate = { [weak self] (sampleBuffer: CMSampleBuffer, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]) in
            guard self?.status == .play else { return }

            self?.renderQueue.async { [weak self] in
                autoreleasepool() { [weak self] in
                    do {
                        try self?.updateFrame(
                            sampleBuffer: sampleBuffer,
                            depthData: depthData,
                            metadataObjects: metadataObjects,
                            position: self?.capture?.propertys.info.devicePosition ?? .back
                        )
                    } catch {
                        MCDebug.errorLog("updateFrame error")
                    }
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }

    public override func draw(in view: MTKView) {
        super.draw(in: view)
        if let frameRate: Int32 = self.capture?.propertys.info.frameRate, frameRate < self.preferredFramesPerSecond {
            guard self.counter > self.drawCounter else { return }
        }
        guard let drawTexture: MTLTexture = self.drawTexture else { return }
        self.drawCounter = self.counter
        self.drawQueue.async { [weak self] in
            autoreleasepool() { [weak self] in
                self?.drawUpdate(drawTexture: drawTexture)
            }
        }
    }
}

extension VideoCaptureView {
    public func play() {
        guard self.status != .play else { return }
        MCDebug.log("CCamVideo.VideoRecordingPlayer.play")
        self.capture?.play()
        self.status = .play
    }
    
    public func pause() {
        MCDebug.log("CCamVideo.VideoRecordingPlayer.pause")
        self.capture?.stop()
        self.status = .pause
    }
    
    public func dispose() {
        MCDebug.log("CCamVideo.VideoRecordingPlayer.dispose")
        self.capture?.stop()
        self.status = .setup
        self.capture = nil
    }
}

extension VideoCaptureView {
    public func update(propertys: CCRenderer.VideoCapture.Propertys) throws {
        try self.capture?.update(propertys: propertys)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        self.updateDrawTexture()
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

extension VideoCaptureView {
    public func recordingStart(_ paramator: CCRenderer.VideoCapture.CaptureWriter.Paramator) throws {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let _ = CCRenderer.VideoCapture.CaptureWriter.setup(paramator)
            let _ = CCRenderer.VideoCapture.CaptureWriter.start()
        }
    }
    
    public func recordingStop() {
        CCRenderer.VideoCapture.CaptureWriter.finish({ [weak self] (result: Bool, filePath: URL) in
            DispatchQueue.main.async { [weak self] in
                self?.event?.onRecodingComplete?(result, filePath)
            }
        })
    }
    
    public func recordingCancelled() {
        CCRenderer.VideoCapture.CaptureWriter.finish(nil)
    }
}

extension VideoCaptureView {
    fileprivate func crip(pixelBuffer: CVPixelBuffer, rect: CGRect) -> CIImage {
        let tempImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter?.setValue(tempImage, forKey: kCIInputImageKey)
        cropFilter?.setValue(rect, forKey: "inputRectangle")
        return (cropFilter?.outputImage)!.transformed(by: CGAffineTransform(translationX: 0, y: -rect.origin.y ))
    }
}

extension VideoCaptureView {
    fileprivate func updateFrame(sampleBuffer: CMSampleBuffer, depthData: AVDepthData?, metadataObjects: [AVMetadataObject], position: AVCaptureDevice.Position) throws {

        self.event?.onFrameUpdate?(sampleBuffer, depthData, metadataObjects)
        
        guard
            let frameRate: Int32 = self.capture?.propertys.info.frameRate,
            let drawTexture: MTLTexture = self.drawTexture
        else { return }

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // renderSize
        if CCRenderer.VideoCapture.CaptureWriter.isWritng == true {
            CCRenderer.VideoCapture.CaptureWriter.addCaptureSampleBuffer(sampleBuffer: sampleBuffer)
            let t: TimeInterval = CCRenderer.VideoCapture.CaptureWriter.recordedDuration
            DispatchQueue.main.async {
                self.event?.onRecodingUpdate?(t)
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // renderSize
        guard var originalPixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let width: Int = CVPixelBufferGetWidth(originalPixelBuffer)
        let height: Int = CVPixelBufferGetHeight(originalPixelBuffer)
        let renderSize: CGSize = CGSize.init(width: width, height: height)
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // drawableSizeを最適化
        self.drawableSize = renderSize
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // renderLayerCompositionInfo
        var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo.init(
            compositionTime: CMTime(value: self.counter, timescale: frameRate),
            timeRange: CMTimeRange.zero,
            percentComplete: 0.0,
            renderSize: renderSize,
            metadataObjects: metadataObjects,
            depthData: depthData,
            queue: self.renderQueue
        )
        self.counter += 1
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // renderLayerCompositionInfo
        guard var commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
        for (index, _) in self.renderLayers.enumerated() {
            guard self.renderLayers.indices.contains(index) else { continue }
            if var renderLayer: MetalRenderLayerProtocol = self.renderLayers[index] as? MetalRenderLayerProtocol {
                do {
                    try self.processingMetalRenderLayer(renderLayer: &renderLayer, commandBuffer: &commandBuffer, pixelBuffer: &originalPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
                } catch {
                    MCDebug.log(error)
                }
            } else if var renderLayer: CVPixelBufferRenderLayerProtocol = self.renderLayers[index] as? CVPixelBufferRenderLayerProtocol {
                do {
                    try renderLayer.process(commandBuffer: &commandBuffer, pixelBuffer: &originalPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
                } catch {
                    MCDebug.log(error)
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // commandBuffer commit
        guard let rgbTexture: MTLTexture = MCCore.texture(pixelBuffer: &originalPixelBuffer, colorPixelFormat: self.colorPixelFormat) else { return }
        commandBuffer.addCompletedHandler { [weak self] cb in
            self?.event?.onPixelUpdate?(originalPixelBuffer, depthData, metadataObjects)
        }
        super.updatePixelBuffer(commandBuffer: commandBuffer, sorce: rgbTexture, destination: drawTexture, renderSize: renderSize)
        commandBuffer.commit()
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
    
    private func processingMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard var textureCache: CVMetalTextureCache = self.textureCache else { throw RecordingError.render }
        guard let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw RecordingError.render }
        guard var destinationTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat) else { throw RecordingError.render }
        try renderLayer.process(commandBuffer: &commandBuffer, source: sourceTexture, destination: &destinationTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
    }
}

extension VideoCaptureView {
    @objc func onOrientationDidChange() {
        self.updateDrawTexture()
    }
    
    fileprivate func updateDrawTexture() {
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // 描画用テクスチャを生成
        self.drawQueue.async { [weak self] in
            autoreleasepool { [weak self] in
                guard
                    let self = self,
                    let captureSize: CGSize = self.capture?.propertys.info.presetSize.size(isOrientation: true),
                    CGFloat(self.drawTexture?.width ?? 0) != captureSize.width,
                    var pixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: captureSize)
                else { return }
                self.drawTexture = MCCore.texture(pixelBuffer: &pixelBuffer, colorPixelFormat: self.colorPixelFormat)
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}
