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

extension CCRenderer.VideoCapture {
    final class VideoCaptureOutput: NSObject {
        fileprivate let videoOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.VideoQueue")
        fileprivate let audioOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.AudioQueue")
        fileprivate let depthOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.DepthQueue")
        fileprivate let sessionQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.DepthQueue")

        fileprivate(set) var videoDataOutput: AVCaptureVideoDataOutput?
        fileprivate(set) var audioDataOutput: AVCaptureAudioDataOutput?

        var onUpdate: ((_ sampleBuffer: CMSampleBuffer, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject]?) -> Void)?

        deinit {
            NotificationCenter.default.removeObserver(self)
            MCDebug.deinitLog(self)
        }

        internal func set(videoDevice: AVCaptureDevice, captureSession: AVCaptureSession, property: CCRenderer.VideoCapture.Property) throws {
            let devicePosition: AVCaptureDevice.Position = property.captureInfo.devicePosition

            var dataOutputs: [AVCaptureOutput] = []

            //////////////////////////////////////////////////////////
            // AVCaptureVideoDataOutput
            let videoDataInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            let videoDataOutput: AVCaptureVideoDataOutput = self.createVideoDataOutput()
            if captureSession.canAddInput(videoDataInput), captureSession.canAddOutput(videoDataOutput) {
                videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
                captureSession.addInput(videoDataInput)
                captureSession.addOutput(videoDataOutput)
                if let connection: AVCaptureConnection = videoDataOutput.connection(with: .video) {
                    connection.isEnabled = true
                    connection.isVideoMirrored = devicePosition == .front ? true : false
                    connection.videoOrientation = Settings.captureVideoOrientation

                    self.videoDataOutput = videoDataOutput
                    dataOutputs.append(videoDataOutput)
                } else {
                    MCDebug.errorLog("AVCaptureVideoDataOutputConnection")
                    throw CCRenderer.VideoCapture.VideoCaptureManager.ErrorType.setupError
                }
            }
            //////////////////////////////////////////////////////////

            if property.isAudioDataOutput {
                //////////////////////////////////////////////////////////
                // AVCaptureAudioDataOutput
                guard let audioDevice: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio) else { throw CCRenderer.VideoCapture.VideoCaptureManager.ErrorType.setupError }
                let audioInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
                let audioDataOutput: AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
                if captureSession.canAddInput(audioInput), captureSession.canAddOutput(audioDataOutput) {
                    audioDataOutput.setSampleBufferDelegate(self, queue: self.audioOutputQueue)
                    captureSession.addInput(audioInput)
                    captureSession.addOutput(audioDataOutput)
                    if let connection: AVCaptureConnection = audioDataOutput.connection(with: .audio) {
                        connection.isEnabled = true
                        self.audioDataOutput = audioDataOutput
                        dataOutputs.append(audioDataOutput)
                    } else {
                        MCDebug.errorLog("AVCaptureAudioDataOutputConnection")
                        throw CCRenderer.VideoCapture.VideoCaptureManager.ErrorType.setupError
                    }
                }
                //////////////////////////////////////////////////////////
            }

            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }
}

extension CCRenderer.VideoCapture.VideoCaptureOutput {
    @objc private func orientationDidChange(_ notification: Notification) {
        guard let connection: AVCaptureConnection = self.videoDataOutput?.connection(with: .video) else { return }
        connection.videoOrientation = Settings.captureVideoOrientation
    }
}

extension CCRenderer.VideoCapture.VideoCaptureOutput {
    /// AVCaptureVideoDataOutputを生成
    fileprivate func createVideoDataOutput() -> AVCaptureVideoDataOutput {
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Configuration.outputPixelBufferPixelFormatTypeKey,
        ]

        return videoDataOutput
    }
}

extension CCRenderer.VideoCapture.VideoCaptureOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.onUpdate?(sampleBuffer, nil, nil)
    }
}
