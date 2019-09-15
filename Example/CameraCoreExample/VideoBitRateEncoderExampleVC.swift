//
//  VideoBitRateEncoderExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/08/23.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class VideoBitRateEncoderExampleVC: UIViewController {
    
    @IBOutlet weak var playbackView: CameraCore.MetalVideoPlaybackView!
    
	private let videoCompositionProperty: VideoCompositionProperty = VideoCompositionProperty.init(
		frameRate: 30,
		presetiFrame: Settings.PresetiFrame.p1280x720,
		renderSize: Settings.PresetiFrame.p1280x720.size(),
		renderScale: 1.0,
		renderType: Settings.RenderType.metal
	)

    private var compositionData: CompositionData!
    
    deinit {
        self.playbackView.pause()
        self.playbackView.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /////////////////////////////////////////////////
        // Create: AVURLAsset & CMTimeRange
        let videoURLAsset001: AVURLAsset = iOS_DummyAVAssets.AssetManager.VideoAsset.portrait002.urlAsset
        let videoAssetTrack001: AVAssetTrack = videoURLAsset001.tracks(withMediaType: AVMediaType.video).first!
        let videoTimeRange001: CMTimeRange = CMTimeRange.init(start: videoAssetTrack001.timeRange.start, duration: videoAssetTrack001.timeRange.duration / 3)
        
        let videoURLAsset002: AVURLAsset = iOS_DummyAVAssets.AssetManager.VideoAsset.portrait002.urlAsset
        let videoAssetTrack002: AVAssetTrack = videoURLAsset002.tracks(withMediaType: AVMediaType.video).first!
        let videoTimeRange002: CMTimeRange = videoAssetTrack002.timeRange
        
        let audioURLAsset: AVURLAsset = iOS_DummyAVAssets.AssetManager.AudioAsset.svg_girl_theme_01.urlAsset
        let audioAssetTrack: AVAssetTrack = audioURLAsset.tracks(withMediaType: AVMediaType.audio).first!
        let audioTimeRange: CMTimeRange = audioAssetTrack.timeRange
        /////////////////////////////////////////////////
        
        /////////////////////////////////////////////////
        // Create: CompositionData
        let compositionVideoAsset001: CompositionVideoAsset = CompositionVideoAsset.init(
            avAsset: videoURLAsset001,
            layers: [CIColorMonochromeLayer()],
            atTime: videoAssetTrack001.timeRange.start,
            trimTimeRange: videoTimeRange001,
			contentMode: .scaleAspectFill
        )
        let compositionVideoAsset002: CompositionVideoAsset = CompositionVideoAsset.init(
            avAsset: videoURLAsset002,
            layers: [],
            atTime: compositionVideoAsset001.atTime + compositionVideoAsset001.timeRange.duration,
            trimTimeRange: videoTimeRange002,
			contentMode: .scaleAspectFill
        )
        let compositionVideoAsset003: CompositionVideoAsset = CompositionVideoAsset.init(
            avAsset: videoURLAsset001,
            layers: [],
            atTime: compositionVideoAsset002.atTime + compositionVideoAsset002.timeRange.duration,
            trimTimeRange: videoTimeRange001,
			contentMode: .scaleAspectFill
        )
        let compositionAudioAsset: CompositionAudioAsset = CompositionAudioAsset.init(
            avAsset: audioURLAsset,
            atTime: audioAssetTrack.timeRange.start,
            trimTimeRange: CMTimeRange.init(start: audioTimeRange.start, duration: compositionVideoAsset001.timeRange.duration + compositionVideoAsset002.timeRange.duration + compositionVideoAsset003.timeRange.duration)
        )
        
        do {
            self.compositionData = CompositionData(
				videoTracks: [
                	try CompositionVideoTrack.init(assets: [compositionVideoAsset001, compositionVideoAsset002, compositionVideoAsset003])
				],
				audioTracks: [
					try CompositionAudioTrack.init(assets: [compositionAudioAsset])
				],
				property: self.videoCompositionProperty)
        } catch {
            print(error)
        }
        /////////////////////////////////////////////////

        
        /////////////////////////////////////////////////
        // Setup
        do {
            try self.compositionData.setup()
            try self.playbackView.setup(compositionData: self.compositionData)
            self.playbackView.play(isRepeat: true)
        } catch {
        }
        /////////////////////////////////////////////////
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
					print(status)
					print(exportPath)
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

extension VideoBitRateEncoderExampleVC {
    enum SegueId: String {
        case openProgressView = "openProgressView"
    }
}
