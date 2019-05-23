//
//  CaptureAudioSession.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
/*
final class CaptureAudioSession: NSObject {
	
	var captureAudioBufferHandler: ((CMSampleBuffer) -> Void)?
	
	let fileType: String = AVFileTypeCoreAudioFormat
	
	let queue: DispatchQueue = DispatchQueue(label: "CameraCore.camera_capture_audio_session.queue")
	
	fileprivate var session : AVCaptureSession?
	
	var canUseSession: Bool { return self.session != nil }
	
	deinit {
		SodaCore.printFunc()
		self.cleanup()
	}
	
	override init() {
		super.init()
		
		self.setupCamera()
	}
	
	private func setupCamera() {
		let session = AVCaptureSession()
		session.beginConfiguration()
		session.sessionPreset = AVCaptureSessionPresetLow
		
		if session.addInputIfPossible(self.generateAudioInput()) {
			_ = session.addOutputIfPossible(self.generateAudioOutput())
		}
		
		session.commitConfiguration()
		self.session = session
	}
	
	func start() {
		guard let session = self.session else { return }
		
		SodaCore.GCD.run(type: .async(queue: .custom(queue: self.queue))) {
			session.startRunning()
		}
	}
	
	func pause() {
		guard let session = self.session else { return }
		if !session.isRunning { return }
		
		SodaCore.GCD.run(type: .async(queue: .custom(queue: self.queue))) {
			session.stopRunning()
		}
	}
	
	func stop(_ completion: ((Void) -> Void)? = nil) {
		guard let session = self.session else { return }
		if !session.isRunning { return }
		
		SodaCore.GCD.run(type: .async(queue: .custom(queue: self.queue))) { [weak self] in
			self?.cleanup()
			completion?()
		}
	}
	
	private func generateCaptureInput(_ device: AVCaptureDevice) -> AVCaptureDeviceInput? {
		var input: AVCaptureDeviceInput?
		do {
			try input = AVCaptureDeviceInput(device: device)
		} catch let error as NSError {
			debugLog("generateCaptureInput error: \(error.localizedDescription)")
			return nil
		}
		
		return input
	}
	
	private func generateAudioInput() -> AVCaptureDeviceInput? {
		guard let device = CaptureDevice.generateAudioInput() else { return nil }
		return self.generateCaptureInput(device)
	}
	
	private func generateAudioOutput() -> AVCaptureAudioDataOutput {
		let output = AVCaptureAudioDataOutput()
		output.setSampleBufferDelegate(self, queue: self.queue)
		
		return output
	}
	
	private func cleanup() {
		if self.session?.isRunning == true {
			self.session?.stopRunning()
			self.session?.outputs.flatMap{ $0 as? AVCaptureOutput }.forEach { self.session?.removeOutput($0) }
		}
		self.session = nil
	}
}

extension CaptureAudioSession {
	
	var audioSettings: [String : Any]? {
		let settings = self.session?.audioOutputs
			.flatMap { $0.recommendedAudioSettingsForAssetWriter(withOutputFileType: self.fileType) }
			.first
		guard let _settings  = settings else { return nil }
		
		let v = _settings as NSDictionary as? [String : Any]
		
		return v
	}
}

extension CaptureAudioSession : AVCaptureVideoDataOutputSampleBufferDelegate {
	
	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
		autoreleasepool() {
			if captureOutput is AVCaptureAudioDataOutput {
				self.captureAudioBufferHandler?(sampleBuffer)
			}
		}
	}
	
	func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {}
}

extension CaptureAudioSession : AVCaptureAudioDataOutputSampleBufferDelegate {}
*/
