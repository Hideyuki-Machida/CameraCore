//
//  VideoCapture.swift
//  VideoPlayer
//
//  Created by machidahideyuki on 2017/04/21.
//  Copyright © 2017年 com.cchannel. All rights reserved.
//

import UIKit
import AVFoundation

extension Renderer.VideoCapture {
	public final class VideoCapture: NSObject {
		
		internal enum ErrorType: Error {
			case setupError
		}
		
		let captureOutput: VideoCaptureOutput = VideoCaptureOutput()
		let deviceFormat: DeviceFormat = DeviceFormat()
		
		var captureSession: AVCaptureSession?
		var videoDevice: AVCaptureDevice?
		var frameRate: Int32 = 30
		var presetiFrame: Settings.PresetiFrame = Settings.PresetiFrame.p1280x720

		public var onUpdate: ((_ sampleBuffer: CMSampleBuffer)->Void)? {
			get {
				return self.captureOutput.onUpdate
			}
			set {
				self.captureOutput.onUpdate = newValue
			}
		}


		let sessionQueue: DispatchQueue = DispatchQueue(label: "com.cchannel.CCamera.VideoCapture.Queue", attributes: .concurrent)
		
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
		
		public init(frameRate: Int32, presetiFrame: Settings.PresetiFrame, position: AVCaptureDevice.Position, isDepth: Bool = false) throws {
			super.init()
			
			self.frameRate = frameRate
			self.presetiFrame = presetiFrame
			
			// AVCaptureSessionを生成
			self.captureSession?.stopRunning()
			self.captureSession = AVCaptureSession()
			self.captureSession?.beginConfiguration()
			self.captureSession?.sessionPreset = AVCaptureSession.Preset(rawValue: presetiFrame.aVCaptureSessionPreset())
			
			do {
				// AVCaptureDeviceを生成
				let videoDevice: AVCaptureDevice = try self._getAVCaptureDevice(position: position)
				self.videoDevice = videoDevice
				// AVCaptureDeviceInputを生成
				let videoCaptureDeviceInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
				
				// AVCaptureVideoDataOutputを登録
				self.captureSession?.addInput(videoCaptureDeviceInput)
				
				// deviceをロックして設定
				try videoDevice.lockForConfiguration()
				
				// フォーカスモード設定
				if videoDevice.isSmoothAutoFocusSupported {
					videoDevice.isSmoothAutoFocusEnabled = true
				}
				if videoDevice.isAutoFocusRangeRestrictionSupported {
					videoDevice.focusMode = .continuousAutoFocus
				}
				

				let captureDeviceFormat: (deviceFormat: AVCaptureDevice.Format?, depthDataFormat: AVCaptureDevice.Format?, filterColorSpace: AVCaptureColorSpace?, minFrameRate: Int32, maxFrameRate: Int32) = self.deviceFormat.get(videoDevice: videoDevice, frameRate: frameRate, presetiFrame: self.presetiFrame)
				guard let format: AVCaptureDevice.Format = captureDeviceFormat.deviceFormat else { throw ErrorType.setupError }
				
				videoDevice.activeFormat = format
				if let filterColorSpace: AVCaptureColorSpace = captureDeviceFormat.filterColorSpace {
					videoDevice.activeColorSpace = filterColorSpace
				}
				videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
				videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
				
				videoDevice.unlockForConfiguration()
				
				self.captureOutput.captureSession = self.captureSession
				try self.captureOutput.set(position: position)
				
				self._updateVideoConnection(videoDataOutput: self.captureOutput.videoDataOutput!, position: position)
				
				self.captureSession?.commitConfiguration()
				
			} catch {
				throw ErrorType.setupError
			}
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


extension Renderer.VideoCapture.VideoCapture {
	public func addAudioDataOutput() throws {
		//try self.captureOutput.addAudioDataOutput()
	}

	public func removeAudioDataOutput() throws {
		//try self.captureOutput.removeAudioDataOutput()
	}
}

extension Renderer.VideoCapture.VideoCapture {

    fileprivate func _updateVideoConnection(videoDataOutput: AVCaptureVideoDataOutput, position: AVCaptureDevice.Position) {
		for connection: Any in videoDataOutput.connections {
			guard let connection: AVCaptureConnection = connection as? AVCaptureConnection else { continue }
			for port: Any in connection.inputPorts {
                guard let port: AVCaptureInput.Port = port as? AVCaptureInput.Port else { continue }
				if port.mediaType == AVMediaType.video {
					if connection.isVideoOrientationSupported {
						connection.videoOrientation = .portrait
						if position == .front {
							connection.isVideoMirrored = true
						} else {
							connection.isVideoMirrored = false
						}
					}
				}
			}
		}
	}

	/// AVCaptureDeviceを生成
    fileprivate func _getAVCaptureDevice(position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
		switch position {
		case .front:
			if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position) {
				Debug.ActionLog("device builtInWideAngleCamera: \(device)")
				return device
			}
		case .back:
			if #available(iOS 10.2, *) {
				if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: position) {
					Debug.ActionLog("device builtInDuoCamera: \(device)")
					return device
				}
			} else {
				if let device = AVCaptureDevice.default(.builtInDuoCamera, for: AVMediaType.video, position: position) {
					Debug.ActionLog("device builtInDuoCamera: \(device)")
					return device
				}
			}
		case .unspecified:
        	throw VideoSettingError.videoDataOutput
		@unknown default: break

		}

