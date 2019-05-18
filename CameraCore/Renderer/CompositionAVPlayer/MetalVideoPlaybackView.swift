//
//  MetalVideoPlaybackView.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/10/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation

public class MetalVideoPlaybackView: MetalImageRenderView, CompositionAVPlayerProtocol {
	
	public var status: PlayerStatus {
		get {
			return self.compositionAVPlayer.status
		}
	}
	public var curentTime: (time: Double, duration: Double)? {
		get {
			return self.compositionAVPlayer.curentTime
		}
		
	}
	
	public typealias PlayerStatus = CompositionAVPlayerStatus
	public typealias ErrorType = CompositionAVPlayerErrorType
	
	fileprivate let queue: DispatchQueue = DispatchQueue(label: "com.cchannel.CameraCore.VideoPlayback.queue")
	fileprivate var compositionAVPlayer: Renderer.CompositionAVPlayer = Renderer.CompositionAVPlayer()
	
	public var event: Renderer.CompositionAVPlayerEvent? {
		get {
			return self.compositionAVPlayer.event
		}
		set {
			self.compositionAVPlayer.event = newValue
		}
	}
	public var compositionData: CompositionDataProtocol? {
		get {
			return self.compositionAVPlayer.compositionData
		}
	}
	public var onPixelUpdate: ((_ pixelBuffer: CVPixelBuffer)->Void)?
	
	deinit {
		self.dispose()
		//self.player?.currentItem?.removeObserver(self, forKeyPath: "status")
		Debug.DeinitLog(self)
	}
	
	/// setup: Video & Audio
	public func setup(compositionData: CompositionDataProtocol) throws {
		super.setup()
		try self.compositionAVPlayer.setup(compositionData: compositionData)
		self.compositionAVPlayer.onPixelUpdate = { [weak self] (pixelBuffer: CVPixelBuffer) in
			let width: Int = CVPixelBufferGetWidth(pixelBuffer)
			let height: Int = CVPixelBufferGetHeight(pixelBuffer)
			self?.updatePixelBuffer(pixelBuffer: pixelBuffer, renderLayers: [], renderSize: CGSize.init(width: width, height: height))
			self?.onPixelUpdate?(pixelBuffer)
		}
	}
	
	public func updateAll(compositionData: CompositionDataProtocol) throws {
		try self.compositionAVPlayer.updateAll(compositionData: compositionData)
	}
	
	public func updateRenderLayer(compositionData: CompositionDataProtocol) throws {
		try self.compositionAVPlayer.updateRenderLayer(compositionData: compositionData)
	}
	
	public func updateAudioMix(compositionData: CompositionDataProtocol) throws {
		try self.compositionAVPlayer.updateAudioMix(compositionData: compositionData)
	}
}


extension MetalVideoPlaybackView {
	public func play(isRepeat: Bool) {
		self.compositionAVPlayer.play(isRepeat: isRepeat)
	}
	
	public func replay(isRepeat: Bool) {
		self.compositionAVPlayer.replay(isRepeat: isRepeat)
	}
	
	
	public func pause() {
		self.compositionAVPlayer.pause()
	}
	
	public func seek(time: CMTime) {
		self.compositionAVPlayer.seek(time: time)
	}
	
	public func seek(percent: Float) {
		self.compositionAVPlayer.seek(percent: percent)
	}
	
	public func dispose() {
		self.compositionAVPlayer.dispose()
	}
	
}
