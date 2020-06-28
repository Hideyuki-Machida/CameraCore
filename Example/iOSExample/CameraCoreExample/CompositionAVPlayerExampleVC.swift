//
//  CompositionAVPlayerExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class CompositionAVPlayerExampleVC: UIViewController {
    
    @IBOutlet weak var timeLabel: UILabel!
    private var compositionPlayer: CameraCore.Renderer.CompositionAVPlayer = CameraCore.Renderer.CompositionAVPlayer()
    
	private let videoCompositionProperty: VideoCompositionProperty = VideoCompositionProperty.init(
		frameRate: 60,
		presetiFrame: Settings.PresetiFrame.p1920x1080,
		renderSize: Settings.PresetiFrame.p1920x1080.size(),
		renderScale: 1.0,
		renderType: Settings.RenderType.openGL
	)

    private var compositionData: CompositionData!
    private var compositionAssetId: CompositionAudioAssetId!
    
    deinit {
        self.compositionPlayer.pause()
        self.compositionPlayer.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /////////////////////////////////////////////////
        // Create: AVURLAsset
        let audioURLAsset: AVURLAsset = iOS_DummyAVAssets.AssetManager.AudioAsset.svg_girl_theme_01.urlAsset
        /////////////////////////////////////////////////
        
        /////////////////////////////////////////////////
        // Create: CompositionData
        let compositionAudioAsset: CompositionAudioAsset = CompositionAudioAsset.init(
            avAsset: audioURLAsset,
            atTime: CMTime.init(value: 1, timescale: 44100)
        )

        self.compositionAssetId = compositionAudioAsset.id

        do {
			self.compositionData = CompositionData(
				videoTracks: [],
				audioTracks: [
					try CompositionAudioTrack.init(assets: [compositionAudioAsset])
				], property: videoCompositionProperty)
		} catch {
		}
        /////////////////////////////////////////////////
        
        /////////////////////////////////////////////////
        // Setup
        let event = Renderer.CompositionAVPlayerEvent()
        event.onFrameUpdate = { [weak self] (time: Float64, _ duration: Float64) in
            print("time: \(time), duration: \(duration)")
            self?.timeLabel.text = "\(TimeInterval(time).mssString) / \(TimeInterval(duration).mssString)"
        }
        self.compositionPlayer.event = event
        do {
            try self.compositionData.setup()
            try self.compositionPlayer.setup(compositionData: self.compositionData)
            self.compositionPlayer.play(isRepeat: true)
        } catch {
        }
        /////////////////////////////////////////////////
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func tap001(_ sender: Any) {
        do {
			var compositionAsset: CompositionAudioAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			let audioTimeRange: CMTimeRange = compositionAsset.originalTimeRange
			compositionAsset.volume = 0.3
			compositionAsset.set(trimTimeRange: audioTimeRange)
			compositionAsset.mute = false

			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.compositionPlayer.updateAll(compositionData: self.compositionData)
            self.compositionPlayer.replay(isRepeat: true)
        } catch {
        }
    }
    
    @IBAction func tap002(_ sender: Any) {
        do {
			var compositionAsset: CompositionAudioAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			let audioTimeRange: CMTimeRange = compositionAsset.originalTimeRange
			compositionAsset.volume = 1.0
			compositionAsset.set(trimTimeRange: CMTimeRange.init(start: audioTimeRange.start + (audioTimeRange.duration / 2), duration: audioTimeRange.duration))
			compositionAsset.mute = false

			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.compositionPlayer.updateAll(compositionData: self.compositionData)
            self.compositionPlayer.replay(isRepeat: true)
        } catch {
        }
    }

    @IBAction func tap003(_ sender: Any) {
        do {
			var compositionAsset: CompositionAudioAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			let audioTimeRange: CMTimeRange = compositionAsset.originalTimeRange
			compositionAsset.volume = 1.0
			compositionAsset.set(trimTimeRange: audioTimeRange)
			compositionAsset.mute = true

			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.compositionPlayer.updateAll(compositionData: self.compositionData)
            self.compositionPlayer.replay(isRepeat: true)
        } catch {
        }
    }

}
