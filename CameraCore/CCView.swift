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

public class CCView: MCImageRenderView, CCComponentProtocol {
    public let setup: CCView.Setup = CCView.Setup()
    public let triger: CCView.Triger = CCView.Triger()
    public let pipe: CCView.Pipe = CCView.Pipe()
    public var debugger: ComponentDebugger?
    
    enum ErrorType: Error {
        case draw
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

    public override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self._init()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        self._init()
    }

    private func _init() {
        self.setup.ccview = self
        self.triger.ccview = self
        self.pipe.ccview = self
    }

    deinit {
        self.dispose()
    }
    
    public func _setup() throws {
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
            self?.debugger?.update()
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

fileprivate extension CCView {
    func dispose() {
        self.setup._dispose()
        self.triger._dispose()
        self.pipe._dispose()
        self.isDraw = false
        NotificationCenter.default.removeObserver(self)
    }
}

extension CCView {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var ccview: CCView?
        fileprivate func _dispose() {
            self.ccview = nil
        }
    }

    // MARK: - Triger
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var ccview: CCView?

        public func dispose() {
            self.ccview?.dispose()
        }

        fileprivate func _dispose() {
            self.ccview = nil
        }
    }

    // MARK: - Pipe
    public class Pipe: NSObject, CCComponentPipeProtocol {
        fileprivate var ccview: CCView?
        fileprivate var observations: [NSKeyValueObservation] = []

        @objc dynamic public var outPresentationTimeStamp: CMTime = CMTime.zero

        func input(imageProcess: CCImageProcess.ImageProcess) throws -> CCView {
            try self.ccview?._setup()
            let observation: NSKeyValueObservation = imageProcess.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCImageProcess.ImageProcess.Pipe, change) in
                guard let outTexture: CCTexture = object.outTexture else { return }

                guard let self = self else { return }

                if outTexture.colorPixelFormat != self.ccview?.colorPixelFormat {
                    MCDebug.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                self.ccview?.drawTexture = outTexture

            }
            self.observations.append(observation)

            return self.ccview!
        }

        func input(camera: CCCapture.Camera) throws -> CCView {
            try self.ccview?._setup()
            let observation: NSKeyValueObservation = camera.pipe.observe(\.outVideoCapturePresentationTimeStamp, options: [.new]) { [weak self] (object: CCCapture.Camera.Pipe, change) in
                guard let captureData: CCCapture.VideoCapture.CaptureData = object.currentVideoCaptureItem else { return }

                guard let self = self else { return }
                if captureData.colorPixelFormat != self.ccview?.colorPixelFormat {
                    MCDebug.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
                do {
                    var drawTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, colorPixelFormat: captureData.colorPixelFormat, planeIndex: 0)
                    drawTexture.presentationTimeStamp = captureData.presentationTimeStamp
                    drawTexture.captureVideoOrientation = captureData.captureVideoOrientation
                    drawTexture.presetSize = captureData.captureInfo.presetSize

                    DispatchQueue.main.async { [weak self] in
                        self?.ccview?.drawTexture = drawTexture
                    }

                } catch {
                    MCDebug.errorLog("CCView: onUpdateCaptureData drawTexture")
                }

            }
            self.observations.append(observation)

            return self.ccview!
        }

        fileprivate func _dispose() {
            self.ccview = nil
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
        }
    }
}
