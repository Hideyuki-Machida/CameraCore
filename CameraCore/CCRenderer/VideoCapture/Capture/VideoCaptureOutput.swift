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
        fileprivate(set) var videoDepthDataOutput: AVCaptureDepthDataOutput?
        fileprivate(set) var metadataOutput: AVCaptureMetadataOutput?
        fileprivate(set) var outputSynchronizer: AVCaptureDataOutputSynchronizer?


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

            if propertys.info.isDepthDataOut {
                //////////////////////////////////////////////////////////
                // AVCaptureDepthDataOutput
                let videoDepthDataOutput: AVCaptureDepthDataOutput = AVCaptureDepthDataOutput()
                if captureSession.canAddOutput(videoDepthDataOutput) {
                    captureSession.addOutput(videoDepthDataOutput)
                    videoDepthDataOutput.isFilteringEnabled = true
                    videoDepthDataOutput.setDelegate(self, callbackQueue: self.depthOutputQueue)
                    if let connection: AVCaptureConnection = videoDepthDataOutput.connection(with: .depthData) {
                        connection.isEnabled = true
                        self.videoDepthDataOutput = videoDepthDataOutput
                        dataOutputs.append(self.videoDepthDataOutput!)
                    } else {
                        Debug.ErrorLog("AVCaptureDepthDataOutputConnection")
                        throw CCRenderer.VideoCapture.VideoCapture.ErrorType.setupError
                    }
                }
                //////////////////////////////////////////////////////////
                
                //////////////////////////////////////////////////////////
                // AVCaptureMetadataOutput
                let metadataOutput: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
                if captureSession.canAddOutput(metadataOutput) {
                    captureSession.addOutput(metadataOutput)
                    if metadataOutput.availableMetadataObjectTypes.contains(.face) {
                        metadataOutput.metadataObjectTypes = [.face]
                        self.metadataOutput = metadataOutput
                        dataOutputs.append(self.metadataOutput!)
                    } else {
                        Debug.ErrorLog("AVCaptureMetadataOutputConnection")
                        throw CCRenderer.VideoCapture.VideoCapture.ErrorType.setupError
                    }
                }
                //////////////////////////////////////////////////////////

                self.outputSynchronizer = AVCaptureDataOutputSynchronizer.init(dataOutputs: dataOutputs)
                self.outputSynchronizer!.setDelegate(self, queue: self.depthOutputQueue)
            } else {
                self.videoDepthDataOutput = nil
                self.metadataOutput = nil
                self.outputSynchronizer = nil
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

extension CCRenderer.VideoCapture.VideoCaptureOutput: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        print("AVCaptureDepthDataOutput")
        print(depthData)
    }
}

extension CCRenderer.VideoCapture.VideoCaptureOutput: AVCaptureDataOutputSynchronizerDelegate {
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        var depthData: AVDepthData?
        var metadataObjects: [AVMetadataObject]?
        
        if let depthDataOutput: AVCaptureDepthDataOutput = self.videoDepthDataOutput, let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData {
            depthData = syncedDepthData.depthData
        }
        
        if let metadataOutput: AVCaptureMetadataOutput = self.metadataOutput, let syncedMetaData: AVCaptureSynchronizedMetadataObjectData = synchronizedDataCollection.synchronizedData(for: metadataOutput) as? AVCaptureSynchronizedMetadataObjectData {
            if let connection = self.videoDataOutput?.connection(with: AVMediaType.video), syncedMetaData.metadataObjects.count >= 1 {
                metadataObjects = []
                for metadataObject in syncedMetaData.metadataObjects {
                    if let face: AVMetadataObject = self.videoDataOutput?.transformedMetadataObject(for: metadataObject, connection: connection) {
                        metadataObjects?.append(face)
                        
                    }
                }
            }
        }
        
        if let videoDataOutput: AVCaptureVideoDataOutput = self.videoDataOutput, let syncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as?AVCaptureSynchronizedSampleBufferData {
            self.onUpdate?(syncedVideoData.sampleBuffer, depthData, metadataObjects)
            
        }
        
    }
}
