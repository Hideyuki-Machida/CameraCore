//
//  CompositionVideoAssetProtocol.swift
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

public struct CompositionVideoAssetProperty {
	internal fileprivate(set) var id: CompositionVideoAssetId
	internal let create: Date
	internal fileprivate(set) var update: Date
	internal fileprivate(set) var dataId: CompositionDataId?
	internal fileprivate(set) var trackId: CompositionVideoTrackId?
	internal fileprivate(set) var avAsset: AVURLAsset
	internal fileprivate(set) var videoAssetTrack: AVAssetTrack?
	internal fileprivate(set) var audioAssetTrack: AVAssetTrack?
	internal fileprivate(set) var originalTimeRange: CMTimeRange
	
	internal var volume: Float
	internal var mute: Bool
	internal var layers: [RenderLayerProtocol]
	internal var backgroundColor: UIColor
	internal var atTime: CMTime
	internal fileprivate(set) var rate: Float64
	internal fileprivate(set) var trimTimeRange: CMTimeRange
	internal fileprivate(set) var timeRange: CMTimeRange
	internal fileprivate(set) var contentMode: CompositionVideoAssetContentMode
	internal fileprivate(set) var contentModeTransform: CGAffineTransform
	internal fileprivate(set) var transform: CGAffineTransform
	internal fileprivate(set) var replacAudio: AVURLAsset?
	
	public init(
		id: CompositionVideoAssetId,
		create: Date,
		update: Date,
		dataId: CompositionDataId?,
		trackId: CompositionVideoTrackId?,
		avAsset: AVURLAsset,
		videoAssetTrack: AVAssetTrack?,
		audioAssetTrack: AVAssetTrack?,
		originalTimeRange: CMTimeRange,
		
		volume: Float,
		mute: Bool,
		layers: [RenderLayerProtocol],
		backgroundColor: UIColor,
		atTime: CMTime,
		rate: Float64,
		trimTimeRange: CMTimeRange,
		timeRange: CMTimeRange,
		contentMode: CompositionVideoAssetContentMode,
		contentModeTransform: CGAffineTransform,
		transform: CGAffineTransform,
		replacAudio: AVURLAsset?
		) {
		self.id = id
		self.create = create
		self.update = update
		self.dataId = dataId
		self.trackId = trackId
		self.avAsset = avAsset
		self.videoAssetTrack = videoAssetTrack
		self.audioAssetTrack = audioAssetTrack
		self.originalTimeRange = originalTimeRange
		
		self.volume = volume
		self.mute = mute
		self.layers = layers
		self.backgroundColor = backgroundColor
		self.atTime = atTime
		self.rate = rate
		self.trimTimeRange = trimTimeRange
		self.timeRange = timeRange
		self.contentMode = contentMode
		self.contentModeTransform = contentModeTransform
		self.transform = transform
		self.replacAudio = replacAudio
	}
	
