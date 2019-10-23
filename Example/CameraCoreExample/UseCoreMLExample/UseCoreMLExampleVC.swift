//
//  UseCoreMLExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/09/23.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore

class UseCoreMLExampleVC: UIViewController {

	@IBOutlet weak var videoCaptureView: CameraCore.VideoCaptureView!
    @IBOutlet weak var classificationLabel: UILabel!
	
	var videoCaputurePropertys = CCRenderer.VideoCapture.Propertys.init(
		devicePosition: AVCaptureDevice.Position.back,
		isAudioDataOutput: true,
		required: [
			.captureSize(Settings.PresetSize.p1280x720),
			.frameRate(Settings.PresetFrameRate.fr30)
		],
		option: []
	)

	
	deinit {
		self.videoCaptureView.pause()
		self.videoCaptureView.dispose()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		do {
			try self.videoCaptureView.setup(self.videoCaputurePropertys)
			let coreMLLayer = try CoreMLMobileNetV2Layer()
			coreMLLayer.onProcessClassifications = { [weak self] (descriptions: [String]) in
				DispatchQueue.main.async { [weak self] in
					self?.classificationLabel.text = descriptions.joined(separator: "\n")
				}
			}
			self.videoCaptureView.renderLayers = [ coreMLLayer ]
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
}
