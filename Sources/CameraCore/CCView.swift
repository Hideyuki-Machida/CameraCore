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
import ProcessLogger_Swift

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
    fileprivate(set) var presentationTimeStamp: CCVariable<CMTime> = CCVariable(CMTime.zero)
    fileprivate(set) var isDraw: CCVariable<Bool> = CCVariable(false)
    fileprivate(set) var drawTexture: CCVariable<CCTexture?> = CCVariable(nil)

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
        ProcessLogger.deinitLog(self)
    }
}

extension CCView: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    public func draw(in view: MTKView) {
        ///////////////////////////////////////////////////////////////////////////////////////////
        guard
            !self.isDraw.value, // draw処理が完了している
            let drawTexture: CCTexture = self.drawTexture.value, // drawTextureが存在する
        self.presentationTimeStamp.value != drawTexture.presentationTimeStamp, // 直前に処理を行ったpresentationTimeStampとdrawTexture.presentationTimeStampが一致しない
            let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() // MTLCommandBufferを生成
        else { return }
        ///////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////
        // 処理判定用のフラグセット
        commandBuffer.addCompletedHandler { [weak self] (_: MTLCommandBuffer) in
            // drawの処理が完了
            self?.isDraw.value = false

            // 処理完了のイベント発行
            //self?.event?.onUpdateComplete?()

            // デバッグモードの場合にデバッグ情報をupdate
            self?.debug?.update()
        }

        self.isDraw.value = true
        self.presentationTimeStamp.value = drawTexture.presentationTimeStamp
        ///////////////////////////////////////////////////////////////////////////////////////////

        do {
            // 描画処理
            try self.drawUpdate(commandBuffer: commandBuffer, drawTexture: drawTexture.texture)
        } catch {
            // drawの処理が完了できなかった
            self.isDraw.value = false
            ProcessLogger.errorLog("CCView draw")
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
        self.isDraw.value = false
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
            imageProcess.pipe.texture.bind() { [weak self] (texture: CCTexture?) in
                guard
                    let self = self,
                    let outTexture: CCTexture = texture
                else { return }

                if outTexture.colorPixelFormat != self.ccview?.colorPixelFormat {
                    ProcessLogger.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                self.ccview?.drawTexture.value = outTexture
            }
        }

        func input(camera: CCCapture.Camera) throws {
            camera.pipe.videoCaptureItem.bind() { [weak self] (captureData: CCCapture.VideoCapture.CaptureData?) in
                guard
                    let self = self,
                    let captureData: CCCapture.VideoCapture.CaptureData = captureData
                else { return }

                if captureData.mtlPixelFormat != self.ccview?.colorPixelFormat {
                    ProcessLogger.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
                do {
                    var drawTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: captureData.mtlPixelFormat, planeIndex: 0)
                    drawTexture.presentationTimeStamp = captureData.presentationTimeStamp
                    drawTexture.captureVideoOrientation = captureData.captureVideoOrientation
                    drawTexture.presetSize = captureData.captureInfo.presetSize

                    DispatchQueue.main.async { [weak self] in
                        self?.ccview?.drawTexture.value = drawTexture
                    }

                } catch {
                    ProcessLogger.errorLog("CCView: onUpdateCaptureData drawTexture")
                }

            }
        }
    
        func input(player: CCPlayer) throws {
            let observation: NSKeyValueObservation = player.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCPlayer.Pipe, change) in
                guard let outTexture: CCTexture = object.outTexture else { return }

                guard let self = self else { return }

                if outTexture.colorPixelFormat != self.ccview?.colorPixelFormat {
                    ProcessLogger.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                self.ccview?.drawTexture.value = outTexture

            }
            self.observations.append(observation)
        }

        @available(iOS 13.0, *)
        func input(camera: CCARCapture.cARCamera) throws {
            let observation: NSKeyValueObservation = camera.pipe.observe(\.ouTimeStamp, options: [.new]) { [weak self] (object: CCARCapture.cARCamera.Pipe, change) in
                guard let captureData: CCARCapture.CaptureData = object.captureData else { return }

                guard let self = self else { return }
                if captureData.mtlPixelFormat != self.ccview?.colorPixelFormat {
                    ProcessLogger.errorLog("CCView: onUpdateCaptureData colorPixelFormat")
                    return
                }

                let pixelBuffer: CVPixelBuffer = captureData.arFrame.capturedImage
                do {
                    var drawTexture: CCTexture = try CCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: captureData.mtlPixelFormat, planeIndex: 0)
                    drawTexture.presentationTimeStamp = captureData.presentationTimeStamp
                    drawTexture.captureVideoOrientation = captureData.captureVideoOrientation
                    drawTexture.presetSize = captureData.captureInfo.presetSize

                    DispatchQueue.main.async { [weak self] in
                        self?.ccview?.drawTexture.value = drawTexture
                    }

                } catch {
                    ProcessLogger.errorLog("CCView: onUpdateCaptureData drawTexture")
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
