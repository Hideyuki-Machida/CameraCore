//
//  ViewController.swift
//  CameraCore_Example
//
//  Created by 町田 秀行 on 2018/08/07.
//  Copyright © 2018年 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import CCamUIComponent

class RecordingViewController: UIViewController {

	@IBOutlet weak var videoCaptureView: CameraCore.MetalVideoCaptureView!
	@IBOutlet weak var recordingButton: VideoRecordingButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.recordingButton.viewMode = .normal
		/*
		self.recordingButton.onTap = { [weak self] (viewMode: VideoRecordingButton.ViewMode) in
			switch viewMode {
			case .normal:
				self?.recordingButton.viewMode = .recording
				//self?.startTimer()
			case .recording, .count:
				self?.recordingButton.viewMode = .normal
			}
		}
		*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

