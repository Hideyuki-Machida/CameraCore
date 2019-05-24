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
		fileprivate let videoOutputQueue: DispatchQueue = DispatchQueue(label: "CCamera.VideoCapture.VideoQueue")
		fileprivate let audioOutputQueue: DispatchQueue = DispatchQueue(label: "CCamera.VideoCapture.AudioQueue")
		fileprivate let sessionQueue: DispatchQueue = DispatchQueue(label: "CCamera.VideoCapture.DepthQueue", attributes: .concurrent)

		var captureSession: AVCaptureSession?
		
		fileprivate(set) var videoDataOutput: AVCaptureVideoDataOutput?
		fileprivate(set) var audioDataOutput: AVCaptureAudioDataOutput?
		fileprivate(set) var metadataOutput: AVCaptureMetadataOutput?
		fileprivate(set) var currentOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
		
		var onUpdate: ((_ sampleBuffer: CMSampleBuffer)->Void)?
		
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
		self.onUpdate?(sampleBuffer)
    }
}

