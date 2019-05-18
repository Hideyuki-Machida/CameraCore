//
//  RenderLayerExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class RenderLayerExampleVC: UIViewController {
    
    @IBOutlet weak var playbackView: CameraCore.MetalVideoPlaybackView!

	private let videoCompositionProperty: VideoCompositionProperty = VideoCompositionProperty.init(
		frameRate: 30,
		presetiFrame: Settings.PresetiFrame.p1920x1080,
		renderSize: Settings.PresetiFrame.p1920x1080.size(),
		renderScale: 1.0,
		renderType: Settings.RenderType.metal
	)

    private var compositionData: CompositionData!
    private var compositionAssetId: CompositionVideoAssetId!
	
	private var effectGroupLayer: GroupLayer!
	
	
    deinit {
        self.playbackView.pause()
        self.playbackView.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.effectGroupLayer = GroupLayer.init(
			layers: [],
			alpha: 1.0,
			blendMode: Blendmode.alpha
		)
		
        /////////////////////////////////////////////////
        // Create: AVURLAsset & CMTimeRange
        let videoURLAsset001: AVURLAsset = iOS_DummyAVAssets.AssetManager.VideoAsset.portrait002.urlAsset
        let videoAssetTrack001: AVAssetTrack = videoURLAsset001.tracks(withMediaType: AVMediaType.video).first!
        let videoTimeRange001: CMTimeRange = videoAssetTrack001.timeRange
        /////////////////////////////////////////////////
        
        /////////////////////////////////////////////////
        // Create: CompositionData
        let compositionVideoAsset001: CompositionVideoAsset = CompositionVideoAsset.init(
            avAsset: videoURLAsset001,
            layers: [self.effectGroupLayer],
            atTime: videoTimeRange001.start,
			contentMode: .scaleAspectFill
        )
        self.compositionAssetId = compositionVideoAsset001.id
        
        do {
            self.compositionData = CompositionData(
				videoTracks: [
					try CompositionVideoTrack.init(assets: [compositionVideoAsset001])
                ],
				audioTracks: [],
				property: self.videoCompositionProperty)
        } catch {
            print(error)
        }
        /////////////////////////////////////////////////

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    

    /// ノーマルに戻す
    @IBAction func tapNoramlButton(_ sender: Any) {
        do {
			var compositionAsset: CompositionVideoAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			compositionAsset.layers = []
			
			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.playbackView.updateRenderLayer(compositionData: self.compositionData)
        } catch {
        }
    }

    /// Lutを適用
    @IBAction func tapLutButton(_ sender: Any) {
		self.effectGroupLayer?.layers = [
			LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.dreamy.url, dimension: 64)
		]
		self.effectGroupLayer?.blendMode = Blendmode.overlay
    }

    /// シーケンスイメージをかぶせる
    @IBAction func tapSequenceImageButton(_ sender: Any) {
		self.effectGroupLayer?.layers = [
			SequenceImageLayer.init(imagePaths: iOS_DummyAVAssets.AssetManager.SequenceImage.glitter_filter.urls, blendMode: Blendmode.screen, updateFrameRate: 24)
		]
		self.effectGroupLayer?.blendMode = Blendmode.alpha
    }

    /// トランスフォームを適用
    @IBAction func tapTransformButton(_ sender: Any) {
		do {
			var compositionAsset: CompositionVideoAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			
			compositionAsset.layers = [
				TransformLayer.init(transform: CGAffineTransform.identity.rotated(by: 1.0).translatedBy(x: 500, y: -500), backgroundColor: UIColor.gray)
			]

			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.playbackView.updateRenderLayer(compositionData: self.compositionData)
        } catch {
        }
    }

    ///
    @IBAction func tapImageButton(_ sender: Any) {
        do {
			var compositionAsset: CompositionVideoAsset = try self.compositionData.get(assetId: self.compositionAssetId) as! CompositionVideoAsset
			
			compositionAsset.layers = [
				TransformLayer.init(transform: CGAffineTransform.identity.rotated(by: 1.0).translatedBy(x: 500, y: -500), backgroundColor: UIColor.gray)
			]

			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.playbackView.updateRenderLayer(compositionData: self.compositionData)
        } catch {
        }
    }

    /// シーケンスイメージの上にLutを適用
    @IBAction func tapLutAndSequenceImageButton(_ sender: Any) {
		self.effectGroupLayer?.layers = [
			SequenceImageLayer.init(imagePaths: iOS_DummyAVAssets.AssetManager.SequenceImage.glitter_filter.urls, blendMode: Blendmode.screen, updateFrameRate: 24),
			LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.dreamy.url, dimension: 64)
		]
		self.effectGroupLayer?.blendMode = Blendmode.overlay
    }

	
	@IBAction func updateSlider(_ sender: UISlider) {
		self.effectGroupLayer?.alpha = sender.value
		/*
		//DispatchQueue.global().async {
			do {
				var compositionAsset: CompositionVideoAsset = try self.compositionData.get(assetId: self.compositionAssetId) as! CompositionVideoAsset
		
				compositionAsset.layers = [
					GroupLayer.init(
						layers: [
							LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.dreamy.url, dimension: 64)
						],
						alpha: sender.value,
						blendMode: Blendmode.overlay
					)
				]

				try self.compositionData.updatet(asset: compositionAsset)
				try self.compositionData.setup()
				try self.playbackView.updateRenderLayer(compositionData: self.compositionData)
			} catch {
			}

		//}
*/
	}
	
}

extension RenderLayerExampleVC {
    private func getCompositionData(layers: [RenderLayerProtocol]) -> CompositionData {
        return compositionData
    }
}
