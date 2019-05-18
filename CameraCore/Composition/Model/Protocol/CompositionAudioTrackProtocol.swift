//
//  CompositionAudioTrackProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/24.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public struct CompositionAudioTrackProperty {
	internal let id: CompositionAudioTrackId
	internal let create: Date
	internal fileprivate(set) var update: Date
	internal fileprivate(set) var dataId: CompositionDataId?
	internal var compositionAudioTrack: AVMutableCompositionTrack?
	internal var layers: [RenderLayerProtocol]
	internal var assets: [CompositionAudioAssetProtocol]
	internal var audioMixInputParameters: AVMutableAudioMixInputParameters?
	
	public var isEmpty: Bool { get { return assets.count <= 0 } }
	
	public init(
		id: CompositionAudioTrackId,
		create: Date,
		update: Date,
		dataId: CompositionDataId?,
		compositionAudioTrack: AVMutableCompositionTrack?,
		layers: [RenderLayerProtocol],
		assets: [CompositionAudioAssetProtocol],
		audioMixInputParameters: AVMutableAudioMixInputParameters?
		) {
		self.id = id
		self.create = create
		self.update = update
		self.dataId = dataId
		self.compositionAudioTrack = compositionAudioTrack
		self.layers = layers
		self.assets = assets
		self.audioMixInputParameters = audioMixInputParameters
	}
	
	internal mutating func fit() {
		var totalTime: CMTimeValue = 0
		for (index, asset) in self.assets.enumerated() {
			self.assets[index].set(atTime: CMTime.init(value: totalTime, timescale: asset.originalTimeRange.start.timescale))
			totalTime += asset.timeRange.duration.value
		}
	}
	
	internal mutating func set(volume: Float) {
		for (index, _) in self.assets.enumerated() {
			self.assets[index].volume = volume
		}
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionTrackProtocol

public protocol CompositionAudioTrackProtocol: Codable {
	var __property: CompositionAudioTrackProperty { get set }
	var id: CompositionAudioTrackId { get }
	var create: Date { get }
	var update: Date { get }
	var dataId: CompositionDataId? { get }
	var compositionAudioTrack: AVMutableCompositionTrack? { get }
	var layers: [RenderLayerProtocol] { get }
	var assets: [CompositionAudioAssetProtocol] { get }
	var audioMixInputParameters: AVMutableAudioMixInputParameters? { get }
	
	init(assets: [CompositionAudioAssetProtocol], layers: [RenderLayerProtocol]) throws
	
	var isEmpty: Bool { get }
	
	mutating func setup(composition: inout AVMutableComposition, dataId: CompositionDataId, videoCompositionProperty: VideoCompositionProperty) throws
	
	mutating func set(dataId: CompositionDataId) throws
	mutating func add(asset: CompositionAudioAssetProtocol) throws
	func get(assetId: CompositionAudioAssetId) -> CompositionAudioAssetProtocol?
	mutating func updatet(asset: CompositionAudioAssetProtocol) throws
	mutating func remove(assetId: CompositionAudioAssetId) throws
	mutating func removeAllAssets() throws
	mutating func fit()
	mutating func swap(at: CompositionAudioAssetId, to: CompositionAudioAssetId) throws
	mutating func set(volume: Float)
}


// MARK: - CompositionTrackProtocol Extention

extension CompositionAudioTrackProtocol {
	public var id: CompositionAudioTrackId { get { return self.__property.id } }
	public var create: Date { get { return self.__property.create } }
	public var update: Date { get { return self.__property.update } }
	public var dataId: CompositionDataId? { get { return self.__property.dataId } }
	public var compositionAudioTrack: AVMutableCompositionTrack? { get { return self.__property.compositionAudioTrack } }
	public var layers: [RenderLayerProtocol] { get { return self.__property.layers } }
	public var assets: [CompositionAudioAssetProtocol] { get { return self.__property.assets } }
	//public var videoCompositionInstruction: [AVVideoCompositionInstructionProtocol]? { get { return self.__property.videoCompositionInstruction } }
	public var audioMixInputParameters: AVMutableAudioMixInputParameters? { get { return self.__property.audioMixInputParameters } }
	
	public var isEmpty: Bool { get { return self.__property.isEmpty } }
}

extension CompositionAudioTrackProtocol {
	public mutating func set(dataId: CompositionDataId) throws {
		self.__property.dataId = dataId
		for (index, _) in self.assets.enumerated() {
			try self.__property.assets[index].set(dataId: dataId)
		}
		self.__property.update = Date.init()
	}
	
	public mutating func add(asset: CompositionAudioAssetProtocol) throws {
		_ = try asset.isValid()
		var asset = asset
		if let dataId = self.dataId {
			try asset.set(dataId: dataId)
		}
		try asset.set(trackId: self.id)
		self.__property.assets.append(asset)
		self.__property.update = Date.init()
	}
	
	public func get(assetId: CompositionAudioAssetId) -> CompositionAudioAssetProtocol? {
		return (self.assets.filter { $0.id == assetId }).first
	}
	
	public mutating func updatet(asset: CompositionAudioAssetProtocol) throws {
		_ = try asset.isValid()
		var hit: Bool = false
		self.__property.assets = self.__property.assets.map {
			if $0.id == asset.id {
				hit = true
				return asset
			} else {
				return $0
			}
		}
		if hit {
			self.__property.update = Date.init()
		} else {
			throw CompositionErrorType.dataError
		}
	}
	
	public mutating func remove(assetId: CompositionAudioAssetId) throws {
		let tempCount: Int = self.assets.count
		self.__property.assets = self.__property.assets.filter { $0.id != assetId }
		if tempCount == self.assets.count {
			throw CompositionErrorType.dataError
		} else {
			self.__property.update = Date.init()
		}
	}
	
	public mutating func swap(at: CompositionAudioAssetId, to: CompositionAudioAssetId) throws {
		var atIndex: Int? = nil
		for (index, item) in self.__property.assets.enumerated() {
			if item.id == at {
				atIndex = index
			}
		}
		var toIndex: Int? = nil
		for (index, item) in self.__property.assets.enumerated() {
			if item.id == to {
				toIndex = index
			}
		}
		
		guard atIndex != nil, toIndex != nil else { throw CompositionErrorType.dataError }
		self.__property.assets.swapAt(atIndex!, toIndex!)
	}
	
	public mutating func removeAllAssets() {
		self.__property.assets = []
	}
	
	public mutating func fit() {
		self.__property.fit()
	}

	public mutating func set(volume: Float) {
		self.__property.set(volume: volume)
	}
	
	public mutating func setupAudio(composition: inout AVMutableComposition, dataId: CompositionDataId, videoCompositionProperty: VideoCompositionProperty) throws {
		let compositionAudioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
		let audioMixInputParameters: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters(track: compositionAudioTrack)
		for (index, asset) in self.__property.assets.enumerated() {
			if let audioTrack: AVAssetTrack = asset.audioAssetTrack {
				do {
					// audioTrackの配置
					try compositionAudioTrack.insertTimeRange(
						asset.trimTimeRange, // AVAssetTrack の タイムレンジ
						of: audioTrack,
						at: asset.atTime // トラック内の配置位置
					)
					audioMixInputParameters.setVolume(asset.mute == true ? 0.0 : asset.volume, at: asset.atTime)
					
					//////////////////////////////////////////
					// フェードイン指定
					if asset.fadeInTime > 0.0 {
						let fadeinSecond: TimeInterval = asset.trimTimeRange.duration.seconds >= asset.fadeInTime ? asset.fadeInTime : asset.trimTimeRange.duration.seconds
						let fadeinDuration: CMTime = CMTimeMakeWithSeconds(fadeinSecond, preferredTimescale: Int32(fadeinSecond))
						let inTime: CMTime = asset.atTime
						if asset.trimTimeRange.duration.seconds < fadeinDuration.seconds {
							audioMixInputParameters.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: asset.mute == true ? 0.0 : asset.volume, timeRange: CMTimeRangeMake(start: inTime, duration: fadeinDuration))
						}
					}
					//////////////////////////////////////////

					//////////////////////////////////////////
					// フェードアウト指定
					if asset.fadeOutTime > 0.0 {
						let fadeoutSecond: TimeInterval = asset.trimTimeRange.duration.seconds >= asset.fadeOutTime ? asset.fadeOutTime : asset.trimTimeRange.duration.seconds
						let fadeoutDuration: CMTime = CMTimeMakeWithSeconds(fadeoutSecond, preferredTimescale: Int32(fadeoutSecond))
						let outTime: CMTime = CMTimeSubtract(CMTimeAdd(asset.atTime, asset.trimTimeRange.duration), fadeoutDuration)
						if asset.trimTimeRange.duration.seconds < fadeoutDuration.seconds {
							audioMixInputParameters.setVolumeRamp(fromStartVolume: asset.mute == true ? 0.0 : asset.volume, toEndVolume: 0.0, timeRange: CMTimeRangeMake(start: outTime, duration: fadeoutDuration))
						}
					}
					//////////////////////////////////////////
				} catch {
					Debug.ErrorLog("VideoCompositor: no audioTrack")
				}
			}
			compositionAudioTrack.scaleTimeRange( CMTimeRange(start: asset.atTime, duration: asset.trimTimeRange.duration), toDuration: asset.timeRange.duration)
			try self.__property.assets[index].setup(videoCompositionProperty: videoCompositionProperty)
		}
		self.__property.compositionAudioTrack = compositionAudioTrack
		self.__property.audioMixInputParameters = audioMixInputParameters
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Codable

extension CompositionAudioTrackProperty {
	enum CodingKeys: String, CodingKey {
		case id
		case create
		case update
		case dataId
		case layers
		case assets
	}
}

extension CompositionAudioTrackProperty: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.create, forKey: .create)
		try container.encode(self.update, forKey: .update)
		try container.encode(self.dataId, forKey: .dataId)
		//let a: [RenderLayerContainer] = self.layers.map { RenderLayerContainer.init(type: $0.type, customIndex: $0.customIndex, renderLayer: $0) }
		//try container.encode(a, forKey: .layers)
		let assets: [CompositionAudioAsset] = self.assets as! [CompositionAudioAsset]
		try container.encode(assets, forKey: .assets)
	}
}

extension CompositionAudioTrackProperty: Decodable {
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try values.decode(CompositionAudioTrackId.self, forKey: .id)
		self.create = try values.decode(Date.self, forKey: .create)
		self.update = try values.decode(Date.self, forKey: .update)
		self.dataId = try values.decode(CompositionDataId?.self, forKey: .dataId)
		//let renderLayerContainers: [RenderLayerContainer] = try values.decode([RenderLayerContainer].self, forKey: .layers)
		//self.layers = renderLayerContainers.map { $0.renderLayer }
		self.layers = []
		do {
			self.assets = try values.decode([CompositionAudioAsset].self, forKey: .assets)
		} catch {
			self.assets = []
		}
	}
}
