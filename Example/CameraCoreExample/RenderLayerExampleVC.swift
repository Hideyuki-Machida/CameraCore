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
	@IBOutlet weak var lutIntensitySlider: UISlider!
	
	private let videoCompositionProperty: VideoCompositionProperty = VideoCompositionProperty.init(
		frameRate: 30,
		//presetiFrame: Settings.PresetiFrame.p1920x1080,
		presetiFrame: Settings.PresetiFrame.p1280x720,
		renderSize: Settings.PresetiFrame.p1280x720.size(),
		renderScale: 1.0,
		renderType: Settings.RenderType.metal
	)

    private var compositionData: CompositionData!
    private var compositionAssetId: CompositionVideoAssetId!

	private var lutLayer: LutLayer!
	private var sequenceImageLayer: SequenceImageLayer!
	private var transformLayer: TransformLayer!
	
	
    deinit {
        self.playbackView.pause()
        self.playbackView.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        do {
			self.lutLayer = try LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: 64)
			self.lutLayer.intensity = self.lutIntensitySlider.value
			
			self.sequenceImageLayer = SequenceImageLayer.init(imagePaths: iOS_DummyAVAssets.AssetManager.SequenceImage.sample001.urls, blendMode: Blendmode.alpha, updateFrameRate: 30)
			
			self.transformLayer = TransformLayer.init(transform: CGAffineTransform.identity.rotated(by: 1.0).translatedBy(x: 500, y: -500), backgroundColor: UIColor.gray)
        } catch {
            print(error)
        }

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
            layers: [],
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
		do {
			var compositionAsset: CompositionVideoAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			
			compositionAsset.layers = [ self.lutLayer ]

			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.playbackView.updateRenderLayer(compositionData: self.compositionData)
		} catch {
			
		}
    }

    /// シーケンスイメージをかぶせる
    @IBAction func tapSequenceImageButton(_ sender: Any) {
		do {
			var compositionAsset: CompositionVideoAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			
			compositionAsset.layers = [ self.sequenceImageLayer ]

			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.playbackView.updateRenderLayer(compositionData: self.compositionData)
		} catch {
			
		}
    }

    /// トランスフォームを適用
    @IBAction func tapTransformButton(_ sender: Any) {
		do {
			var compositionAsset: CompositionVideoAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			
			compositionAsset.layers = [ self.transformLayer ]

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
        do {
			var compositionAsset: CompositionVideoAsset = try self.compositionData.get(assetId: self.compositionAssetId) as! CompositionVideoAsset
			
			compositionAsset.layers = [
				self.sequenceImageLayer,
				self.lutLayer
			]

			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.playbackView.updateRenderLayer(compositionData: self.compositionData)
        } catch {
        }
    }

	
	@IBAction func updateSlider(_ sender: UISlider) {
		self.lutLayer.intensity = sender.value
	}
	
}

extension RenderLayerExampleVC {
    private func getCompositionData(layers: [RenderLayerProtocol]) -> CompositionData {
        return compositionData
    }
}
