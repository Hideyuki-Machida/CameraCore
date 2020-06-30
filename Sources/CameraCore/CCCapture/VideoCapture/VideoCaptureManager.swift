//
//  VideoCapture.swift
//  VideoPlayer
//
//  Created by machidahideyuki on 2017/04/21.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas

extension CCCapture.VideoCapture {
    public final class VideoCaptureManager {
        internal enum ErrorType: Error {
            case setupError
        }

        let captureOutput: VideoCaptureOutput = VideoCaptureOutput()

        var captureSession: AVCaptureSession?
        var videoDevice: AVCaptureDevice?

        var property: CCCapture.VideoCapture.Property = CCCapture.VideoCapture.Property()

        public var onUpdateSampleBuffer: ((_ sampleBuffer: CMSampleBuffer, _ captureVideoOrientation: AVCaptureVideoOrientation, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject]?) -> Void)? {
            get {
                return self.captureOutput.onUpdateSampleBuffer
            }
            set {
                self.captureOutput.onUpdateSampleBuffer = newValue
            }
        }

        public var onUpdateDepthData: ((_ depthData: AVDepthData) -> Void)? {
            get {
                return self.captureOutput.onUpdateDepthData
            }
            set {
                self.captureOutput.onUpdateDepthData = newValue
            }
        }

        public var onUpdateMetadataObjects: ((_ metadataObjects: [AVMetadataObject]) -> Void)? {
            get {
                return self.captureOutput.onUpdateMetadataObjects
            }
            set {
                self.captureOutput.onUpdateMetadataObjects = newValue
            }
        }

        
        let sessionQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.Queue")

        var currentVideoInput: AVCaptureDeviceInput? {
            return self.captureSession?.inputs
                .compactMap { $0 as? AVCaptureDeviceInput }
                .filter { $0.device.hasMediaType(AVMediaType.video) }.first
        }

        internal enum VideoSettingError: Error {
            case captureSetting
            case videoDataOutput
            case audioDataOutput
        }

        public init(property: CCCapture.VideoCapture.Property) throws {
            self.captureSession = AVCaptureSession()
            try self.setup(property: property)
        }

        func setup(property: CCCapture.VideoCapture.Property) throws {
            guard let captureSession: AVCaptureSession = self.captureSession else { return }
            self.property = property

            //////////////////////////////////////////////////////////
            // プロパティーセットアップ
            var propertyError: Bool = false
            do {
                try self.property.setup()
            } catch {
                propertyError = true
                self.property.captureInfo.trace()
            }
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            // AVCaptureDeviceを生成
            guard let videoDevice: AVCaptureDevice = self.property.captureInfo.device else { throw CCCapture.ErrorType.setup }
            guard let format: AVCaptureDevice.Format = self.property.captureInfo.deviceFormat else { throw CCCapture.ErrorType.setup }
            let depthDataFormat: AVCaptureDevice.Format? = self.property.captureInfo.depthDataFormat
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            // AVCaptureSessionを生成
            let isRunning: Bool = captureSession.isRunning
            if isRunning {
                captureSession.stopRunning()
            }
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            // captureSession.commitConfiguration()
            captureSession.beginConfiguration()

            defer {
                captureSession.commitConfiguration()
                if isRunning {
                    captureSession.startRunning()
                }
                self.captureSession = captureSession
            }
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            // AVCaptureOutputをリセット
            for i in captureSession.inputs { captureSession.removeInput(i) }
            for i in captureSession.outputs.reversed() { captureSession.removeOutput(i) }
            try self.captureOutput.set(videoDevice: videoDevice, captureSession: captureSession, property: property)
            //////////////////////////////////////////////////////////

            // ここから順番制あり
            // https://stackoverflow.com/questions/29910400/avfoundation-i-use-setactivevideominframeduration-didnt-work

            // キャプチャ解像度設定
            // この後の設定でsessionPresetに該当しないものは オートで AVCaptureSessionPresetInputPriorityに変更される。
            if captureSession.canSetSessionPreset(property.captureInfo.presetSize.aVCaptureSessionPreset) {
                captureSession.sessionPreset = property.captureInfo.presetSize.aVCaptureSessionPreset
            }

            //////////////////////////////////////////////////////////
            try videoDevice.lockForConfiguration()
            videoDevice.activeFormat = format
            if depthDataFormat != nil {
                videoDevice.activeDepthDataFormat = depthDataFormat
            }

            // フォーカスモード設定
            if videoDevice.isSmoothAutoFocusSupported {
                videoDevice.isSmoothAutoFocusEnabled = self.property.captureInfo.isSmoothAutoFocusEnabled
            }

            // カラースペース設定
            captureSession.automaticallyConfiguresCaptureDeviceForWideColor = false
            videoDevice.activeColorSpace = self.property.captureInfo.colorSpace

            // framerate設定
            let frameRate: Int32 = self.property.captureInfo.frameRate
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
            videoDevice.unlockForConfiguration()
            self.videoDevice = videoDevice
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            if propertyError {
                throw CCCapture.ErrorType.setup
            } else {
                MCDebug.successLog("Video Capture setup")
            }
            //////////////////////////////////////////////////////////
        }

        deinit {
            self.onUpdateSampleBuffer = nil
            MCDebug.deinitLog(self)
            guard let captureSession: AVCaptureSession = self.captureSession else { return }
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }

        public func play() {
            self.captureSession?.startRunning()
        }

        public func stop() {
            self.captureSession?.stopRunning()
        }

        /////////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

extension CCCapture.VideoCapture.VideoCaptureManager {
    public func update(property: CCCapture.VideoCapture.Property) throws {
        try self.setup(property: property)
    }
}

extension CCCapture.VideoCapture.VideoCaptureManager {
    // TODO: Torch は ライブでは使っていなかった。。。TorchModeをセットした際にエラーになるケースでUI側からは何が起こったかわからないので後日IFを改修
    public var isTorchActive: Bool {
        get {
            return self.videoDevice?.isTorchActive ?? false
        }
        set {
            let errorMessage: String = "CCCapture.VideoCapture.VideoCaptureManager.isTorchActive: set"
            guard
                let device: AVCaptureDevice = self.videoDevice,
                let torchMode: AVCaptureDevice.TorchMode = newValue ? .on : .off,
                device.isTorchModeSupported(torchMode)
            else {
                MCDebug.errorLog(errorMessage)
                return
            }

            do {
                try device.lockForConfiguration()
                device.torchMode = torchMode
                device.unlockForConfiguration()
            } catch {
                MCDebug.errorLog(errorMessage)
            }
        }
    }

    public var zoom: CGFloat {
        get {
            return self.videoDevice?.videoZoomFactor ?? 0
        }
        set {
            do {
                try self.videoDevice?.lockForConfiguration()
                self.videoDevice?.videoZoomFactor = newValue
                self.videoDevice?.unlockForConfiguration()
            } catch {
                MCDebug.errorLog("CCCapture.VideoCapture.VideoCaptureManager.zoom: set")
            }
        }
    }
}
