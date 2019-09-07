
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

class MetalVideoCaptureViewExampleVC: UIViewController {
	
	@IBOutlet weak var videoCaptureView: CameraCore.MetalVideoCaptureView!
	@IBOutlet weak var recordingButton: UIButton!
	
	deinit {
		self.videoCaptureView.pause()
		self.videoCaptureView.dispose()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let event: VideoCaptureViewEvent = VideoCaptureViewEvent()
		event.onRecodingUpdate = { [weak self] (recordedDuration: TimeInterval) in
			print(recordedDuration)
		}
		event.onRecodingComplete = { [weak self] (result: Bool, filePath: URL) in
			print(result)
			print(filePath)
			if result {
			} else {
			}
		}
		self.videoCaptureView.event = event
		do {
			try self.videoCaptureView.setup(
				frameRate: 30,
				//presetiFrame: Settings.PresetiFrame.p1280x720,
				presetiFrame: Settings.PresetiFrame.p1920x1080,
				//position: AVCaptureDevice.Position.front
				position: AVCaptureDevice.Position.back
			)
			
			self.videoCaptureView.renderLayers = [
				//DepthMapLayer(),
				//iOSHumanSegmentationLayer(),
				//Depth_FaceMetaData_BlendLayer()
				//iOSFaceDetectionLayer(),
				//FaceMetaDataLayer(),
			]

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
			self.videoCaptureView.capture!.switchFPS(frameRate: 24)
		})
		
		let action002: UIAlertAction = UIAlertAction(title: "30 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.capture!.switchFPS(frameRate: 30)
		})
		
		let action003: UIAlertAction = UIAlertAction(title: "60 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.capture!.switchFPS(frameRate: 60)
		})
		
		let action004: UIAlertAction = UIAlertAction(title: "90 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.capture!.switchFPS(frameRate: 90)
		})
		
		let action005: UIAlertAction = UIAlertAction(title: "120 FPS", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.capture!.switchFPS(frameRate: 120)
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
				try self.videoCaptureView.capture!.setPresetiFrame(presetiFrame: .p960x540)
			} catch {
				print("@@@@")
			}
		})
		
		let action002: UIAlertAction = UIAlertAction(title: "p1280x720", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaptureView.capture!.setPresetiFrame(presetiFrame: .p1280x720)
			} catch {
				print("@@@@")
			}
		})
		
		let action003: UIAlertAction = UIAlertAction(title: "p1920x1080", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaptureView.capture!.setPresetiFrame(presetiFrame: .p1920x1080)
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
				try self.videoCaptureView.capture?.setPosition(.front)
			} catch {
				
			}
		})
		
		let action002: UIAlertAction = UIAlertAction(title: "back", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			do {
				try self.videoCaptureView.capture?.setPosition(.back)
			} catch {
				
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
	
	@IBAction func setDepthDataBtnTapAction(_ sender: UIButton) {
		let action: UIAlertController = UIAlertController(title: "DepthData設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
		
		let action001: UIAlertAction = UIAlertAction(title: "DepthMap", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in

		})

		let action002: UIAlertAction = UIAlertAction(title: "DepthMap Normalize", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			
			/*
			self.videoCaptureView.renderLayers = [
				DepthMapLayer(),
				Depth_FaceMetaData_BlendLayer()
			]
			*/
		})

		let action003: UIAlertAction = UIAlertAction(title: "DepthMap Thresholding（顔をもとに２値化）", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in

			/*
			self.videoCaptureView.renderLayers = [
				iOSHumanSegmentationLayer(),
				Depth_FaceMetaData_BlendLayer()
			]
*/
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
	
	@IBAction func setFilterBtnTapAction(_ sender: UIButton) {
		let action: UIAlertController = UIAlertController(title: "Filter設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
		
		let action001: UIAlertAction = UIAlertAction(title: "true", style: UIAlertAction.Style.default, handler:{
			(action: UIAlertAction!) -> Void in
			self.videoCaptureView.renderLayers = [LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: 64)]
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
					Renderer.VideoCapture.CaptureWriter.Paramator.init(
						outputFilePath: URL.init(fileURLWithPath: filePath),
						presetiFrame: Settings.PresetiFrame.p1920x1080,
						frameRate: 30,
						devicePosition: AVCaptureDevice.Position.back,
						croppingRect: CGRect.init(origin: CGPoint.init(), size: Settings.PresetiFrame.p1920x1080.size()),
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
