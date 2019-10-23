//
//  CameraRollManagerVideoPreviewVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/08/27.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore

class CameraRollManagerVideoPreviewVC: UIViewController {

	var playerItem: AVPlayerItem!

    @IBOutlet weak var screen: UIView!
	private var player : AVPlayer! = AVPlayer()

    deinit {
        Debug.DeinitLog(self)
    }
    
	override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

		let playerLayer = AVPlayerLayer(player: self.player)
		playerLayer.frame = self.screen.bounds
		playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
		self.screen.layer.addSublayer(playerLayer)
		
		self.player.replaceCurrentItem(with: self.playerItem)
		self.player.play()
	}

	@IBAction func closeButtonTapAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
