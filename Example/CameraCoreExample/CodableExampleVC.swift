//
//  CodableExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/08/26.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class CodableExampleVC: UIViewController {
    
    @IBOutlet weak var playbackView: CameraCore.MetalVideoPlaybackView!
    
    private let path: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/data.json"
	private let videoCompositionProperty: VideoCompositionProperty = VideoCompositionProperty.init(
		frameRate: 1,
		presetiFrame: Settings.PresetiFrame.p1280x720,
		renderSize: Settings.PresetiFrame.p1280x720.size(),
		renderScale: 1.0,
		renderType: Settings.RenderType.metal
	)

    private var compositionData: CompositionData!
    private var compositionAssetId: CompositionVideoAssetId!
    
    deinit {
        self.playbackView.pause()
        self.playbackView.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let compositionData: CompositionData = try JSONDecoder().decode(CompositionData.self, from: try Data.init(contentsOf: URL.init(fileURLWithPath: self.path)))
            self.compositionData = compositionData
            self.compositionAssetId = self.compositionData.videoTracks[0].assets[0].id
            do {
                try self.compositionData.setup()
                try self.playbackView.setup(compositionData: self.compositionData)
                self.playbackView.play(isRepeat: true)
            } catch {

            }
        } catch {
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
			
			compositionAsset.layers = [
				try LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: 64)
			]
			
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
			
			compositionAsset.layers = [
				SequenceImageLayer.init(imagePaths: iOS_DummyAVAssets.AssetManager.SequenceImage.sample001.urls, blendMode: Blendmode.screen, updateFrameRate: 30)
			]
			
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
			let imagePath: URL = iOS_DummyAVAssets.AssetManager.SequenceImage.sample001.urls[1]
			var compositionAsset: CompositionVideoAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)

			let imageLayer: ImageLayer = ImageLayer.init(imagePath: imagePath,
							blendMode: Blendmode.alpha,
							alpha: 0.5,
							renderSize: self.videoCompositionProperty.renderSize,
							contentMode: CompositionImageLayerContentMode.none,
							transform: nil)
			
			compositionAsset.layers = [
				imageLayer
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
			var compositionAsset: CompositionVideoAssetProtocol = try self.compositionData.get(assetId: self.compositionAssetId)
			
			compositionAsset.layers = [
				SequenceImageLayer.init(imagePaths: iOS_DummyAVAssets.AssetManager.SequenceImage.sample001.urls, blendMode: Blendmode.screen, updateFrameRate: 30),
				try LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: 64)
			]
			
			try self.compositionData.updatet(asset: compositionAsset)
            try self.compositionData.setup()
            try self.playbackView.updateRenderLayer(compositionData: self.compositionData)
        } catch {
        }
    }
    
    @IBAction func tapSaveDataButton(_ sender: Any) {
        let data: Data = try! JSONEncoder().encode(self.compositionData)
		let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{ (action: UIAlertAction!) -> Void in
            print("OK")
        })
        do {
            try data.write(to: URL.init(fileURLWithPath: self.path))
			let alert: UIAlertController = UIAlertController(title: "CompositionDataを保存しました", message: "", preferredStyle:  UIAlertController.Style.alert)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        } catch {
			let alert: UIAlertController = UIAlertController(title: "CompositionDataの保存に失敗しました", message: "", preferredStyle:  UIAlertController.Style.alert)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func tapLoadDataButton(_ sender: Any) {
        let compositionData: CompositionData = try! JSONDecoder().decode(CompositionData.self, from: try Data.init(contentsOf: URL.init(fileURLWithPath: self.path)))
		let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{ (action: UIAlertAction!) -> Void in
            print("OK")
        })
        self.compositionData = compositionData
        do {
            try self.compositionData.setup()
            try self.playbackView.updateAll(compositionData: self.compositionData)
            self.playbackView.replay(isRepeat: true)
			let alert: UIAlertController = UIAlertController(title: "CompositionDataをLoadしました", message: "", preferredStyle:  UIAlertController.Style.alert)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        } catch {
			let alert: UIAlertController = UIAlertController(title: "CompositionDataをLoadに失敗しました", message: "", preferredStyle:  UIAlertController.Style.alert)
            alert.addAction(defaultAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

}
