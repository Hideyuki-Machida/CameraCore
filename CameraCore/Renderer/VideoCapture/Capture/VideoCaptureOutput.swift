//
//  VideoCaptureOutput.swift
//  CCamVideo
//
//  Created by hideyuki machida on 2018/08/05.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

extension Renderer.VideoCapture {
	final class VideoCaptureOutput: NSObject {
		fileprivate let videoOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.VideoQueue")
		fileprivate let audioOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.AudioQueue")
		fileprivate let depthOutputQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.DepthQueue")
		fileprivate let sessionQueue: DispatchQueue = DispatchQueue(label: "MetalCanvas.VideoCapture.DepthQueue", attributes: .concurrent)

		var captureSession: AVCaptureSession?
		
		fileprivate(set) var videoDataOutput: AVCaptureVideoDataOutput?
		fileprivate(set) var audioDataOutput: AVCaptureAudioDataOutput?
		fileprivate(set) var videoDepthDataOutput: AVCaptureDepthDataOutput?
		fileprivate(set) var metadataOutput: AVCaptureMetadataOutput?
		fileprivate(set) var outputSynchronizer: AVCaptureDataOutputSynchronizer?
		fileprivate(set) var currentOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait

		var onUpdate: ((_ sampleBuffer: CMSampleBuffer, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject]?)->Void)?
		
		override init () {
			super.init()
		}
		
		deinit {
			Debug.DeinitLog(self)
			NotificationCenter.default.removeObserver(self)
		}
		
		internal func set(position: AVCaptureDevice.Position) throws {
			guard self.captureSession != nil else { throw Renderer.VideoCapture.VideoCapture.ErrorType.setupError }

			let orienation: AVCaptureVideoOrientation = currentOrientation
			var dataOutputs: [AVCaptureOutput] = []
			
			//////////////////////////////////////////////////////////
			// AVCaptureVideoDataOutput
			let videoDataOutput: AVCaptureVideoDataOutput = try self._getVideoDataOutput()
			if self.captureSession!.canAddOutput(videoDataOutput) {
				videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
				self.captureSession?.addOutput(videoDataOutput)
				if let connection: AVCaptureConnection = videoDataOutput.connection(with: .video) {
					connection.isEnabled = true
					connection.isVideoMirrored = position == .front ? true : false
					connection.videoOrientation = orienation

					self.videoDataOutput = videoDataOutput
					dataOutputs.append(self.videoDataOutput!)
				} else {
					Debug.ActionLog("No AVCaptureVideoDataOutputConnection")
				}
			}
			//////////////////////////////////////////////////////////
			
			/**/
			//////////////////////////////////////////////////////////
			// AVCaptureAudioDataOutput
			let audioDataOutput: AVCaptureAudioDataOutput = try self._getAudioDataOutput()
			if self.captureSession!.canAddOutput(audioDataOutput) {
				audioDataOutput.setSampleBufferDelegate(self, queue: self.audioOutputQueue)
				self.captureSession?.addOutput(audioDataOutput)
				if let connection: AVCaptureConnection = audioDataOutput.connection(with: .audio) {
					connection.isEnabled = true
				} else {
					Debug.ActionLog("No AVCaptureAudioDataOutputConnection")
				}
				self.audioDataOutput = audioDataOutput
			}
			//////////////////////////////////////////////////////////
			/**/
			
			//////////////////////////////////////////////////////////
			// AVCaptureDepthDataOutput
			let videoDepthDataOutput: AVCaptureDepthDataOutput = AVCaptureDepthDataOutput()
			if self.captureSession!.canAddOutput(videoDepthDataOutput) {
				self.captureSession?.addOutput(videoDepthDataOutput)
				videoDepthDataOutput.isFilteringEnabled = true
				videoDepthDataOutput.setDelegate(self, callbackQueue: self.depthOutputQueue)
				if let connection: AVCaptureConnection = videoDepthDataOutput.connection(with: .depthData) {
					print("isVideoOrientationSupported")
					print(connection.isVideoOrientationSupported)
					connection.isEnabled = true
					/*
					if position == .front {
					//connection.videoOrientation = orienation
					}
					*/
					//connection.isVideoMirrored = position == .front ? true : false
					//connection.videoOrientation = orienation
					//connection.videoOrientation = .portraitUpsideDown
					//connection.isVideoMirrored = true
					self.videoDepthDataOutput = videoDepthDataOutput
					dataOutputs.append(self.videoDepthDataOutput!)
				} else {
					print("No AVCaptureDepthDataOutputConnection")
				}
			}
			//////////////////////////////////////////////////////////
			
			//////////////////////////////////////////////////////////
			// AVCaptureMetadataOutput
			let metadataOutput: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
			if self.captureSession!.canAddOutput(metadataOutput) {
				self.captureSession?.addOutput(metadataOutput)
				if metadataOutput.availableMetadataObjectTypes.contains(.face) {
					metadataOutput.metadataObjectTypes = [.face]
					self.metadataOutput = metadataOutput
					dataOutputs.append(self.metadataOutput!)
				} else {
					print("No AVCaptureMetadataOutputConnection")
				}
				
				/*
				metadataOutput.metadataObjectTypes = [.face]
				if let connection: AVCaptureConnection = metadataOutput.connection(with: .metadata) {
				connection.isEnabled = true
				connection.isVideoMirrored = position == .front ? true : false
				connection.videoOrientation = orienation
				
				self.metadataOutput = metadataOutput
				dataOutputs.append(self.metadataOutput!)
				} else {
				print("No AVCaptureMetadataOutputConnection")
				}
				*/
			}
			//////////////////////////////////////////////////////////

			self.outputSynchronizer = AVCaptureDataOutputSynchronizer.init(dataOutputs: dataOutputs)
			self.outputSynchronizer!.setDelegate(self, queue: self.depthOutputQueue)
			self.captureSession?.commitConfiguration()
		}
		
	}
}

