//
//  UseCoreMLDeeplabV3ExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/10/06.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import Vision

@available(iOS 12.0, *)
class UseCoreMLDeeplabV3ExampleVC: UIViewController {

    @IBOutlet weak var videoCaptureView: CameraCore.VideoCaptureView!
    
    private var detectionOverlay: CALayer! = nil
	var videoCaputurePropertys = CCRenderer.VideoCapture.Propertys.init(
		devicePosition: AVCaptureDevice.Position.back,
		//deviceType: AVCaptureDevice.DeviceType.builtInDualCamera,
		isAudioDataOutput: true,
		required: [
			.captureSize(Settings.PresetSize.p960x540),
			.frameRate(Settings.PresetFrameRate.fr30)
		],
		option: []
	)

    
    deinit {
        self.videoCaptureView.pause()
        self.videoCaptureView.dispose()
    }
    
    var rootLayer: CALayer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.rootLayer = self.videoCaptureView.layer
        do {
            try self.videoCaptureView.setup(self.videoCaputurePropertys)
            let coreMLLayer = try CoreMLDeeplabV3Layer()
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
