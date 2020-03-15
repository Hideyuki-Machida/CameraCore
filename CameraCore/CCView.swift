//
//  CCView.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/01.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas
import MetalKit
import UIKit

public class CCView: MCImageRenderView {
    enum ErrorType: Error {
        case draw
    }

    deinit {
        self.isDraw = false
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate let orientationManager: OrientationManager = OrientationManager()

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

    private var _isDraw: Bool = false
    fileprivate(set) var isDraw: Bool {
        get {
            objc_sync_enter(self)
            let isDraw: Bool = self._isDraw
            objc_sync_exit(self)
            return isDraw
        }
        set {
            objc_sync_enter(self)
            self._isDraw = newValue
            objc_sync_exit(self)
        }
    }

    private var _drawTexture: CCTexture?
    fileprivate(set) var drawTexture: CCTexture? {
        get {
            objc_sync_enter(self)
            let drawTexture: CCTexture? = self._drawTexture
            objc_sync_exit(self)
            return drawTexture
        }
        set {
            objc_sync_enter(self)
            self._drawTexture = newValue
            objc_sync_exit(self)
        }
    }

    public override func setup() throws {
        try super.setup()
        self.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
    }

    public override func draw(in view: MTKView) {
        super.draw(in: view)

        guard
            !self.isDraw,
            let drawTexture: CCTexture = self.drawTexture,
            self.presentationTimeStamp != drawTexture.presentationTimeStamp
        else { return }

        self.presentationTimeStamp = drawTexture.presentationTimeStamp

        guard let commandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }

        commandBuffer.addCompletedHandler { [weak self] (_: MTLCommandBuffer) in
            self?.isDraw = false
        }

        self.isDraw = true

        do {
            let texture: CCTexture = try orientationManager.rotateTexture(commandBuffer: commandBuffer, source: drawTexture, colorPixelFormat: self.colorPixelFormat, captureVideoOrientation: drawTexture.captureVideoOrientation)

            self.drawUpdate(commandBuffer: commandBuffer, drawTexture: texture.texture)
        } catch {
            MCDebug.errorLog("CCView draw")
        }
    }
}

// MARK: - pipe

extension CCView {
    func pipe(postProcess: CCRenderer.PostProcess) throws -> CCView {
        try self.setup()

        postProcess.onUpdate = { [weak self] (outTexture: CCTexture) in
            guard let self = self else { return }
            if outTexture.colorPixelFormat != self.colorPixelFormat {
                MCDebug.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                return
            }

            self.drawTexture = outTexture
        }

        return self
    }

    func pipe(camera: CCCapture.Camera) throws -> CCView {
        try self.setup()

        camera.pipe.outCaptureData = { [weak self] (captureData: CCCapture.VideoCapture.CaptureData) in
            guard let self = self else { return }
            if captureData.colorPixelFormat != self.colorPixelFormat {
                MCDebug.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                return
            }

            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
            do {
                var drawTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, colorPixelFormat: captureData.colorPixelFormat, planeIndex: 0)
                drawTexture.presentationTimeStamp = captureData.presentationTimeStamp
                drawTexture.captureVideoOrientation = captureData.captureVideoOrientation
                drawTexture.presetSize = captureData.captureInfo.presetSize

                self.drawTexture = drawTexture

            } catch {
                MCDebug.errorLog("CCView: onUpdateCaptureData drawTexture")
            }
        }

        return self
    }
}
