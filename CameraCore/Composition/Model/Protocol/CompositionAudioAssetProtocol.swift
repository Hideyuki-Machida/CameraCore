//
//  CompositionAudioAssetProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/24.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionAssetProperty

public struct CompositionAudioAssetProperty {
	internal fileprivate(set) var id: CompositionAudioAssetId
	internal let create: Date
	internal fileprivate(set) var update: Date
	internal fileprivate(set) var dataId: CompositionDataId?
	internal fileprivate(set) var trackId: CompositionAudioTrackId?
	internal fileprivate(set) var avAsset: AVURLAsset
	internal fileprivate(set) var audioAssetTrack: AVAssetTrack?
	internal fileprivate(set) var originalTimeRange: CMTimeRange
	
	internal var volume: Float
	internal var mute: Bool
	internal var layers: [RenderLayerProtocol]
	internal var atTime: CMTime
	internal fileprivate(set) var rate: Float64
	internal fileprivate(set) var trimTimeRange: CMTimeRange
	internal fileprivate(set) var timeRange: CMTimeRange
	internal fileprivate(set) var fadeInTime: TimeInterval
	internal fileprivate(set) var fadeOutTime: TimeInterval
	
	public init(
		id: CompositionAudioAssetId,
		create: Date,
		update: Date,
		dataId: CompositionDataId?,
		trackId: CompositionAudioTrackId?,
		avAsset: AVURLAsset,
		audioAssetTrack: AVAssetTrack?,
		originalTimeRange: CMTimeRange,
		
		volume: Float,
		mute: Bool,
		layers: [RenderLayerProtocol],
		atTime: CMTime,
		rate: Float64,
		trimTimeRange: CMTimeRange,
		timeRange: CMTimeRange,
		fadeInTime: TimeInterval = 0.0,
		fadeOutTime: TimeInterval = 0.0
		) {
		self.id = id
		self.create = create
		self.update = update
		self.dataId = dataId
		self.trackId = trackId
		self.avAsset = avAsset
		self.audioAssetTrack = audioAssetTrack
		self.originalTimeRange = originalTimeRange
		
		self.volume = volume
		self.mute = mute
		self.layers = layers
		self.atTime = atTime
		self.rate = rate
		self.trimTimeRange = trimTimeRange
		self.timeRange = timeRange
		self.fadeInTime = fadeInTime
		self.fadeOutTime = fadeOutTime
	}
	
