
//
//  MetalVideoCaptureViewExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/12/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class VideoCaptureView002ExampleVC: UIViewController {

	@IBOutlet weak var videoCaptureView: CameraCore.VideoCaptureView!
	@IBOutlet weak var recordingButton: UIButton!

	var lutLayer: LutLayer!

	var videoCaputurePropertys = CCRenderer.VideoCapture.Propertys.init(
		devicePosition: AVCaptureDevice.Position.back,
		deviceType: AVCaptureDevice.DeviceType.builtInDualCamera,
		isAudioDataOutput: true,
		required: [
			.captureSize(Settings.PresetSize.p1280x720),
			.frameRate(Settings.PresetFrameRate.fr30)
		],
		option: [
			.colorSpace(AVCaptureColorSpace.P3_D65),
			.videoHDR(true)
		]
	)


	deinit {
		self.videoCaptureView.pause()
		self.videoCaptureView.dispose()
				Debug.DeinitLog(self)
		}

	override func viewDidLoad() {
		super.viewDidLoad()

		let event: VideoCaptureViewEvent = VideoCaptureViewEvent()
		event.onRecodingUpdate = { (recordedDuration: TimeInterval) in
			print(recordedDuration)
		}
		event.onRecodingComplete = { (result: Bool, filePath: URL) in
			print(result)
			print(filePath)
			if result {
			} else {
			}
		}
		event.onPreviewUpdate = { (sampleBuffer: CMSampleBuffer) in
			//print(sampleBuffer)
		}

		self.videoCaptureView.event = event
		do {
			self.lutLayer = try LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: LutLayer.Dimension.d3)

			try self.videoCaptureView.setup(self.videoCaputurePropertys)
		} catch {
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.videoCaptureView.play()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.videoCaptureView.pause()
		self.videoCaptureView.dispose()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


	@IBAction func setFPSBtnTapAction(_ sender: UIButton) {
		let action: UIAlertController = UIAlertController(title: "FPS設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
		
		let action001: UIAlertAction = UIAlertAction(title: "24 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaputurePropertys.swap(property: .frameRate(.fr24))
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})
		
		let action002: UIAlertAction = UIAlertAction(title: "30 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaputurePropertys.swap(property: .frameRate(.fr30))
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})
		
		let action003: UIAlertAction = UIAlertAction(title: "60 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaputurePropertys.swap(property: .frameRate(.fr60))
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})
		
		let action004: UIAlertAction = UIAlertAction(title: "90 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaputurePropertys.swap(property: .frameRate(.fr90))
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})
		
		let action005: UIAlertAction = UIAlertAction(title: "120 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaputurePropertys.swap(property: .frameRate(.fr120))
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})
		
		let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
			(action: UIAlertAction!) -> Void in
		})

		action.addAction(action001)
		action.addAction(action002)
		action.addAction(action003)
		action.addAction(action004)
		action.addAction(action005)
		//action.addAction(action004)
		//action.addAction(action005)
		action.addAction(cancel)
		
		self.present(action, animated: true, completion: nil)
	}
	
	@IBAction func setPresetiFrameBtnTapAction(_ sender: UIButton) {
		let action: UIAlertController = UIAlertController(title: "撮影解像度設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
		
		let action001: UIAlertAction = UIAlertAction(title: "p960x540", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaputurePropertys.swap(property: .captureSize(.p960x540))
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})

		let action002: UIAlertAction = UIAlertAction(title: "p1280x720", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaputurePropertys.swap(property: .captureSize(.p1280x720))
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})

		let action003: UIAlertAction = UIAlertAction(title: "p1920x1080", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaputurePropertys.swap(property: .captureSize(.p1920x1080))
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})

		let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
			(action: UIAlertAction!) -> Void in
		})
		
		action.addAction(action001)
		action.addAction(action002)
		action.addAction(action003)
		action.addAction(cancel)
		
		self.present(action, animated: true, completion: nil)
	}

	@IBAction func setTouchBtnTapAction(_ sender: UIButton) {
		let action: UIAlertController = UIAlertController(title: "Touch設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
		
		let action001: UIAlertAction = UIAlertAction(title: "true", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.capture!.isTouchActive = true
		})
		
		let action002: UIAlertAction = UIAlertAction(title: "false", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.capture!.isTouchActive = false
		})
		
		let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
			(action: UIAlertAction!) -> Void in
		})
		
		action.addAction(action001)
		action.addAction(action002)
		action.addAction(cancel)
		
		self.present(action, animated: true, completion: nil)
	}

	@IBAction func setPositionBtnTapAction(_ sender: UIButton) {
		let action: UIAlertController = UIAlertController(title: "Position設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
		
		let action001: UIAlertAction = UIAlertAction(title: "front", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				self.videoCaputurePropertys.devicePosition = .front
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})
		
		let action002: UIAlertAction = UIAlertAction(title: "back", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				self.videoCaputurePropertys.devicePosition = .back
				try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
			} catch {
				print("@@@@")
			}
		})

		let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
			(action: UIAlertAction!) -> Void in
		})
		
		action.addAction(action001)
		action.addAction(action002)
		action.addAction(cancel)
		
		self.present(action, animated: true, completion: nil)
	}

	@IBAction func setFilterBtnTapAction(_ sender: UIButton) {
		let action: UIAlertController = UIAlertController(title: "Filter設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
		
		let action001: UIAlertAction = UIAlertAction(title: "true", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.renderLayers = [ self.lutLayer ]
		})
		
		let action002: UIAlertAction = UIAlertAction(title: "false", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.renderLayers = []
		})
		
		let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
			(action: UIAlertAction!) -> Void in
		})
		
		action.addAction(action001)
		action.addAction(action002)
		action.addAction(cancel)
		
		self.present(action, animated: true, completion: nil)
	}

	@IBAction func recordingTapAction(_ sender: Any) {
		if self.videoCaptureView.isRecording {
			self.videoCaptureView.recordingStop()
			self.recordingButton.setTitle("撮影開始", for: UIControl.State.normal)
		} else {
			let filePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + "recordingVideo" + NSUUID().uuidString + ".mp4"

			do {
				try self.videoCaptureView.recordingStart(
					CCRenderer.VideoCapture.CaptureWriter.Paramator.init(
						outputFilePath: URL.init(fileURLWithPath: filePath),
						presetiFrame: Settings.PresetSize.p1280x720,
						frameRate: 30,
						devicePosition: AVCaptureDevice.Position.back,
						croppingRect: CGRect.init(origin: CGPoint.init(), size: Settings.PresetSize.p1280x720.size()),
						fileType: AVFileType.mp4,
						videoCodecType: Settings.VideoCodec.hevc
						//videoCodecType: Settings.VideoCodec.h264
					)
				)
				self.recordingButton.setTitle("撮影ストップ", for: UIControl.State.normal)
			} catch {
				
			}

		}
	}
	
}
