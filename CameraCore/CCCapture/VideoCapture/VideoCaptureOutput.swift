//
//  VideoCaptureOutput.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/05.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas

extension CCCapture.VideoCapture {
    final class VideoCaptureOutput: NSObject {
        fileprivate let sessionQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.DepthQueue")

        fileprivate(set) var videoDataOutput: AVCaptureVideoDataOutput?
        fileprivate(set) var audioDataOutput: AVCaptureAudioDataOutput?

        fileprivate(set) var captureVideoOrientation: AVCaptureVideoOrientation?

        var onUpdate: ((_ sampleBuffer: CMSampleBuffer, _ captureVideoOrientation: AVCaptureVideoOrientation, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject]?) -> Void)?

        deinit {
            NotificationCenter.default.removeObserver(self)
            MCDebug.deinitLog(self)
        }

        func set(videoDevice: AVCaptureDevice, captureSession: AVCaptureSession, property: CCCapture.VideoCapture.Property) throws {
            let devicePosition: AVCaptureDevice.Position = property.captureInfo.devicePosition

            var dataOutputs: [AVCaptureOutput] = []
            self.captureVideoOrientation = property.captureVideoOrientation

            //////////////////////////////////////////////////////////
            // AVCaptureVideoDataOutput
            let videoDataInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            let videoDataOutput: AVCaptureVideoDataOutput = self.createVideoDataOutput()
            if captureSession.canAddInput(videoDataInput), captureSession.canAddOutput(videoDataOutput) {
                videoDataOutput.setSampleBufferDelegate(self, queue: CCCapture.videoOutputQueue)
                captureSession.addInput(videoDataInput)
                captureSession.addOutput(videoDataOutput)
                if let connection: AVCaptureConnection = videoDataOutput.connection(with: .video) {
                    connection.isEnabled = true
                    connection.isVideoMirrored = devicePosition == .front ? true : false

                    if let captureVideoOrientation: AVCaptureVideoOrientation = self.captureVideoOrientation {
                        // captureVideoOrientation が固定の場合
                        connection.videoOrientation = captureVideoOrientation
                    }

                    self.videoDataOutput = videoDataOutput
                    dataOutputs.append(videoDataOutput)
                } else {
                    MCDebug.errorLog("AVCaptureVideoDataOutputConnection")
                    throw CCCapture.VideoCapture.VideoCaptureManager.ErrorType.setupError
                }
            }
            //////////////////////////////////////////////////////////

            if property.isAudioDataOutput {
                //////////////////////////////////////////////////////////
                // AVCaptureAudioDataOutput
                guard let audioDevice: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio) else { throw CCCapture.VideoCapture.VideoCaptureManager.ErrorType.setupError }
                let audioInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                let audioDataOutput: AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
                if captureSession.canAddInput(audioInput), captureSession.canAddOutput(audioDataOutput) {
                    audioDataOutput.setSampleBufferDelegate(self, queue: CCCapture.audioOutputQueue)
                    captureSession.addInput(audioInput)
                    captureSession.addOutput(audioDataOutput)
                    if let connection: AVCaptureConnection = audioDataOutput.connection(with: .audio) {
                        connection.isEnabled = true
                        self.audioDataOutput = audioDataOutput
                        dataOutputs.append(audioDataOutput)
                    } else {
                        MCDebug.errorLog("AVCaptureAudioDataOutputConnection")
                        throw CCCapture.VideoCapture.VideoCaptureManager.ErrorType.setupError
                    }
                }
                //////////////////////////////////////////////////////////
            }

            NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)

            self.setVideoOrientation()
        }
    }
}

private extension CCCapture.VideoCapture.VideoCaptureOutput {
    @objc func orientationDidChange(_ notification: Notification) {
        self.setVideoOrientation()
    }

    func setVideoOrientation() {
        guard self.captureVideoOrientation == nil else { return }
        // captureVideoOrientation が固定ではない
        guard let connection: AVCaptureConnection = self.videoDataOutput?.connection(with: .video) else { return }
        DispatchQueue.main.async {
            // UIApplication.shared.statusBarOrientation.toAVCaptureVideoOrientation はメインスレッドからしか呼べない
            guard
                let captureVideoOrientation: AVCaptureVideoOrientation = UIApplication.shared.statusBarOrientation.toAVCaptureVideoOrientation
            else { return }
            connection.videoOrientation = captureVideoOrientation
        }
    }
}

private extension CCCapture.VideoCapture.VideoCaptureOutput {
    /// AVCaptureVideoDataOutputを生成
    func createVideoDataOutput() -> AVCaptureVideoDataOutput {
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Configuration.shared.outputPixelBufferPixelFormatTypeKey,
        ]

        return videoDataOutput
    }
}

extension CCCapture.VideoCapture.VideoCaptureOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let connection: AVCaptureConnection = self.videoDataOutput?.connection(with: .video) else { return }
        self.onUpdate?(sampleBuffer, connection.videoOrientation, nil, nil)
    }
}

