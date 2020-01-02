//
//  MetalVideoCaptureView.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/17.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas
import MetalKit
import UIKit

public class VideoCaptureView: MCImageRenderView, VideoCaptureViewProtocol {
    public enum Status {
        case setup
        case update
        case ready
        case play
        case pause
        case seek
        case dispose
    }

    private let renderQueue: DispatchQueue = DispatchQueue(label: "CameraCore.VideoCaptureView.render.queue")

    public var status: Status = .setup {
        willSet {
            self.event?.onStatusChange?(newValue)
        }
    }

    public var capture: CCRenderer.VideoCapture.VideoCaptureManager?

    public var croppingRect: CGRect?
    public var renderSize: CGSize?
    public var isDisplaySyncRendering: Bool = false
    public var isRecording: Bool {
        return CCRenderer.VideoCapture.CaptureWriter.isWriting
    }

    public var event: VideoCaptureViewEvent?

    /// 描画時に適用されるフィルターを指定
    public var renderLayers: [RenderLayerProtocol] = [] {
        willSet {
            self.renderQueue.async { [weak self] in
                self?.process.update(renderLayers: newValue)
            }
        }
    }

    fileprivate var presentationTimeStamp: CMTime = CMTime()
    fileprivate let process: CCRenderer.PostProcess = CCRenderer.PostProcess()

    public override func awakeFromNib() {
        super.awakeFromNib()
        self.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        self.process.onUpdate = { [weak self] (pixelBuffer: CVPixelBuffer) in
            self?.event?.onPixelUpdate?(pixelBuffer)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func setup() throws {
        try self.setup(Configuration.defaultVideoCaptureProperty)
    }

    public override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        super.mtkView(view, drawableSizeWillChange: size)
    }

    public override func draw(in view: MTKView) {
        super.draw(in: view)
        guard
            self.process.presentationTimeStamp != self.presentationTimeStamp,
            let drawTexture: MTLTexture = self.process.outTexture
        else { return }
        self.presentationTimeStamp = self.process.presentationTimeStamp
        self.drawUpdate(drawTexture: drawTexture)
    }

    public func setup(_ property: CCRenderer.VideoCapture.Property) throws {
        try super.setup()
        self.status = .setup

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        do {
            self.capture = try CCRenderer.VideoCapture.VideoCaptureManager(property: property)
        } catch {
            self.capture = nil
            throw CCRenderer.ErrorType.setup
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // 描画用テクスチャを生成
        guard let captureSize: MCSize = self.capture?.property.captureInfo.presetSize.size(isOrientation: true) else { return }
        self.process.updateOutTexture(captureSize: captureSize, colorPixelFormat: self.colorPixelFormat)
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        self.capture?.onUpdate = { [weak self] (sampleBuffer: CMSampleBuffer, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?) in
            guard
                let self = self,
                self.status == .play,
                let captureSize: MCSize = self.capture?.property.captureInfo.presetSize.size(isOrientation: true),
                let frameRate: Int32 = self.capture?.property.captureInfo.frameRate
            else { return }

            self.renderQueue.async { [weak self] in
                guard
                    let self = self,
                    !self.process.isProcess
                else { return }

                if self.isDisplaySyncRendering {
                    guard self.presentationTimeStamp != CMSampleBufferGetPresentationTimeStamp(sampleBuffer) else { return }
                }

                let currentCaptureItem: CCRenderer.VideoCapture.CaptureData = CCRenderer.VideoCapture.CaptureData(
                    sampleBuffer: sampleBuffer,
                    frameRate: frameRate,
                    depthData: depthData,
                    metadataObjects: metadataObjects,
                    captureSize: captureSize,
                    colorPixelFormat: self.colorPixelFormat
                )

                do {
                    try self.process.process(captureData: currentCaptureItem, queue: self.renderQueue)
                } catch {
                    MCDebug.errorLog("VideoCaptureView Render")
                }
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }

    public func play() {
        guard self.status != .play else { return }
        MCDebug.log("CameraCore.VideoRecordingPlayer.play")
        self.capture?.play()
        self.status = .play
    }

    public func pause() {
        MCDebug.log("CameraCore.VideoRecordingPlayer.pause")
        self.capture?.stop()
        self.status = .pause
    }

    public func dispose() {
        MCDebug.log("CameraCore.VideoRecordingPlayer.dispose")
        self.capture?.stop()
        self.status = .setup
        self.capture = nil
    }
}

extension VideoCaptureView {
    public func update(property: CCRenderer.VideoCapture.Property) throws {
        try self.capture?.update(property: property)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // 描画用テクスチャを生成
        guard let captureSize: MCSize = self.capture?.property.captureInfo.presetSize.size(isOrientation: true) else { return }
        self.process.updateOutTexture(captureSize: captureSize, colorPixelFormat: self.colorPixelFormat)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

extension VideoCaptureView {
    public func recordingStart(_ parameter: CCRenderer.VideoCapture.CaptureWriter.Parameter) throws {
        CCRenderer.VideoCapture.CaptureWriter.setup(parameter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CCRenderer.VideoCapture.CaptureWriter.start()
        }
    }

    public func recordingStop() {
        CCRenderer.VideoCapture.CaptureWriter.finish { [weak self] (result: Bool, filePath: URL) in
            DispatchQueue.main.async { [weak self] in
                self?.event?.onRecodingComplete?(result, filePath)
            }
        }
    }

    public func recordingCancelled() {
        CCRenderer.VideoCapture.CaptureWriter.finish(nil)
    }
}

extension VideoCaptureView {
    fileprivate func crop(pixelBuffer: CVPixelBuffer, rect: CGRect) -> CIImage? {
        let tempImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter?.setValue(tempImage, forKey: kCIInputImageKey)
        cropFilter?.setValue(rect, forKey: "inputRectangle")
        return cropFilter?.outputImage?.transformed(by: CGAffineTransform(translationX: 0, y: -rect.origin.y))
    }
}

extension VideoCaptureView {
    @objc private func orientationDidChange(_ notification: Notification) {
        guard let captureSize: MCSize = self.capture?.property.captureInfo.presetSize.size(isOrientation: true) else { return }
        self.process.updateOutTexture(captureSize: captureSize, colorPixelFormat: self.colorPixelFormat)
    }
}