	public mutating func setup(videoCompositionProperty: VideoCompositionProperty) throws {
		guard let videoAssetTrack: AVAssetTrack = self.videoAssetTrack else { return }

		self.contentModeTransform = self.contentMode.transform(
			videoSize: videoAssetTrack.naturalSize,
			renderSize: videoCompositionProperty.renderSize,
			transform: videoAssetTrack.preferredTransform
		)

		//self.contentModeTransform = self.contentMode.transform(videoSize: videoAssetTrack.naturalSize, renderSize: CGSize.init(w: 1280, h: 720), transform: videoAssetTrack.preferredTransform)
		//self.contentModeTransform = self.contentMode.transform(videoSize: videoAssetTrack.naturalSize, renderSize: CGSize.init(w: 720, h: 720), transform: videoAssetTrack.preferredTransform)
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionAssetProtocol

public protocol CompositionVideoAssetProtocol: Codable {
	var __property: CompositionVideoAssetProperty { get set }
	var id: CompositionVideoAssetId { get }
	var create: Date { get }
	var update: Date { get }
	var dataId: CompositionDataId? { get }
	var trackId: CompositionVideoTrackId? { get }
	var avAsset: AVURLAsset { get }
	var videoAssetTrack: AVAssetTrack? { get }
	var audioAssetTrack: AVAssetTrack? { get }
	var originalTimeRange: CMTimeRange { get }
	
	var volume: Float { set get }
	var mute: Bool { set get }
	var layers: [RenderLayerProtocol] { set get }
	var backgroundColor: UIColor { set get }
	var atTime: CMTime { get }
	var rate: Float64 { get }
	var trimTimeRange: CMTimeRange { get }
	var timeRange: CMTimeRange { get }
	var contentMode: CompositionVideoAssetContentMode { get }
	var transform: CGAffineTransform { set get }
	//var contentModeTransform: CGAffineTransform { get }
	var replacAudio: AVURLAsset? { get }
	
	
	func isValid() throws -> Bool
	
	mutating func set(trimTimeRange: CMTimeRange)
	mutating func set(rate: Float64)
	mutating func set(atTime: CMTime)
	
	mutating func set(dataId: CompositionDataId) throws
	mutating func set(trackId: CompositionVideoTrackId) throws
	
	mutating func setup(videoCompositionProperty: VideoCompositionProperty) throws
}


// MARK: - CompositionAssetProtocol Extention

extension CompositionVideoAssetProtocol {
	public var id: CompositionVideoAssetId { get { return self.__property.id } }
	public var create: Date { get { return self.__property.create } }
	public var update: Date { get { return self.__property.update } }
	public var dataId: CompositionDataId? { get { return self.__property.dataId } }
	public var trackId: CompositionVideoTrackId? { get { return self.__property.trackId } }
	public var avAsset: AVURLAsset { get { return self.__property.avAsset } }
	public var videoAssetTrack: AVAssetTrack? { get { return self.__property.videoAssetTrack } }
	public var audioAssetTrack: AVAssetTrack? { get { return self.__property.audioAssetTrack } }
	public var originalTimeRange: CMTimeRange { get { return self.__property.originalTimeRange } }
	
	public var volume: Float { get { return self.__property.volume } set { self.__property.volume = newValue } }
	public var mute: Bool { get { return self.__property.mute } set { self.__property.mute = newValue } }
	public var layers: [RenderLayerProtocol] { get { return self.__property.layers } set { self.__property.layers = newValue } }
	public var backgroundColor: UIColor { get { return self.__property.backgroundColor } set { self.__property.backgroundColor = newValue } }
	public var atTime: CMTime { get { return self.__property.atTime } }
	public var rate: Float64 { get { return self.__property.rate } }
	public var trimTimeRange: CMTimeRange { get { return self.__property.trimTimeRange } }
	public var timeRange: CMTimeRange { get { return self.__property.timeRange } }
	public var contentMode: CompositionVideoAssetContentMode { get { return self.__property.contentMode } }
	public var contentModeTransform: CGAffineTransform { get { return self.__property.contentModeTransform } }
	public var transform: CGAffineTransform { get { return self.__property.transform } set { self.__property.transform = newValue } }
	public var replacAudio: AVURLAsset? { get { return self.__property.replacAudio } }
}

extension CompositionVideoAssetProtocol {
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

extension CompositionVideoAssetProtocol {
	public mutating func set(dataId: CompositionDataId) {
		self.__property.dataId = dataId
	}
	
	public mutating func set(trackId: CompositionVideoTrackId) {
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
	
	public mutating func set(replacAudio: AVURLAsset?) throws {
		self.__property.replacAudio = replacAudio
		let audioAssetTrack: AVAssetTrack? = replacAudio != nil ? replacAudio!.tracks(withMediaType: AVMediaType.audio).first : avAsset.tracks(withMediaType: AVMediaType.audio).first
		self.__property.audioAssetTrack = audioAssetTrack
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

extension CompositionVideoAssetProperty {
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
		case backgroundColor
		case atTime
		case rate
		case trimTimeRange
		case timeRange
		case contentMode
		case contentModeTransform
		case transform
		
		case replacAudio
	}
}

extension CompositionVideoAssetProperty: Encodable {
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
		try container.encode(self.contentMode, forKey: .contentMode)
		try container.encode(self.transform, forKey: .transform)
		//try container.encode(self.contentModeTransform, forKey: .contentModeTransform)
		
		if let replacAudio: AVURLAsset = self.replacAudio {
			try container.encode(CodableURL.init(url: replacAudio.url), forKey: .replacAudio)
		}
	}
}

extension CompositionVideoAssetProperty: Decodable {
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try values.decode(CompositionVideoAssetId.self, forKey: .id)
		self.create = try values.decode(Date.self, forKey: .create)
		self.update = try values.decode(Date.self, forKey: .update)
		self.dataId = try values.decode(CompositionDataId?.self, forKey: .dataId)
		self.trackId = try values.decode(CompositionVideoTrackId?.self, forKey: .trackId)
		let assetPath: CodableURL = try values.decode(CodableURL.self, forKey: .avAsset)
		self.avAsset = AVURLAsset.init(url: assetPath.url)
		self.videoAssetTrack = self.avAsset.tracks(withMediaType: AVMediaType.video).first
		self.audioAssetTrack = self.avAsset.tracks(withMediaType: AVMediaType.audio).first
		self.originalTimeRange = try values.decode(CMTimeRange.self, forKey: .originalTimeRange)
		
		self.volume = try values.decode(Float.self, forKey: .volume)
		self.mute = try values.decode(Bool.self, forKey: .mute)
		//let renderLayerContainers: [RenderLayerContainer] = try values.decode([RenderLayerContainer].self, forKey: .layers)
		//self.layers = renderLayerContainers.map { $0.renderLayer }
		self.layers = []
		self.backgroundColor = UIColor.black
		self.atTime = try values.decode(CMTime.self, forKey: .atTime)
		self.rate = try values.decode(Float64.self, forKey: .rate)
		self.trimTimeRange = try values.decode(CMTimeRange.self, forKey: .trimTimeRange)
		self.timeRange = try values.decode(CMTimeRange.self, forKey: .timeRange)
		self.contentMode = try values.decode(CompositionVideoAssetContentMode.self, forKey: .contentMode)
		self.transform = try values.decode(CGAffineTransform.self, forKey: .transform)
		self.contentModeTransform = CGAffineTransform.identity
		
		do {
			let replacAudioPath: CodableURL = try values.decode(CodableURL.self, forKey: .replacAudio)
			self.replacAudio = AVURLAsset.init(url: replacAudioPath.url)
			guard let replacAudio: AVURLAsset = self.replacAudio else { return }
			guard let autioTrack: AVAssetTrack = replacAudio.tracks(withMediaType: AVMediaType.audio).first else { return }
			self.audioAssetTrack = autioTrack
		} catch {
			
		}
	}
}
