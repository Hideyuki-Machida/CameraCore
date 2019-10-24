//
//  SimpleAVPlayer.swift
//  SimpleAVPlayer
//
//  Created by machidahideyuki on 2018/01/05.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import AVFoundation

public class SimpleAVPlayer: AVPlayer {
	public var timeRange: CMTimeRange?
	public var onUpdate: ((_ time: Float64, _ duration: Float64) -> Void)?
	
	private var _displayLink: CADisplayLink?
	private var _playerItem: AVPlayerItem?
	
	deinit {
		Debug.DeinitLog(self)
	}
	
	fileprivate func startLink() {
		self.closeLink()
		self._displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidRefresh))
		self._displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
	}
	
	public override func seek(to: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
		self.pause()
		super.seek(to: to, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
		self.play()
	}
	
	public override func pause() {
		self.closeLink()
		self.unregisterNotification()
		super.pause()
	}
	
	public override func play() {
		super.play()
		self.startLink()
		self.registerNotification()
	}
	
	public func seek(percent: Float) {
		guard let totalDuration: CMTime = super.currentItem?.duration else { return }
		let s: Double = Double(totalDuration.value) / Double(totalDuration.timescale)
		let time: Double = s * Double(percent)
		let cmtime: CMTime = CMTime(seconds: time, preferredTimescale: totalDuration.timescale).convertScale(30, method: .roundHalfAwayFromZero)
		
		super.pause()
		super.seek(to: cmtime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
	}
	
	
	fileprivate func closeLink() {
		self._displayLink?.remove(from: RunLoop.main, forMode: RunLoop.Mode.common)
		self._displayLink?.invalidate()
		self._displayLink = nil
	}
	
	@objc fileprivate func displayLinkDidRefresh() {
		guard let item: AVPlayerItem = self.currentItem else { return }
		
		// 総再生時間を取得.
		let duration: Float64 = CMTimeGetSeconds(item.duration)
		// 現在の時間を取得.
		let time: Float64 = CMTimeGetSeconds(self.currentTime())
		DispatchQueue.main.async { [weak self] in
			guard duration.isNaN == false else { return }
			self?.onUpdate?(time, duration)
		}
		
		guard let timeRange: CMTimeRange = self.timeRange else { return }
		if time >= timeRange.end.seconds {
			self.pause()
			self.seek(to: timeRange.start, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
			self.play()
		}
	}
	
	fileprivate func registerNotification() {
		self.unregisterNotification()
		NotificationCenter.default.addObserver(self,
											   selector: #selector(videoDidEnd),
											   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
											   object: self.currentItem)
	}
	
	fileprivate func unregisterNotification() {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc private func videoDidEnd(notification: NSNotification) {
		if let timeRange: CMTimeRange = self.timeRange {
			self.seek(to: timeRange.start, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
		} else {
			self.seek(to: CMTime.zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
		}
		self.play()
	}
}