extension Renderer.VideoCapture.VideoCaptureOutput {
	@objc
	func onOrientationDidChange(notification: NSNotification) {
		self.currentOrientation = AVCaptureVideoOrientation.init(ui: UIApplication.shared.statusBarOrientation)
	}
}

extension Renderer.VideoCapture.VideoCaptureOutput {
    /// AVCaptureVideoDataOutputを生成
    fileprivate func _getVideoDataOutput() throws -> AVCaptureVideoDataOutput {
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Configuration.outputPixelBufferPixelFormatTypeKey
        ]
        
        return videoDataOutput
    }
    
    /// AVCaptureAudioDataOutputを生成
    fileprivate func _getAudioDataOutput() throws -> AVCaptureAudioDataOutput {
        do {
            let audioDevice: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio)!
            let audioInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
			if self.captureSession!.canAddInput(audioInput) {
				self.captureSession?.addInput(audioInput)
			}
			
            let audioDataOutput: AVCaptureAudioDataOutput = AVCaptureAudioDataOutput()
            return audioDataOutput
        } catch {
            throw Renderer.VideoCapture.VideoCapture.VideoSettingError.audioDataOutput
        }
        
    }
}

extension Renderer.VideoCapture.VideoCaptureOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		//self.onUpdate?(sampleBuffer)
    }
}

extension Renderer.VideoCapture.VideoCaptureOutput: AVCaptureDepthDataOutputDelegate {
	@available(iOS 11.0, *)
	func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
		print("AVCaptureDepthDataOutput")
		print(depthData)
	}
	
	/*
	func depthDataOutput(_ output: AVCaptureDepthDataOutput, didDrop depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection, reason: AVCaptureOutput.DataDroppedReason) {
	
	}
	*/
}

extension Renderer.VideoCapture.VideoCaptureOutput: AVCaptureDataOutputSynchronizerDelegate {
	func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
		var depthData: AVDepthData?
		var metadataObjects: [AVMetadataObject]?
		
		if let depthDataOutput: AVCaptureDepthDataOutput = self.videoDepthDataOutput, let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData {
			
			print("AVCaptureDepthDataOutput")
			print(syncedDepthData.depthDataWasDropped)
			print(syncedDepthData.depthData)
			
			depthData = syncedDepthData.depthData
		}
		
		if let metadataOutput: AVCaptureMetadataOutput = self.metadataOutput, let syncedMetaData: AVCaptureSynchronizedMetadataObjectData = synchronizedDataCollection.synchronizedData(for: metadataOutput) as? AVCaptureSynchronizedMetadataObjectData {
			
			print("AVCaptureMetadataOutput")
			print(syncedMetaData.metadataObjects)
			
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
			
			print("AVCaptureOutput")
			self.onUpdate?(syncedVideoData.sampleBuffer, depthData, metadataObjects)
			
		}
		
	}
}