	public mutating func setup(videoCompositionProperty: VideoCompositionProperty) throws {
		//guard let videoAssetTrack: AVAssetTrack = self.videoAssetTrack else { return }
		//self.contentModeTransform = self.contentMode.transform(videoSize: videoAssetTrack.naturalSize, renderSize: videoCompositionProperty.renderSize, transform: CGAffineTransform.identity)
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionAssetProtocol

public protocol CompositionAudioAssetProtocol: Codable {
	var __property: CompositionAudioAssetProperty { get set }
	var id: CompositionAudioAssetId { get }
	var create: Date { get }
	var update: Date { get }
	var dataId: CompositionDataId? { get }
	var trackId: CompositionAudioTrackId? { get }
	var avAsset: AVURLAsset { get }
	var audioAssetTrack: AVAssetTrack? { get }
	var originalTimeRange: CMTimeRange { get }
	
	var volume: Float { set get }
	var mute: Bool { set get }
	var layers: [RenderLayerProtocol] { set get }
	var atTime: CMTime { get }
	var rate: Float64 { get }
	var trimTimeRange: CMTimeRange { get }
	var timeRange: CMTimeRange { get }
	var fadeInTime: TimeInterval { set get }
	var fadeOutTime: TimeInterval { set get }
	
	func isValid() throws -> Bool
	
	mutating func set(trimTimeRange: CMTimeRange)
	mutating func set(rate: Float64)
	mutating func set(atTime: CMTime)
	
	mutating func set(dataId: CompositionDataId) throws
	mutating func set(trackId: CompositionAudioTrackId) throws
	
	mutating func setup(videoCompositionProperty: VideoCompositionProperty) throws
}


// MARK: - CompositionAssetProtocol Extention

extension CompositionAudioAssetProtocol {
	public var id: CompositionAudioAssetId { get { return self.__property.id } }
	public var create: Date { get { return self.__property.create } }
	public var update: Date { get { return self.__property.update } }
	public var dataId: CompositionDataId? { get { return self.__property.dataId } }
	public var trackId: CompositionAudioTrackId? { get { return self.__property.trackId } }
	public var avAsset: AVURLAsset { get { return self.__property.avAsset } }
	public var audioAssetTrack: AVAssetTrack? { get { return self.__property.audioAssetTrack } }
	public var originalTimeRange: CMTimeRange { get { return self.__property.originalTimeRange } }
	
	public var volume: Float { get { return self.__property.volume } set { self.__property.volume = newValue } }
	public var mute: Bool { get { return self.__property.mute } set { self.__property.mute = newValue } }
	public var layers: [RenderLayerProtocol] { get { return self.__property.layers } set { self.__property.layers = newValue } }
	public var atTime: CMTime { get { return self.__property.atTime } }
	public var rate: Float64 { get { return self.__property.rate } }
	public var trimTimeRange: CMTimeRange { get { return self.__property.trimTimeRange } }
	public var timeRange: CMTimeRange { get { return self.__property.timeRange } }
	public var fadeInTime: TimeInterval { get { return self.__property.fadeInTime } set { self.__property.fadeInTime = newValue } }
	public var fadeOutTime: TimeInterval { get { return self.__property.fadeOutTime } set { self.__property.fadeOutTime = newValue } }
}

extension CompositionAudioAssetProtocol {
	public func isValid() throws -> Bool {
		guard self.__property.avAsset.isPlayable == true else { throw CompositionAssetErrorType.isPlayableError }
		guard self.__property.avAsset.isExportable == true else { throw CompositionAssetErrorType.isExportableError }
		guard self.__property.avAsset.isReadable == true else { throw CompositionAssetErrorType.isReadableError }
		guard self.__property.avAsset.isComposable == true else { throw CompositionAssetErrorType.isComposableError }
		guard self.__property.avAsset.hasProtectedContent == false else { throw CompositionAssetErrorType.hasProtectedContentError }
		
		if self.__property.avAsset.tracks.count <= 0 {
			throw CompositionAssetErrorType.trackError
		}
		return true
	}
}

extension CompositionAudioAssetProtocol {
	public mutating func set(dataId: CompositionDataId) {
		self.__property.dataId = dataId
	}
	
	public mutating func set(trackId: CompositionAudioTrackId) {
		self.__property.trackId = trackId
	}
	
	public mutating func set(trimTimeRange: CMTimeRange) {
		let scaledTrimTimeRange: CMTimeRange = CMTimeRange.convertTimeRange(timeRange: trimTimeRange, rate: 1.0, timescale: Configuration.timeScale)
		self.__property.trimTimeRange = scaledTrimTimeRange
		self.set(rate: self.rate)
	}
	
	public mutating func set(rate: Float64) {
		self.__property.rate = rate
		if rate == 1.0 {
			self.__property.timeRange = self.trimTimeRange
		} else {
			self.__property.timeRange = CMTimeRange.convertTimeRange(timeRange: self.trimTimeRange, rate: self.rate, timescale: Configuration.timeScale)
		}
	}
	
	public mutating func set(atTime: CMTime) {
		self.__property.atTime = atTime
	}
	/*
	public mutating func setup(videoCompositionProperty: VideoCompositionProperty) throws {
	try self.__property.setup(videoCompositionProperty: videoCompositionProperty)
	}
	*/
	//private mutating func 	public var extensionData: CompositionAssetExtensionDataProtocol?
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Codable

extension CompositionAudioAssetProperty {
	enum CodingKeys: String, CodingKey {
		case id
		case create
		case update
		case dataId
		case trackId
		case avAsset
		case videoAssetTrack
		case audioAssetTrack
		case originalTimeRange
		
		case volume
		case mute
		case layers
		case atTime
		case rate
		case trimTimeRange
		case timeRange
		case fadeInTime
		case fadeOutTime
	}
}

extension CompositionAudioAssetProperty: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		try container.encode(self.create, forKey: .create)
		try container.encode(self.update, forKey: .update)
		try container.encode(self.dataId, forKey: .dataId)
		try container.encode(self.trackId, forKey: .trackId)
		try container.encode(CodableURL.init(url: self.avAsset.url), forKey: .avAsset)
		//try container.encode(self.videoAssetTrack, forKey: .videoAssetTrack)
		//try container.encode(self.audioAssetTrack, forKey: .audioAssetTrack)
		try container.encode(self.originalTimeRange, forKey: .originalTimeRange)
		try container.encode(self.volume, forKey: .volume)
		try container.encode(self.mute, forKey: .mute)
		//let a: [RenderLayerContainer] = self.layers.map { RenderLayerContainer.init(type: $0.type, customIndex: $0.customIndex, renderLayer: $0) }
		//try container.encode(a, forKey: .layers)
		//try container.encode(self.backgroundColor, forKey: .backgroundColor)
		try container.encode(self.atTime, forKey: .atTime)
		try container.encode(self.rate, forKey: .rate)
		try container.encode(self.trimTimeRange, forKey: .trimTimeRange)
		try container.encode(self.timeRange, forKey: .timeRange)
		try container.encode(self.fadeInTime, forKey: .fadeInTime)
		try container.encode(self.fadeOutTime, forKey: .fadeOutTime)
	}
}

extension CompositionAudioAssetProperty: Decodable {
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try values.decode(CompositionAudioAssetId.self, forKey: .id)
		self.create = try values.decode(Date.self, forKey: .create)
		self.update = try values.decode(Date.self, forKey: .update)
		self.dataId = try values.decode(CompositionDataId?.self, forKey: .dataId)
		self.trackId = try values.decode(CompositionAudioTrackId?.self, forKey: .trackId)
		let assetPath: CodableURL = try values.decode(CodableURL.self, forKey: .avAsset)
		self.avAsset = AVURLAsset.init(url: assetPath.url)
		self.audioAssetTrack = self.avAsset.tracks(withMediaType: AVMediaType.audio).first
		self.originalTimeRange = try values.decode(CMTimeRange.self, forKey: .originalTimeRange)
		
		self.volume = try values.decode(Float.self, forKey: .volume)
		self.mute = try values.decode(Bool.self, forKey: .mute)
		//let renderLayerContainers: [RenderLayerContainer] = try values.decode([RenderLayerContainer].self, forKey: .layers)
		//self.layers = renderLayerContainers.map { $0.renderLayer }
		self.layers = []
		self.atTime = try values.decode(CMTime.self, forKey: .atTime)
		self.rate = try values.decode(Float64.self, forKey: .rate)
		self.trimTimeRange = try values.decode(CMTimeRange.self, forKey: .trimTimeRange)
		self.timeRange = try values.decode(CMTimeRange.self, forKey: .timeRange)
		self.fadeInTime = try values.decode(TimeInterval.self, forKey: .fadeInTime)
		self.fadeOutTime = try values.decode(TimeInterval.self, forKey: .fadeOutTime)
	}
}
