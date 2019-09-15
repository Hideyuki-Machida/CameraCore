//
//  MetalVideoPlaybackViewExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/10/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class MetalVideoPlaybackViewExampleVC: UIViewController {
	
	//@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var playbackView: CameraCore.MetalVideoPlaybackView!
	

	private let videoCompositionProperty: VideoCompositionProperty = VideoCompositionProperty.init(
		frameRate: 30,
		presetiFrame: Settings.PresetiFrame.p1280x720,
		//presetiFrame: Settings.PresetiFrame.p1920x1080,
		renderSize: Settings.PresetiFrame.p1280x720.size(),
		//renderSize: Settings.PresetiFrame.p1920x1080.size(),
		//renderSize: CGSize.init(w: 1080, h: 1080),
		//renderSize: CGSize.init(w: 720, h: 720),
		renderScale: 1.0,
		renderType: Settings.RenderType.metal
	)

	/*
	private let videoCompositionProperty: VideoCompositionProperty = VideoCompositionProperty.init(
		frameRate: 30,
		presetiFrame: Settings.PresetiFrame.p1280x720,
		renderSize: Settings.PresetiFrame.p1280x720.size(),
		renderScale: 1.0
	)
*/
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
		let videoTimeRange001: CMTimeRange = CMTimeRange.init(start: videoAssetTrack001.timeRange.start, duration: videoAssetTrack001.timeRange.duration / 2)
		
		let videoURLAsset002: AVURLAsset = iOS_DummyAVAssets.AssetManager.VideoAsset.portrait002.urlAsset
		
		let audioURLAsset: AVURLAsset = iOS_DummyAVAssets.AssetManager.AudioAsset.svg_girl_theme_01.urlAsset
		let audioAssetTrack: AVAssetTrack = audioURLAsset.tracks(withMediaType: AVMediaType.audio).first!
		let audioTimeRange: CMTimeRange = audioAssetTrack.timeRange
		/////////////////////////////////////////////////
		
		/////////////////////////////////////////////////
		// Create: CompositionData
		let compositionVideoAsset001: CompositionVideoAsset = CompositionVideoAsset.init(
			avAsset: videoURLAsset001,
            rate: 0.5,
			//layers: [CIColorMonochromeLayer()],
			layers: [MTLCIColorMonochromeLayer()],
			//layers: [],
			atTime: CMTime.zero,
			trimTimeRange: videoTimeRange001,
			contentMode: .scaleAspectFill
		)
		let compositionVideoAsset002: CompositionVideoAsset = CompositionVideoAsset.init(
			avAsset: videoURLAsset002,
			layers: [],
			atTime: compositionVideoAsset001.atTime + compositionVideoAsset001.timeRange.duration,
			contentMode: .scaleAspectFill
		)
		let compositionVideoAsset003: CompositionVideoAsset = CompositionVideoAsset.init(
			avAsset: videoURLAsset001,
			layers: [],
			atTime: compositionVideoAsset002.atTime + compositionVideoAsset002.timeRange.duration,
			contentMode: .scaleAspectFill
		)
		let compositionAudioAsset: CompositionAudioAsset = CompositionAudioAsset.init(
			avAsset: audioURLAsset,
			atTime: audioAssetTrack.timeRange.start,
			trimTimeRange: CMTimeRange.init(start: audioTimeRange.start, duration: compositionVideoAsset001.timeRange.duration + compositionVideoAsset002.timeRange.duration + compositionVideoAsset003.timeRange.duration)
		)
		
		do {
			var compositionData = CompositionData(
				videoTracks: [
					try CompositionVideoTrack.init(assets: [
						compositionVideoAsset001,
						compositionVideoAsset002,
						compositionVideoAsset003
					])
				],
				audioTracks: [
					try CompositionAudioTrack.init(assets: [compositionAudioAsset])
				],
				property: self.videoCompositionProperty
			)
			
			/////////////////////////////////////////////////
			// Setup
			let event: Renderer.CompositionAVPlayerEvent = Renderer.CompositionAVPlayerEvent()
			event.onFrameUpdate = { [weak self] (time: Float64, _ duration: Float64) in
				//print("time: \(time), duration: \(duration)")
				//self?.timeLabel.text = "\(TimeInterval(time).mssString) / \(TimeInterval(duration).mssString)"
			}
			self.playbackView.event = event
			do {
				try compositionData.setup()
				try self.playbackView.setup(compositionData: compositionData)
				self.playbackView.play(isRepeat: true)
			} catch {
			}
			/////////////////////////////////////////////////
		} catch {
			print(error)
		}
		
		/////////////////////////////////////////////////
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
}
