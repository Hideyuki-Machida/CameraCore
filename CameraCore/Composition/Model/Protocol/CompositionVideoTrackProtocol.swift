//
//  CompositionVideoTrackProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/24.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionAssetType

/*
public enum CompositionTrackType: Int, Codable {
	case video = 0
	case audio = 1
	
	public func type() -> CompositionTrackProtocol.Type {
		switch self {
		case .video: return CompositionVideoTrack.self
		case .audio: return CompositionAudioTrack.self
		}
	}
	
	public func decode(to: Data) throws -> CompositionTrackProtocol {
		switch self {
		case .video: return try JSONDecoder().decode(CompositionVideoTrack.self, from: to)
		case .audio: return try JSONDecoder().decode(CompositionAudioTrack.self, from: to)
		}
	}
}
*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionTrackProtocolErrorType
/*
public enum CompositionTrackProtocolErrorType: Error {
	case dataError
}
*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionTrackProperty

public struct CompositionVideoTrackProperty {
	internal let id: CompositionVideoTrackId
	internal let create: Date
	internal fileprivate(set) var update: Date
	internal fileprivate(set) var dataId: CompositionDataId?
	internal var compositionVideoTrack: AVMutableCompositionTrack?
	internal var compositionAudioTrack: AVMutableCompositionTrack?
	internal var layers: [RenderLayerProtocol]
	internal var assets: [CompositionVideoAssetProtocol]
	internal var videoCompositionInstruction: [AVVideoCompositionInstructionProtocol]?
	internal var audioMixInputParameters: AVMutableAudioMixInputParameters?
	
	public var isEmpty: Bool { get { return assets.count <= 0 } }
	
	public init(
		id: CompositionVideoTrackId,
		create: Date,
		update: Date,
		dataId: CompositionDataId?,
		compositionVideoTrack: AVMutableCompositionTrack?,
		compositionAudioTrack: AVMutableCompositionTrack?,
		layers: [RenderLayerProtocol],
		assets: [CompositionVideoAssetProtocol],
		videoCompositionInstruction: [AVVideoCompositionInstructionProtocol]?,
		audioMixInputParameters: AVMutableAudioMixInputParameters?
		) {
		self.id = id
		self.create = create
		self.update = update
		self.dataId = dataId
		self.compositionVideoTrack = compositionVideoTrack
		self.compositionAudioTrack = compositionAudioTrack
		self.layers = layers
		self.assets = assets
		self.videoCompositionInstruction = videoCompositionInstruction
		self.audioMixInputParameters = audioMixInputParameters
	}
	
	internal mutating func fit() {
		var totalTime: CMTimeValue = 0
		for (index, asset) in self.assets.enumerated() {
			self.assets[index].set(atTime: CMTime.init(value: totalTime, timescale: asset.originalTimeRange.start.timescale))
			totalTime += asset.timeRange.duration.value
		}
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionTrackProtocol

public protocol CompositionVideoTrackProtocol: Codable {
	var __property: CompositionVideoTrackProperty { get set }
	var id: CompositionVideoTrackId { get }
	var create: Date { get }
	var update: Date { get }
	var dataId: CompositionDataId? { get }
	var compositionVideoTrack: AVMutableCompositionTrack? { get }
	var compositionAudioTrack: AVMutableCompositionTrack? { get }
	var layers: [RenderLayerProtocol] { get set }
	var assets: [CompositionVideoAssetProtocol] { get }
	var videoCompositionInstruction: [AVVideoCompositionInstructionProtocol]? { get }
	var audioMixInputParameters: AVMutableAudioMixInputParameters? { get }
	
	init(assets: [CompositionVideoAssetProtocol], layers: [RenderLayerProtocol]) throws
	
	var isEmpty: Bool { get }
	
	mutating func setup(composition: inout AVMutableComposition, dataId: CompositionDataId, videoCompositionProperty: inout VideoCompositionProperty) throws
	
	mutating func set(dataId: CompositionDataId) throws
	mutating func add(asset: CompositionVideoAssetProtocol) throws
	func get(assetId: CompositionVideoAssetId) -> CompositionVideoAssetProtocol?
	mutating func updatet(asset: CompositionVideoAssetProtocol) throws
	mutating func remove(assetId: CompositionVideoAssetId) throws
	mutating func removeAllAssets() throws
	mutating func fit()
	mutating func swap(at: CompositionVideoAssetId, to: CompositionVideoAssetId) throws
}


// MARK: - CompositionTrackProtocol Extention

extension CompositionVideoTrackProtocol {
	public var id: CompositionVideoTrackId { get { return self.__property.id } }
	public var create: Date { get { return self.__property.create } }
	public var update: Date { get { return self.__property.update } }
	public var dataId: CompositionDataId? { get { return self.__property.dataId } }
	public var compositionVideoTrack: AVMutableCompositionTrack? { get { return self.__property.compositionVideoTrack } }
	public var compositionAudioTrack: AVMutableCompositionTrack? { get { return self.__property.compositionAudioTrack } }
	public var layers: [RenderLayerProtocol] { get { return self.__property.layers } set { return self.__property.layers = newValue } }
	public var assets: [CompositionVideoAssetProtocol] { get { return self.__property.assets } }
	//public var videoCompositionInstruction: [AVVideoCompositionInstructionProtocol]? { get { return self.__property.videoCompositionInstruction } }
	public var audioMixInputParameters: AVMutableAudioMixInputParameters? { get { return self.__property.audioMixInputParameters } }
	
	public var isEmpty: Bool { get { return self.__property.isEmpty } }
}

extension CompositionVideoTrackProtocol {
	public mutating func set(dataId: CompositionDataId) throws {
		self.__property.dataId = dataId
		for (index, _) in self.assets.enumerated() {
			try self.__property.assets[index].set(dataId: dataId)
		}
		self.__property.update = Date.init()
	}
	
	public mutating func add(asset: CompositionVideoAssetProtocol) throws {
		_ = try asset.isValid()
		var asset = asset
		if let dataId = self.dataId {
			try asset.set(dataId: dataId)
		}
		try asset.set(trackId: self.id)
		self.__property.assets.append(asset)
		self.__property.update = Date.init()
	}
	
	public func get(assetId: CompositionVideoAssetId) -> CompositionVideoAssetProtocol? {
		return (self.assets.filter { $0.id == assetId }).first
	}
	
	public mutating func updatet(asset: CompositionVideoAssetProtocol) throws {
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
	
	public mutating func remove(assetId: CompositionVideoAssetId) throws {
		let tempCount: Int = self.assets.count
		self.__property.assets = self.__property.assets.filter { $0.id != assetId }
		if tempCount == self.assets.count {
			throw CompositionErrorType.dataError
		} else {
			self.__property.update = Date.init()
		}
	}
	
	public mutating func swap(at: CompositionVideoAssetId, to: CompositionVideoAssetId) throws {
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
	
	public mutating func setupVideo(composition: inout AVMutableComposition, dataId: CompositionDataId, videoCompositionProperty: inout VideoCompositionProperty) throws {
		let compositionVideoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!
		let compositionAudioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
		
		let audioMixInputParameters: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters(track: compositionAudioTrack)
		for (index, asset) in self.__property.assets.enumerated() {
			if let videoAssetTrack: AVAssetTrack = asset.videoAssetTrack {
				do {
					// videoTrackの配置
					try compositionVideoTrack.insertTimeRange(
						asset.trimTimeRange, // AVAssetTrack の タイムレンジ
						of: videoAssetTrack,
						at: asset.atTime // トラック内の配置位置
					)
					if let replacAudio: AVURLAsset = asset.replacAudio {
						for audioAssetTrack: AVAssetTrack in replacAudio.tracks(withMediaType: AVMediaType.audio) {
							// audioTrackの配置
							try compositionAudioTrack.insertTimeRange(
								asset.timeRange, // AVAssetTrack の タイムレンジ
								of: audioAssetTrack,
								at: asset.atTime // トラック内の配置位置
							)
						}
						audioMixInputParameters.setVolume(asset.volume, at: asset.atTime)
					} else if let audioTrack: AVAssetTrack = asset.audioAssetTrack, asset.mute != true, asset.replacAudio == nil, asset.rate == 1.0 {
						// audioTrackの配置
						try compositionAudioTrack.insertTimeRange(
							asset.trimTimeRange, // AVAssetTrack の タイムレンジ
							of: audioTrack,
							at: asset.atTime // トラック内の配置位置
						)
						audioMixInputParameters.setVolume(asset.volume, at: asset.atTime)
					} else {
						Debug.ErrorLog("VideoCompositor: no audioTrack")
					}
				} catch {
					Debug.ErrorLog("VideoCompositor: _createCompositionVideoTrack")
				}
			}
			compositionVideoTrack.scaleTimeRange( CMTimeRange(start: asset.atTime, duration: asset.trimTimeRange.duration), toDuration: asset.timeRange.duration)
			if asset.replacAudio == nil {
				compositionAudioTrack.scaleTimeRange( CMTimeRange(start: asset.atTime, duration: asset.trimTimeRange.duration), toDuration: asset.timeRange.duration)
			}
			try self.__property.assets[index].setup(videoCompositionProperty: videoCompositionProperty)
		}

		self.__property.compositionVideoTrack = compositionVideoTrack
		self.__property.compositionAudioTrack = compositionAudioTrack
		//self.videoCompositionInstruction = self.getVideoCompositionInstruction()
		self.__property.audioMixInputParameters = audioMixInputParameters
	}
}

extension CompositionVideoTrackProtocol {
	public var videoCompositionInstruction: [AVVideoCompositionInstructionProtocol]? {
		get {
			return self.getVideoCompositionInstruction()
		}
	}
	/// AVMutableVideoCompositionInstructionを作成
	fileprivate func getVideoCompositionInstruction() -> [AVVideoCompositionInstructionProtocol]? {
		guard self.compositionVideoTrack != nil else { return nil }
		var instructions: [AVVideoCompositionInstructionProtocol] = []
		let trackID: CMPersistentTrackID = self.compositionVideoTrack!.trackID
		for assetData: CompositionVideoAssetProtocol in self.assets {
			let trackIDNumber = NSNumber.init(value: trackID)
			let timeRange: CMTimeRange = CMTimeRange.init(start: assetData.atTime, duration: assetData.timeRange.duration)
			let instruction = CustomVideoCompositionInstruction.init(theSourceTrackIDs: [trackIDNumber], forTimeRange: timeRange)
			//instruction.compositionVideoAsset = assetData as? CompositionVideoAsset
			instruction.compositionVideoAsset = assetData
			instruction.compositionVideoTrack = self
			instruction.enablePostProcessing = true
			instruction.timeRange = timeRange
			instructions.append(instruction)
		}
		
		return instructions
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Codable

extension CompositionVideoTrackProperty {
	enum CodingKeys: String, CodingKey {
		case id
		case create
		case update
		case dataId
		case layers
		case assets
	}
}

extension CompositionVideoTrackProperty: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.create, forKey: .create)
		try container.encode(self.update, forKey: .update)
		try container.encode(self.dataId, forKey: .dataId)
		//let a: [RenderLayerContainer] = self.layers.map { RenderLayerContainer.init(type: $0.type, customIndex: $0.customIndex, renderLayer: $0) }
		//try container.encode(a, forKey: .layers)
		let assets: [CompositionVideoAsset] = self.assets as! [CompositionVideoAsset]
		try container.encode(assets, forKey: .assets)
	}
}

extension CompositionVideoTrackProperty: Decodable {
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try values.decode(CompositionVideoTrackId.self, forKey: .id)
		self.create = try values.decode(Date.self, forKey: .create)
		self.update = try values.decode(Date.self, forKey: .update)
		self.dataId = try values.decode(CompositionDataId?.self, forKey: .dataId)
		//let renderLayerContainers: [RenderLayerContainer] = try values.decode([RenderLayerContainer].self, forKey: .layers)
		//self.layers = renderLayerContainers.map { $0.renderLayer }
		self.layers = []
		do {
			self.assets = try values.decode([CompositionVideoAsset].self, forKey: .assets)
		} catch {
			self.assets = []
		}
	}
}
