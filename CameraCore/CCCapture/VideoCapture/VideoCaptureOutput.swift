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
        fileprivate(set) var depthDataOutput: AVCaptureDepthDataOutput?
        fileprivate(set) var outputSynchronizer: AVCaptureDataOutputSynchronizer?

        fileprivate(set) var captureVideoOrientation: AVCaptureVideoOrientation?

        var onUpdateSampleBuffer: ((_ sampleBuffer: CMSampleBuffer, _ captureVideoOrientation: AVCaptureVideoOrientation, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject]?) -> Void)?

        var onUpdateDepthData: ((_ depthData: AVDepthData) -> Void)?

        
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
            let videoDataOutput: AVCaptureVideoDataOutput = self.createVideoDataOutput(pixelFormatType: property.outPutPixelFormatType)
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

            if property.isDepthDataOutput {
                //////////////////////////////////////////////////////////
                // AVCaptureDepthDataOutput
                let depthDataOutput: AVCaptureDepthDataOutput = AVCaptureDepthDataOutput()
                if captureSession.canAddOutput(depthDataOutput) {
                    captureSession.addOutput(depthDataOutput)
                    depthDataOutput.isFilteringEnabled = true
                    depthDataOutput.setDelegate(self, callbackQueue: CCCapture.depthOutputQueue)
                    if let connection: AVCaptureConnection = depthDataOutput.connection(with: .depthData) {
                        connection.isEnabled = true
                        connection.isVideoMirrored = devicePosition == .front ? true : false

                        if let captureVideoOrientation: AVCaptureVideoOrientation = self.captureVideoOrientation {
                            // captureVideoOrientation が固定の場合
                            connection.videoOrientation = captureVideoOrientation
                        }

                        self.depthDataOutput = depthDataOutput
                        dataOutputs.append(self.depthDataOutput!)
                    } else {
                        MCDebug.errorLog("No AVCaptureDepthDataOutputConnection")
                        throw CCCapture.VideoCapture.VideoCaptureManager.ErrorType.setupError
                    }
                }
                //////////////////////////////////////////////////////////
                self.outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.videoDataOutput!, self.depthDataOutput!])
                self.outputSynchronizer!.setDelegate(self, queue: CCCapture.depthOutputQueue)
            }

            NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)

            self.setVideoOrientation()
        }
    }
}
/*
private extension CCCapture.VideoCapture.VideoCaptureOutput {
    class videoDataOutputSampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate {
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let connection: AVCaptureConnection = self.videoDataOutput?.connection(with: .video) else { return }
            //self.onUpdateSampleBuffer?(sampleBuffer, connection.videoOrientation, nil, nil)
            //print(CMSampleBufferGetImageBuffer(sampleBuffer))
        }
    }
    class audioDataOutputSampleBufferDelegate: AVCaptureAudioDataOutputSampleBufferDelegate {
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let connection: AVCaptureConnection = self.videoDataOutput?.connection(with: .video) else { return }
            //self.onUpdateSampleBuffer?(sampleBuffer, connection.videoOrientation, nil, nil)
            //print(CMSampleBufferGetImageBuffer(sampleBuffer))
        }
    }
}
*/
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
    func createVideoDataOutput(pixelFormatType: MCPixelFormatType) -> AVCaptureVideoDataOutput {
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: pixelFormatType.osType,
        ]

        return videoDataOutput
    }
}

extension CCCapture.VideoCapture.VideoCaptureOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let connection: AVCaptureConnection = self.videoDataOutput?.connection(with: .video) else { return }
        self.onUpdateSampleBuffer?(sampleBuffer, connection.videoOrientation, nil, nil)
    }
}
extension CCCapture.VideoCapture.VideoCaptureOutput: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        self.onUpdateDepthData?(depthData)
    }
}
extension CCCapture.VideoCapture.VideoCaptureOutput: AVCaptureDataOutputSynchronizerDelegate {
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        //print(1111)
        if let syncedDepthData = synchronizedDataCollection.synchronizedData(for: self.depthDataOutput!) as? AVCaptureSynchronizedDepthData, !syncedDepthData.depthDataWasDropped {
            let depthData = syncedDepthData.depthData
            print(depthData)
        }
        
        if let syncedVideoData = synchronizedDataCollection.synchronizedData(for: self.videoDataOutput!) as? AVCaptureSynchronizedSampleBufferData, !syncedVideoData.sampleBufferWasDropped {
            let videoSampleBuffer = syncedVideoData.sampleBuffer
            print("video")
            guard let connection: AVCaptureConnection = self.videoDataOutput?.connection(with: .video) else { return }
            self.onUpdateSampleBuffer?(videoSampleBuffer, connection.videoOrientation, nil, nil)
        }
    }
}

