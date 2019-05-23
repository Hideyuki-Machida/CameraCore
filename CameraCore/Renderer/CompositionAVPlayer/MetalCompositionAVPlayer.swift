//
//  MetalCompositionAVPlayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/10/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

extension Renderer {
	public class MetalCompositionAVPlayer: NSObject, CompositionAVPlayerProtocol, RenderEventControllerProtocol {
		public var events: [RenderEventProtocol] = []
		
		public typealias PlayerStatus = CompositionAVPlayerStatus
		public typealias ErrorType = CompositionAVPlayerErrorType
		
		public fileprivate(set) var status: Renderer.CompositionAVPlayer.PlayerStatus = .setup {
			willSet {
				self.event?.onStatusChange?(newValue)
			}
		}
		
		public var curentTime: (time: Double, duration: Double)? {
			get {
				guard let player: AVPlayer = self.player else { return nil }
				guard let item: AVPlayerItem = player.currentItem else { return nil }
				
				// 総再生時間を取得.
				let duration: Float64 = CMTimeGetSeconds(item.duration)
				// 現在の時間を取得.
				let time: Float64 = CMTimeGetSeconds(player.currentTime())
				
				return (time: time, duration: duration)
			}
			
		}
		
		fileprivate let queue: DispatchQueue = DispatchQueue(label: "CameraCore.CompositionAVPlayer.queue")
		public var player: AVPlayer?
		fileprivate var output: AVPlayerItemVideoOutput?
		fileprivate var isRepeat: Bool = false
		fileprivate var displayLink: CADisplayLink?
		
		public var event: Renderer.CompositionAVPlayerEvent?
		public var onPixelUpdate: ((_ pixelBuffer: CVPixelBuffer)->Void)?
		
		deinit {
			self.dispose()
			//self.player?.currentItem?.removeObserver(self, forKeyPath: "status")
			Debug.DeinitLog(self)
		}
		
		/// setup: Video & Audio
		public func setup(compositionData: CompositionDataProtocol) throws {
			let playerItem: AVPlayerItem = AVPlayerItem(asset: compositionData.composition)
			if let videoComposition: AVMutableVideoComposition = compositionData.videoComposition {
				playerItem.videoComposition = videoComposition
			}
			playerItem.audioMix = compositionData.audioMix
			//playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
			if compositionData.videoComposition != nil {
				self.output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
					kCVPixelBufferPixelFormatTypeKey as String: Configuration.outputPixelBufferPixelFormatTypeKey,
					kCVPixelBufferWidthKey as String : compositionData.property.presetiFrame.size().width,
					kCVPixelBufferHeightKey as String : compositionData.property.presetiFrame.size().height,
					kCVPixelFormatOpenGLESCompatibility as String : true,
					])
				output?.setDelegate(self, queue: self.queue)
				output?.suppressesPlayerRendering = true
				playerItem.add(self.output!)
			}
			
			self.player = AVPlayer(playerItem: playerItem)
			self.player?.replaceCurrentItem(with: nil)
			self.player?.replaceCurrentItem(with: playerItem)
			self.status = .ready
		}
		
		public func updateAll(compositionData: CompositionDataProtocol) throws {
			self.unregisterNotification()
			self.closeLink()
			self.player?.pause()
			self.seek(time: CMTime.zero)
			let playerItem: AVPlayerItem = AVPlayerItem(asset: compositionData.composition)
			if let videoComposition: AVMutableVideoComposition = compositionData.videoComposition {
				playerItem.videoComposition = videoComposition
			}
			playerItem.audioMix = compositionData.audioMix
			if let output = self.output {
				playerItem.add(output)
			}
			self.player = AVPlayer(playerItem: playerItem)
			self.player?.replaceCurrentItem(with: nil)
			self.player?.replaceCurrentItem(with: playerItem)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
				guard self?.status == .play else {
					self?.status = .ready
					return
				}
				self?._play()
			}
		}
		
		public func updateRenderLayer(compositionData: CompositionDataProtocol) throws {
			if let videoComposition: AVMutableVideoComposition = compositionData.videoComposition {
				self.player?.currentItem?.videoComposition = videoComposition
			} else {
				throw ErrorType.setupError
			}
		}
		
		public func updateAudioMix(compositionData: CompositionDataProtocol) throws {
			autoreleasepool() { [weak self] in
				self?.player?.currentItem?.audioMix = compositionData.audioMix
			}
		}
		
		/*
		override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		
		guard let playerItem: AVPlayerItem = self.player?.currentItem else { return }
		switch playerItem.status {
		case AVPlayerItemStatus.readyToPlay:
		//メインスレッドで実行
		DispatchQueue.main.async { [weak self] in
		guard let `self` = self else { return }
		
		guard self.status == .play else {
		self.status = .ready
		return
		}
		
		if self.update == true {
		self.update = false
		let output: AVPlayerItemVideoOutput = self.output
		self.player?.currentItem?.add(output)
		self._play()
		}
		}
		case AVPlayerItemStatus.failed:
		
		break
		case .unknown:
		
		break
		}
		}
		*/
		var update: Bool = false
		
		public func duration() -> CMTime? {
			guard
				let player: AVPlayer = self.player,
				let currentItem: AVPlayerItem = player.currentItem
				else { return nil }
			return currentItem.duration
		}
	}
}

