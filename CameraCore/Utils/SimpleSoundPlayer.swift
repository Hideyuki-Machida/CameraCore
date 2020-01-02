//
//  SoundPlayer.swift
//  MystaVideoModule
//
//  Created by 町田 秀行 on 2018/03/22.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import AVFoundation

final public class SimpleSoundPlayer: NSObject {
	public static let shared = SimpleSoundPlayer()

	fileprivate var displayLink: CADisplayLink?
	fileprivate var context = "playAudioContext"
	fileprivate var player: AVPlayer?
	fileprivate var playerItem: AVPlayerItem?

	public var id: String?
	public var onPlayUpdate: ((_ time: Float64, _ duration: Float64)->Void)?
	public var onPlayComplete: (()->Void)?

	private override init() {
		super.init()
		self.player = AVPlayer.init()
	}

	public func setup(id: String, url: String) {
		let asset: AVURLAsset = AVURLAsset.init(url: URL.init(string: url)!)
		self.onPlayComplete?()
		self.pause()
		self.id = id
		let playerItem: AVPlayerItem = AVPlayerItem.init(asset: asset)
		self.player?.replaceCurrentItem(with: nil)
		self.player?.replaceCurrentItem(with: playerItem)
	}

	public func setup(id: String, url: URL) {
		let asset: AVURLAsset = AVURLAsset.init(url: url)
		self.onPlayComplete?()
		self.pause()
		self.id = id
		let playerItem: AVPlayerItem = AVPlayerItem.init(asset: asset)
		self.player?.replaceCurrentItem(with: nil)
		self.player?.replaceCurrentItem(with: playerItem)
	}

	public func play() {
		self.startLink()
		self.registerNotification()
		self.player?.play()
	}

	public func pause() {
		self.id = nil
		self.closeLink()
		self.unregisterNotification()
		self.player?.pause()
	}
}

extension SimpleSoundPlayer {

	fileprivate func startLink() {
		self.closeLink()
		self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidRefresh))
		self.displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
	}

	fileprivate func closeLink() {
		self.displayLink?.remove(from: RunLoop.main, forMode: RunLoop.Mode.common)
		self.displayLink?.invalidate()
		self.displayLink = nil
	}

	@objc fileprivate func displayLinkDidRefresh() {
		guard let player: AVPlayer = self.player, let playerItem: AVPlayerItem = player.currentItem else { return }
		let duration: Float64 = CMTimeGetSeconds(playerItem.duration)
		let time: Float64 = CMTimeGetSeconds(player.currentTime())
		DispatchQueue.main.async { [weak self] in
			self?.onPlayUpdate?(time, duration)
		}
	}

	fileprivate func registerNotification() {
		self.unregisterNotification()
		NotificationCenter.default.addObserver(self,
											   selector: #selector(videoDidEnd),
											   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
											   object: self.player?.currentItem)
	}

	fileprivate func unregisterNotification() {
		NotificationCenter.default.removeObserver(self)
	}

	@objc private func videoDidEnd(notification: NSNotification) {
		DispatchQueue.main.async { [weak self] in
			self?.onPlayComplete?()
			self?.id = nil
		}
	}
}