		if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position) {
			Debug.ActionLog("device builtInWideAngleCamera: \(device)")
			return device
		}
        throw VideoSettingError.videoDataOutput
	}
	
}

extension Renderer.VideoCapture.VideoCapture {

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


extension Renderer.VideoCapture.VideoCapture {
    
    // ビデオHDR設定
    public var isVideoHDREnabled: Bool {
        get {
            guard let device = self.videoDevice else { return false }
            return device.isVideoHDREnabled
        }
    }

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
    
    public var position: AVCaptureDevice.Position? {
        return self.videoDevice?.position
    }

    public func setPresetiFrame(presetiFrame: Settings.PresetiFrame) throws {
        self.captureSession?.sessionPreset = AVCaptureSession.Preset(rawValue: presetiFrame.aVCaptureSessionPreset())
    }
    
    public func setPosition(_ position: AVCaptureDevice.Position) throws {
        guard let session: AVCaptureSession = self.captureSession else { throw VideoSettingError.captureSetting }
        guard let input: AVCaptureDeviceInput = self.currentVideoInput else { throw VideoSettingError.captureSetting }
        session.beginConfiguration()
        session.removeInput(input)
        
        do {
			// AVCaptureDeviceを生成
            let videoDevice: AVCaptureDevice = try self._getAVCaptureDevice(position: position)
            self.videoDevice = videoDevice

			let captureDeviceFormat: (deviceFormat: AVCaptureDevice.Format?, depthDataFormat: AVCaptureDevice.Format?, filterColorSpace: AVCaptureColorSpace?, minFrameRate: Int32, maxFrameRate: Int32) = self.deviceFormat.get(videoDevice: videoDevice, frameRate: frameRate, presetiFrame: self.presetiFrame)
			guard let format: AVCaptureDevice.Format = captureDeviceFormat.deviceFormat else { return }

			// AVCaptureDeviceInputを生成
            let videoCaptureDeviceInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            // AVCaptureVideoDataOutputを登録
            if session.canAddInput(videoCaptureDeviceInput) {
                session.addInput(videoCaptureDeviceInput)
            }
            
            // deviceをロックして設定
            try videoDevice.lockForConfiguration()
            
            // フォーカスモード設定
            if videoDevice.isAutoFocusRangeRestrictionSupported == true {
                videoDevice.isSmoothAutoFocusEnabled = true
            }
            if videoDevice.isAutoFocusRangeRestrictionSupported {
                videoDevice.focusMode = .continuousAutoFocus
            }
			
			videoDevice.activeFormat = format
			/*
			if let depthDataFormat: AVCaptureDevice.Format = captureDeviceFormat.depthDataFormat {
				videoDevice.activeDepthDataFormat = depthDataFormat
			}
*/
			if let filterColorSpace: AVCaptureColorSpace = captureDeviceFormat.filterColorSpace {
				videoDevice.activeColorSpace = filterColorSpace
			}
			videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
			videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
            
            videoDevice.unlockForConfiguration()
        } catch {
            session.commitConfiguration()
            throw VideoSettingError.captureSetting
        }
        
        let videoDataOutputs: [Any] = session.outputs
        let videoDataOutput: AVCaptureVideoDataOutput = videoDataOutputs.compactMap { $0 as? AVCaptureVideoDataOutput }.first!
        self._updateVideoConnection(videoDataOutput: videoDataOutput, position: position)
        session.commitConfiguration()
    }
    
    public func switchFPS(frameRate: Int32) {
        self._switchFPS(frameRate: frameRate)
    }
}


extension Renderer.VideoCapture.VideoCapture {
    private func _switchFPS(frameRate: Int32) {
        guard let videoDevice: AVCaptureDevice = self.videoDevice else { return }
        self.sessionQueue.async { [weak self] in
            guard let `self` = self else { return }
            do {
                let captureDeviceFormat: (deviceFormat: AVCaptureDevice.Format?, depthDataFormat: AVCaptureDevice.Format?, filterColorSpace: AVCaptureColorSpace?, minFrameRate: Int32, maxFrameRate: Int32) = self.deviceFormat.get(videoDevice: videoDevice, frameRate: frameRate, presetiFrame: self.presetiFrame)
                guard let format: AVCaptureDevice.Format = captureDeviceFormat.deviceFormat else { return }
                // deviceをロックして設定
                try videoDevice.lockForConfiguration()
                
                // フォーカスモード設定
                if videoDevice.isAutoFocusRangeRestrictionSupported == true {
                    videoDevice.isSmoothAutoFocusEnabled = true
                }
                if videoDevice.isAutoFocusRangeRestrictionSupported {
                    videoDevice.focusMode = .continuousAutoFocus
                }

                videoDevice.activeFormat = format
				/*
				if let depthDataFormat: AVCaptureDevice.Format = captureDeviceFormat.depthDataFormat {
					videoDevice.activeDepthDataFormat = depthDataFormat
				}
				*/	
				if let filterColorSpace: AVCaptureColorSpace = captureDeviceFormat.filterColorSpace {
					videoDevice.activeColorSpace = filterColorSpace
				}
				videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
				videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: frameRate)
                
                videoDevice.unlockForConfiguration()
				self.captureSession?.commitConfiguration()
				//try self.captureOutput.set()
            } catch {
            }
        }
    }
}
