//
//  VideoCaptureView002ExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/10/15.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class VideoCaptureView002ExampleVC: UIViewController {
		
	@IBOutlet weak var videoCaptureView: CameraCore.VideoCaptureView!
		
	var videoCaputurePropertys = CCRenderer.VideoCapture.Propertys.init(
		devicePosition: AVCaptureDevice.Position.back,
		//deviceType: AVCaptureDevice.DeviceType.builtInDualCamera,
		isAudioDataOutput: true,
		required: [
			.captureSize(Settings.PresetSize.p1920x1080 ),
			.frameRate(Settings.PresetFrameRate.fr30)
		],
		option: []
	)

		
	deinit {
		self.videoCaptureView.pause()
		self.videoCaptureView.dispose()
		Debug.DeinitLog(self)
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
		event.onPreviewUpdate = { [weak self] (sampleBuffer: CMSampleBuffer) in
			//print(sampleBuffer)
		}

		self.videoCaptureView.event = event
		do {
			//self.lutLayer = try LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: LutLayer.Dimension.d3)
			
			try self.videoCaptureView.setup(self.videoCaputurePropertys)
			
			self.videoCaptureView.renderLayers = [
				//FaceLayer()
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
	
}
