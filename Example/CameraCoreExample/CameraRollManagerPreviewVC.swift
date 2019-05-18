//
//  CameraRollManagerOverViewVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/08/27.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class CameraRollManagerPreviewVC: UIViewController {

    public var compositionData: CompositionDataProtocol!
    @IBOutlet weak var playbackView: CameraCore.VideoPlaybackView!
    
    var onComplete: (()->Void)?
    
    deinit {
        self.playbackView.pause()
        self.playbackView.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /////////////////////////////////////////////////
        // Setup
        let event = Renderer.CompositionAVPlayerEvent()
        self.playbackView.event = event
        do {
            try self.compositionData.setup()
            try self.playbackView.setup(compositionData: self.compositionData)
            self.playbackView.play(isRepeat: true)
        } catch {

        }
        /////////////////////////////////////////////////
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.playbackView.pause()
        self.playbackView.dispose()
    }
    
    @IBAction func closeButtonTapAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func saveButtonTapAction(_ sender: Any) {
        self.performSegue(withIdentifier: SegueId.openProgressView.rawValue, sender: nil)
        let filePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + "encodeVideo" + NSUUID().uuidString + ".mp4"
        let url: URL = URL.init(fileURLWithPath: filePath)
        do {
            try self.compositionData.setup()
			let videoEncorderProperty: VideoEncorderProperty = VideoEncorderProperty.init(
				exportPath: url,
				compositionData: self.compositionData,
				frameRate: 30,
				presetiFrame: Settings.PresetiFrame.p1920x1080,
				renderSize: Settings.PresetiFrame.p1920x1080.size(),
				codec: Settings.VideoCodec.hevc
			)
			CameraCore.VideoBitRateEncoder.onEvent = { [weak self] (event) in
				switch event {
				case .complete(let status, let exportPath):
					if status == true, let exportPath: URL = exportPath {
						CameraRollManager.save(videoFileURL: exportPath, type: .copy, completion: { [weak self] (result) in
							do {
								let a = try result.get()
								print("カメラロールURL: \(a)")
								self?.onComplete?()
							} catch {
								
							}
						})
					}
					self?.dismiss(animated: true, completion: nil)
				case .progress(let progress):
					guard let vc: ProgressViewVC = self?.presentedViewController as? ProgressViewVC else { return }
					vc.progressLabel.text = String(Int(floor(progress * 100))) + "%"
				case .memoryWorning: break
				}
			}

			try VideoBitRateEncoder.setup(property: videoEncorderProperty)
            VideoBitRateEncoder.start()
        } catch {
            self.dismiss(animated: true, completion: nil)
        }
    }
}


//MARK: - Segue

extension CameraRollManagerPreviewVC {
    enum SegueId: String {
        case openProgressView = "openProgressView"
    }
}
