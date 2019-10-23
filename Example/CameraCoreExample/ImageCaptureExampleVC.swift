//
//  ImageCaptureExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2019/03/07.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MetalCanvas
import CameraCore
import iOS_DummyAVAssets

class ImageCaptureExampleVC: UIViewController {
	
	private let videoCompositionProperty: VideoCompositionProperty = VideoCompositionProperty.init(
		frameRate: 60,
		presetiFrame: Settings.PresetiFrame.p1920x1080,
		renderSize: Settings.PresetiFrame.p1920x1080.size(),
		renderScale: 1.0,
		renderType: Settings.RenderType.metal
	)

	@IBOutlet weak var imageView: UIImageView!

	override func viewDidLoad() {
		super.viewDidLoad()
		let videoURLAsset: AVURLAsset = iOS_DummyAVAssets.AssetManager.VideoAsset.portrait002.urlAsset
		let videoAssetTrack: AVAssetTrack = videoURLAsset.tracks(withMediaType: AVMediaType.video).first!
		let compositionVideoAsset: CompositionVideoAsset = CompositionVideoAsset.init(
			avAsset: videoURLAsset,
			rate: 1.0,
			layers: [MTLCIColorMonochromeLayer()],
			atTime: CMTime.zero,
			trimTimeRange: videoAssetTrack.timeRange,
			contentMode: .scaleAspectFill
		)

		/*
		do {
			try iOS_AVModule.ImageCapture.capture(
				url: videoURLAsset.url,
				size: Settings.PresetiFrame.p1280x720.size(),
				compositionAsset: compositionVideoAsset,
				at: CMTime.zero
			)
			{ (image: CGImage?) in
				DispatchQueue.main.async { [weak self] in
					self?.imageView.image = UIImage.init(cgImage: image!)
				}
			}

		} catch {
			
		}
*/
		do {
			var compositionData: CompositionData = CompositionData(
				videoTracks: [
					try CompositionVideoTrack.init(assets: [compositionVideoAsset])
				],
				audioTracks: [],
				property: self.videoCompositionProperty)
			try compositionData.setup()
			let image: CGImage? = try CameraCore.ImageCapture.capture(size: Settings.PresetiFrame.p1280x720.size(), compositionData: compositionData, at: CMTime.zero)
			self.imageView.image = UIImage.init(cgImage: image!)
			print(image)
		} catch {
			print(8888)
		}

	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
}
