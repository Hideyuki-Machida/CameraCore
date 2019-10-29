//
//  VideoCapture.swift
//  VideoPlayer
//
//  Created by machidahideyuki on 2017/04/21.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import MetalCanvas

extension CCRenderer.VideoCapture {
    public final class VideoCapture {
        
        internal enum ErrorType: Error {
            case setupError
        }
        
        let captureOutput: VideoCaptureOutput = VideoCaptureOutput()
        
        var captureSession: AVCaptureSession?
        var videoDevice: AVCaptureDevice?

        var propertys: CCRenderer.VideoCapture.Propertys = Configuration.defaultVideoCapturePropertys
        
        public var onUpdate: ((_ sampleBuffer: CMSampleBuffer, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject]?)->Void)? {
            get {
                return self.captureOutput.onUpdate
            }
            set {
                self.captureOutput.onUpdate = newValue
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
        
        public init(propertys: CCRenderer.VideoCapture.Propertys) throws {
            self.captureSession = AVCaptureSession()
            try self.setup(propertys: propertys)
        }

        func setup(propertys: CCRenderer.VideoCapture.Propertys) throws {
            guard let captureSession: AVCaptureSession = self.captureSession else { return }
            self.propertys = propertys

            //////////////////////////////////////////////////////////
            // プロパティーセットアップ
            var propertyError: Bool = false
            do {
                try self.propertys.setup()
            } catch {
                propertyError = true
                self.propertys.info.trace()
            }
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            // AVCaptureDeviceを生成
            guard let videoDevice: AVCaptureDevice = self.propertys.info.device else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            guard let format: AVCaptureDevice.Format = self.propertys.info.deviceFormat else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            // AVCaptureSessionを生成
            let isRunning: Bool = captureSession.isRunning
            /*
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
             */
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            //captureSession.commitConfiguration()
            captureSession.beginConfiguration()
            MCDebug.log("Video Capture beginConfiguration")

            defer {
                captureSession.commitConfiguration()
                if isRunning {
                    captureSession.startRunning()
                }
                self.captureSession = captureSession
                MCDebug.log("Video Capture commitConfiguration")
                if !propertyError {
                    MCDebug.successLog("Video Capture setup")
                }
            }
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            // AVCaptureDeviceInputを生成
            let videoCaptureDeviceInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            // AVCaptureVideoDataOutputを登録
            for i in captureSession.inputs { captureSession.removeInput(i) }
            self.captureSession?.addInput(videoCaptureDeviceInput)

            for i in captureSession.outputs { captureSession.removeOutput(i) }
            try self.captureOutput.set(captureSession: captureSession, propertys: propertys)
            //////////////////////////////////////////////////////////

            // ここから順番制あり
            // https://stackoverflow.com/questions/29910400/avfoundation-i-use-setactivevideominframeduration-didnt-work
            
            // キャプチャ解像度設定
            // この後の設定でsessionPresetに該当しないものは オートで AVCaptureSessionPresetInputPriorityに変更される。
            if captureSession.canSetSessionPreset(propertys.info.presetSize.aVCaptureSessionPreset()) {
                captureSession.sessionPreset = propertys.info.presetSize.aVCaptureSessionPreset()
            }
            
            //////////////////////////////////////////////////////////
            try videoDevice.lockForConfiguration()
            videoDevice.activeFormat = format

            // フォーカスモード設定
            if videoDevice.isSmoothAutoFocusSupported {
                videoDevice.isSmoothAutoFocusEnabled = self.propertys.info.isSmoothAutoFocusEnabled
            }

            // カラースペース設定
            videoDevice.activeColorSpace = self.propertys.info.colorSpace

            // framerate設定
            let frameRate: Int32 = self.propertys.info.frameRate
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
            videoDevice.unlockForConfiguration()
            self.videoDevice = videoDevice
            //////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////
            if propertyError {
                throw CCRenderer.VideoCapture.ErrorType.setupError
            }
            //////////////////////////////////////////////////////////
        }

        deinit {
            self.onUpdate = nil
            MCDebug.log(self)
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

extension CCRenderer.VideoCapture.VideoCapture {
    public func update(propertys: CCRenderer.VideoCapture.Propertys) throws {
        try self.setup(propertys: propertys)
    }
}

extension CCRenderer.VideoCapture.VideoCapture {

    // ビデオHDR設定
    public var isTouchActive: Bool {
        get {
            guard let device = self.videoDevice else { return false }
            return device.isTorchActive
        }
        set {
            guard let device = self.videoDevice else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = newValue ? .on : .off
                device.unlockForConfiguration()
            } catch {
                return
            }
        }
    }
    
    public var zoom: CGFloat {
        get {
            guard let device = self.videoDevice else { return 0 }
            return device.videoZoomFactor
        }
        set {
            do {
                try self.videoDevice?.lockForConfiguration()
                self.videoDevice?.videoZoomFactor = newValue
                self.videoDevice?.unlockForConfiguration()
            } catch {
                return
            }
        }
    }

}