extension Renderer.MetalCompositionAVPlayer {
	public func play(isRepeat: Bool) {
		guard self.status != .setup, self.status != .dispose, self.status != .play else { return }
		self.isRepeat = isRepeat
		self._play()
	}
	
	public func replay(isRepeat: Bool) {
		guard self.status != .setup else { return }
		self.registerNotification()
		self.startLink()
		
		self.isRepeat = isRepeat
		self.player?.pause()
		self.player?.seek(to: CMTime.zero)
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
			self?.player?.play()
			self?.status = .play
		}
	}
	
	public func pause() {
		guard self.status != .setup, self.status != .dispose, self.status != .pause else { return }
		self.unregisterNotification()
		self.closeLink()
		self.player?.pause()
		self.status = .pause
	}
	
	fileprivate func _play() {
		self.registerNotification()
		self.startLink()
		self.player?.play()
		self.status = .play
	}
	
	public func seek(time: CMTime) {
		self.player?.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
		self.status = .seek
	}
	public func seek(percent: Float) {
		guard let totalDuration: CMTime = self.player?.currentItem?.duration else { return }
		let s: Double = Double(totalDuration.value) / Double(totalDuration.timescale)
		let time: Double = s * Double(percent)
		let cmtime: CMTime = CMTime(seconds: time, preferredTimescale: totalDuration.timescale).convertScale(Configuration.compositionFramerate, method: .roundHalfAwayFromZero)
		
		self.player?.pause()
		self.player?.seek(to: cmtime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
		self.status = .seek
	}
	
	public func dispose() {
		self.unregisterNotification()
		self.closeLink()
		self.player?.pause()
		//self.isDrawable = false
		self.status = .dispose
	}
	
}


extension Renderer.MetalCompositionAVPlayer {
	
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
		guard self.status == .play || self.status == .seek else { return }
		
		self.frameUpdate()
		
		guard let output: AVPlayerItemVideoOutput = self.player?.currentItem?.outputs.compactMap({ $0 as? AVPlayerItemVideoOutput }).first else { return }
		
		let itemTime: CMTime = output.itemTime(forHostTime: CACurrentMediaTime())
		if output.hasNewPixelBuffer(forItemTime: itemTime) {
			autoreleasepool() { [weak self] in
				guard let pixelBuffer: CVPixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) else { return }
				self?.onPixelUpdate?(pixelBuffer)
			}
		}
		
	}
	
	fileprivate func frameUpdate() {
		guard let player: AVPlayer = self.player else { return }
		guard let item: AVPlayerItem = player.currentItem else { return }
		
		// 総再生時間を取得.
		let duration: Float64 = CMTimeGetSeconds(item.duration)
		// 現在の時間を取得.
		let time: Float64 = CMTimeGetSeconds(player.currentTime())
		DispatchQueue.main.async { [weak self] in
			self?.event?.onFrameUpdate?(time, duration)
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
		self.event?.onPreviewFinish?()
		self.status = .endTime
		if self.isRepeat {
			self.seek(time: CMTime.zero)
			self.player?.play()
			self.status = .play
		}
	}
}


extension Renderer.MetalCompositionAVPlayer: AVPlayerItemOutputPullDelegate {
	
	public func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
	}
	
	public func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) {
	}
	
}
