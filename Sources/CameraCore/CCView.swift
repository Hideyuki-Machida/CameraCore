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

public class CCView: MTKView, CCComponentProtocol {

    enum ErrorType: Error {
        case draw
    }

    // MARK: - CCComponentProtocol
    public let setup: CCView.Setup = CCView.Setup()
    public let triger: CCView.Triger = CCView.Triger()
    public let pipe: CCView.Pipe = CCView.Pipe()
    public var debug: CCComponentDebug?

    // MARK: -
    private var _presentationTimeStamp: CMTime = CMTime()
    fileprivate(set) var presentationTimeStamp: CMTime {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return self._presentationTimeStamp
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
            defer { objc_sync_exit(self) }
            return self._isDraw
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
            defer { objc_sync_exit(self) }
            return self._drawTexture
        }
        set {
            objc_sync_enter(self)
            self._drawTexture = newValue
            objc_sync_exit(self)
        }
    }

    // MARK: - Lifecycle
    public override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        self._init()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        self._init()
    }

    private func _init() {
        self.delegate = self

        self.setup.ccview = self
        self.triger.ccview = self
        self.pipe.ccview = self

        self.framebufferOnly = false
        self.enableSetNeedsDisplay = false
        self.autoResizeDrawable = true

        self.device = MCCore.device
        self.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
    }

    deinit {
        self.dispose()
    }
}

extension CCView: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    public func draw(in view: MTKView) {
        ///////////////////////////////////////////////////////////////////////////////////////////
        guard
            !self.isDraw, // draw処理が完了している
            let drawTexture: CCTexture = self.drawTexture, // drawTextureが存在する
            self.presentationTimeStamp != drawTexture.presentationTimeStamp, // 直前に処理を行ったpresentationTimeStampとdrawTexture.presentationTimeStampが一致しない
            let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() // MTLCommandBufferを生成
        else { return }
        ///////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////
        // 処理判定用のフラグセット
        commandBuffer.addCompletedHandler { [weak self] (_: MTLCommandBuffer) in
            // drawの処理が完了
            self?.isDraw = false

            // 処理完了のイベント発行
            //self?.event?.onUpdateComplete?()

            // デバッグモードの場合にデバッグ情報をupdate
            self?.debug?.update()
        }

        self.isDraw = true
        self.presentationTimeStamp = drawTexture.presentationTimeStamp
        ///////////////////////////////////////////////////////////////////////////////////////////

        do {
            // 描画処理
            try self.drawUpdate(commandBuffer: commandBuffer, drawTexture: drawTexture.texture)
        } catch {
            // drawの処理が完了できなかった
            self.isDraw = false
            MCDebug.errorLog("CCView draw")
        }
    }
}

private extension CCView {
    func drawUpdate(commandBuffer: MTLCommandBuffer, drawTexture: MTLTexture) throws {
        ///////////////////////////////////////////////////////////////////////////////////////////
        // drawableSizeを最適化
        // drawableSizeは次回生成のdrawableに適応されるっぽい
        self.drawableSize = CGSize(CGFloat(drawTexture.width), CGFloat(drawTexture.height))
        ///////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////
        guard
            let drawable: CAMetalDrawable = self.currentDrawable, // currentDrawableが存在する
            drawable.texture.width == drawTexture.width, drawable.texture.height == drawTexture.height, // drawable.texturのサイズとdrawTextureのサイズが一致する
            let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder() // blitEncoder生成
        else { throw ErrorType.draw }
        ///////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////
        // ブリットエンコード
        blitEncoder.copy(from: drawTexture,
                         sourceSlice: 0,
                         sourceLevel: 0,
                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSizeMake(drawable.texture.width, drawable.texture.height, drawable.texture.depth),
                         to: drawable.texture,
                         destinationSlice: 0,
                         destinationLevel: 0,
                         destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder.endEncoding()
        ///////////////////////////////////////////////////////////////////////////////////////////

        commandBuffer.present(drawable)
        commandBuffer.commit()
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

        fileprivate func _dispose() {
            self.ccview = nil
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
        }

        func input(imageProcess: CCImageProcess.ImageProcess) throws {
            let observation: NSKeyValueObservation = imageProcess.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCImageProcess.ImageProcess.Pipe, change) in
                guard
                    let self = self,
                    let outTexture: CCTexture = object.outTexture
                else { return }

                if outTexture.colorPixelFormat != self.ccview?.colorPixelFormat {
                    MCDebug.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                self.ccview?.drawTexture = outTexture
            }
            self.observations.append(observation)
        }

        func input(camera: CCCapture.Camera) throws {
            let observation: NSKeyValueObservation = camera.pipe.observe(\.outPixelPresentationTimeStamp, options: [.new]) { [weak self] (object: CCCapture.Camera.Pipe, change) in
                guard
                    let self = self,
                    let captureData: CCCapture.VideoCapture.CaptureData = object.currentVideoCaptureItem
                else { return }

                if captureData.mtlPixelFormat != self.ccview?.colorPixelFormat {
                    MCDebug.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
                do {
                    var drawTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: captureData.mtlPixelFormat, planeIndex: 0)
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
        }
    
        func input(player: CCPlayer) throws {
            let observation: NSKeyValueObservation = player.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCPlayer.Pipe, change) in
                guard let outTexture: CCTexture = object.outTexture else { return }

                guard let self = self else { return }

                if outTexture.colorPixelFormat != self.ccview?.colorPixelFormat {
                    MCDebug.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                self.ccview?.drawTexture = outTexture

            }
            self.observations.append(observation)
        }

        @available(iOS 13.0, *)
        func input(camera: CCARCapture.cARCamera) throws {
            let observation: NSKeyValueObservation = camera.pipe.observe(\.ouTimeStamp, options: [.new]) { [weak self] (object: CCARCapture.cARCamera.Pipe, change) in
                guard let captureData: CCARCapture.CaptureData = object.captureData else { return }

                guard let self = self else { return }
                if captureData.mtlPixelFormat != self.ccview?.colorPixelFormat {
                    MCDebug.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                let pixelBuffer: CVPixelBuffer = captureData.arFrame.capturedImage
                do {
                    var drawTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: captureData.mtlPixelFormat, planeIndex: 0)
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
        }
    }
}

extension CCView {
    public class Event {
        public var onUpdateStart: (() -> Void)?
        public var onUpdateComplete: (() -> Void)?

        public init() {}
    }
}
