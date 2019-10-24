//
//  VideoCapture.swift
//  VideoPlayer
//
//  Created by machidahideyuki on 2017/04/21.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation

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
			self.propertys = propertys
			
			// AVCaptureSessionを生成
			self.captureSession?.stopRunning()
			self.captureSession?.beginConfiguration()

			if let _ : Bool = self.captureSession?.canSetSessionPreset(propertys.info.presetSize.aVCaptureSessionPreset()) {
				self.captureSession?.sessionPreset = propertys.info.presetSize.aVCaptureSessionPreset()
			}

			try self.propertys.setup()
			
			// AVCaptureDeviceを生成
			guard let videoDevice: AVCaptureDevice = self.propertys.info.device else { throw CCRenderer.VideoCapture.ErrorType.setupError }
			guard let format: AVCaptureDevice.Format = self.propertys.info.deviceFormat else { throw CCRenderer.VideoCapture.ErrorType.setupError }
			let frameRate: Int32 = self.propertys.info.frameRate

			// AVCaptureDeviceInputを生成
			let videoCaptureDeviceInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
			
			// AVCaptureVideoDataOutputを登録
			_ = self.captureSession?.inputs.map({ self.captureSession?.removeInput($0) })
			self.captureSession?.addInput(videoCaptureDeviceInput)
			// deviceをロックして設定
			try videoDevice.lockForConfiguration()
			videoDevice.activeFormat = format
			
			// フォーカスモード設定
			if videoDevice.isSmoothAutoFocusSupported {
				videoDevice.isSmoothAutoFocusEnabled = self.propertys.info.isSmoothAutoFocusEnabled
			}

			videoDevice.activeColorSpace = self.propertys.info.colorSpace
			videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
			videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: frameRate)

			videoDevice.unlockForConfiguration()
			
			self.captureOutput.captureSession = self.captureSession
			try self.captureOutput.set(propertys: propertys)
			
			self.captureSession?.commitConfiguration()
			
			self.videoDevice = videoDevice
		}

		deinit {
			Debug.DeinitLog(self)
		}
		
		public func play() {
			self.sessionQueue.async { [weak self] in
				self?.captureSession?.startRunning()
			}
		}
		
		public func stop() {
			self.sessionQueue.async { [weak self] in
				self?.captureSession?.stopRunning()
			}
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
	public func addAudioDataOutput() throws {
		//try self.captureOutput.addAudioDataOutput()
	}

	public func removeAudioDataOutput() throws {
		//try self.captureOutput.removeAudioDataOutput()
	}
}

extension CCRenderer.VideoCapture.VideoCapture {

	/// フォーカスポイントを設定
	internal func focus(atPoint: CGPoint) -> Bool {
		guard let device: AVCaptureDevice = self.videoDevice else { return false  }
		if !device.isFocusModeSupported(.autoFocus) { return false }
		
		do {
			try device.lockForConfiguration()
		} catch {
			return false
		}
		
		device.focusPointOfInterest = atPoint
		device.focusMode = .autoFocus
		
		device.unlockForConfiguration()
		return true
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
