//
//  VideoCaptureOutput.swift
//  CCamVideo
//
//  Created by hideyuki machida on 2018/08/05.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas

extension CCRenderer.VideoCapture {
    final class VideoCaptureOutput: NSObject {
        fileprivate let videoOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.VideoQueue")
        fileprivate let audioOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.AudioQueue")
        fileprivate let depthOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.DepthQueue")
        fileprivate let sessionQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.DepthQueue")

        fileprivate(set) var videoDataOutput: AVCaptureVideoDataOutput?
        fileprivate(set) var audioDataOutput: AVCaptureAudioDataOutput?

        var onUpdate: ((_ sampleBuffer: CMSampleBuffer, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject]?)->Void)?

        override init () {
            super.init()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
                MCDebug.deinitLog(self)
            }
        

        internal func set(captureSession: AVCaptureSession, propertys: CCRenderer.VideoCapture.Propertys) throws {
            let devicePosition: AVCaptureDevice.Position = propertys.info.devicePosition
            
            var dataOutputs: [AVCaptureOutput] = []
            
            //////////////////////////////////////////////////////////
            // AVCaptureVideoDataOutput
            let videoDataOutput: AVCaptureVideoDataOutput = try self.getVideoDataOutput()
            if captureSession.canAddOutput(videoDataOutput) {
                videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
                captureSession.addOutput(videoDataOutput)
                if let connection: AVCaptureConnection = videoDataOutput.connection(with: .video) {
                    connection.isEnabled = true
                    connection.isVideoMirrored = devicePosition == .front ? true : false
                    connection.videoOrientation = Settings.captureVideoOrientation

                    self.videoDataOutput = videoDataOutput
                    dataOutputs.append(self.videoDataOutput!)
                } else {
                    MCDebug.errorLog("AVCaptureVideoDataOutputConnection")
                    throw CCRenderer.VideoCapture.VideoCapture.ErrorType.setupError
                }
            }
            //////////////////////////////////////////////////////////

            if propertys.isAudioDataOutput {
                //////////////////////////////////////////////////////////
                // AVCaptureAudioDataOutput
                let audioDataOutput: AVCaptureAudioDataOutput = try self.getAudioDataOutput(captureSession: captureSession)
                if captureSession.canAddOutput(audioDataOutput) {
                    audioDataOutput.setSampleBufferDelegate(self, queue: self.audioOutputQueue)
                    captureSession.addOutput(audioDataOutput)
                    if let connection: AVCaptureConnection = audioDataOutput.connection(with: .audio) {
                        connection.isEnabled = true
                        self.audioDataOutput = audioDataOutput
                        dataOutputs.append(self.videoDataOutput!)
                    } else {
                        MCDebug.errorLog("AVCaptureAudioDataOutputConnection")
                        throw CCRenderer.VideoCapture.VideoCapture.ErrorType.setupError
                    }
                }
                //////////////////////////////////////////////////////////
            }

            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationDidChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }
}

extension CCRenderer.VideoCapture.VideoCaptureOutput {
    @objc
    func onOrientationDidChange(notification: NSNotification) {
        guard let connection: AVCaptureConnection = self.videoDataOutput?.connection(with: .video) else { return }
        connection.videoOrientation = Settings.captureVideoOrientation
    }
}

extension CCRenderer.VideoCapture.VideoCaptureOutput {
        /// AVCaptureVideoDataOutputを生成
    fileprivate func getVideoDataOutput() throws -> AVCaptureVideoDataOutput {
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Configuration.outputPixelBufferPixelFormatTypeKey
        ]

        return videoDataOutput
    }
    
    /// AVCaptureAudioDataOutputを生成
    fileprivate func getAudioDataOutput(captureSession: AVCaptureSession) throws -> AVCaptureAudioDataOutput {
        do {
            let audioDevice: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio)!
            let audioInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
    
            let audioDataOutput: AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
            return audioDataOutput
        } catch {
            throw CCRenderer.VideoCapture.VideoCapture.VideoSettingError.audioDataOutput
        }
    }
}

extension CCRenderer.VideoCapture.VideoCaptureOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.onUpdate?(sampleBuffer, nil, nil)
    }
}
