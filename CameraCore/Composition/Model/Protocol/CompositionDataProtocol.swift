//
//  CompositionDataProtocol.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/08/21.
//  Copyright © 2018年 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionDataProperty

internal enum CompositionDataError: Error {
    case setupError
    case dataError
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionDataProperty

public struct CompositionDataProperty {
    internal let id: CompositionDataId
    internal let create: Date
    internal fileprivate(set) var update: Date
    internal fileprivate(set) var videoTracks: [CompositionVideoTrackProtocol]
    internal fileprivate(set) var audioTracks: [CompositionAudioTrackProtocol]
    internal fileprivate(set) var property: VideoCompositionProperty
    internal fileprivate(set) var composition: AVMutableComposition = AVMutableComposition()
    internal fileprivate(set) var videoComposition: AVMutableVideoComposition?
    internal fileprivate(set) var audioMix: AVMutableAudioMix = AVMutableAudioMix()
    
	public init(videoTracks: [CompositionVideoTrackProtocol], audioTracks: [CompositionAudioTrackProtocol], property: VideoCompositionProperty) {
		self.init(id: CompositionDataId(), videoTracks: videoTracks, audioTracks: audioTracks, property: property)
    }
    
    public init(id: CompositionDataId, videoTracks: [CompositionVideoTrackProtocol], audioTracks: [CompositionAudioTrackProtocol], property: VideoCompositionProperty) {
        self.id = id
        self.videoTracks = videoTracks
        self.audioTracks = audioTracks
        self.property = property
        self.create = Date.init()
        self.update = Date.init()
        
		for (index, _) in self.videoTracks.enumerated() {
			do {
				try self.videoTracks[index].set(dataId: self.id)
			} catch {
				
			}
		}
		for (index, _) in self.audioTracks.enumerated() {
			do {
				try self.audioTracks[index].set(dataId: self.id)
			} catch {
				
			}
		}
    }
	
	public init(id: CompositionDataId, videoTracks: [CompositionVideoTrackProtocol], audioTracks: [CompositionAudioTrackProtocol], property: VideoCompositionProperty, create: Date, update: Date) {
		self.id = id
		self.videoTracks = videoTracks
		self.audioTracks = audioTracks
		self.property = property
		self.create = create
		self.update = update
		
		for (index, _) in self.videoTracks.enumerated() {
			do {
				try self.videoTracks[index].set(dataId: self.id)
			} catch {
				
			}
		}
		for (index, _) in self.audioTracks.enumerated() {
			do {
				try self.audioTracks[index].set(dataId: self.id)
			} catch {
				
			}
		}
	}
}

extension CompositionDataProperty {
    internal mutating func add(track: CompositionVideoTrackProtocol) throws {
        var track = track
        try track.set(dataId: id)
        self.videoTracks.append(track)
        self.update = Date.init()
    }
    public mutating func add(trackId: CompositionVideoTrackId, asset: CompositionVideoAssetProtocol) throws {
        for (index, _) in self.videoTracks.enumerated() {
            if self.videoTracks[index].id == trackId {
                try self.videoTracks[index].add(asset: asset)
            }
        }
        self.update = Date.init()
    }
    public func get(trackId: CompositionVideoTrackId) -> CompositionVideoTrackProtocol? {
        return (self.videoTracks.filter { $0.id == trackId }).first
    }
    public func get(assetId: CompositionVideoAssetId) throws -> CompositionVideoAssetProtocol {
        for (index, _) in self.videoTracks.enumerated() {
            if let asset = self.videoTracks[index].get(assetId: assetId) {
                return asset
            }
        }
		throw CompositionDataError.dataError
    }
    public mutating func updatet(track: CompositionVideoTrackProtocol) throws {
        for (index, _) in self.videoTracks.enumerated() {
            if self.videoTracks[index].id == track.id {
                self.videoTracks[index] = track
                self.update = Date.init()
                return
            }
        }
    }
    public mutating func updatet(asset: CompositionVideoAssetProtocol) throws {
        for (index, _) in self.videoTracks.enumerated() {
            do {
                try self.videoTracks[index].updatet(asset: asset)
                self.update = Date.init()
            } catch {
            }
        }
    }
    public mutating func remove(trackId: CompositionVideoTrackId) throws {
        for (index, _) in self.videoTracks.enumerated() {
            if self.videoTracks[index].id == trackId {
                self.videoTracks.remove(at: index)
                self.update = Date.init()
            }
        }
    }
    public mutating func remove(assetId: CompositionVideoAssetId) throws {
        for (index, _) in self.videoTracks.enumerated() {
            do {
                try self.videoTracks[index].remove(assetId: assetId)
                self.update = Date.init()
            } catch {
            }
        }
    }
	public mutating func removeAssets(trackId: CompositionVideoTrackId) throws {
		for (index, _) in self.videoTracks.enumerated() {
			if self.videoTracks[index].id == trackId {
				try self.videoTracks[index].removeAllAssets()
			}
		}
        self.update = Date.init()
	}
	public mutating func fit() {
        for (index, _) in self.videoTracks.enumerated() {
            self.videoTracks[index].fit()
            self.update = Date.init()
        }
    }

	public func isEmpty() -> Bool {
		for (index, _) in self.videoTracks.enumerated() {
			if !self.videoTracks[index].isEmpty {
				return false
			}
		}
		return true
	}
	
	public mutating func swap(trackId: CompositionVideoTrackId, at: CompositionVideoAssetId, to: CompositionVideoAssetId) throws {
		var isSwap: Bool = false
		for (index, _) in self.videoTracks.enumerated() {
			if self.videoTracks[index].id == trackId {
				try self.videoTracks[index].swap(at: at, to: to)
				isSwap = true
			}
		}
		guard isSwap == true else {
            self.update = Date.init()
			throw CompositionDataError.dataError
		}
	}
}

extension CompositionDataProperty {
	internal mutating func add(track: CompositionAudioTrackProtocol) throws {
		var track = track
		try track.set(dataId: id)
		self.audioTracks.append(track)
		self.update = Date.init()
	}
	public mutating func add(trackId: CompositionAudioTrackId, asset: CompositionAudioAssetProtocol) throws {
		for (index, _) in self.videoTracks.enumerated() {
			if self.audioTracks[index].id == trackId {
				try self.audioTracks[index].add(asset: asset)
			}
		}
		self.update = Date.init()
	}
	public func get(trackId: CompositionAudioTrackId) -> CompositionAudioTrackProtocol? {
		return (self.audioTracks.filter { $0.id == trackId }).first
	}
	public func get(assetId: CompositionAudioAssetId) throws -> CompositionAudioAssetProtocol {
		for (index, _) in self.audioTracks.enumerated() {
			if let asset = self.audioTracks[index].get(assetId: assetId) {
				return asset
			}
		}
		throw CompositionDataError.dataError
	}
	public mutating func updatet(track: CompositionAudioTrackProtocol) throws {
		for (index, _) in self.audioTracks.enumerated() {
			if self.audioTracks[index].id == track.id {
				self.audioTracks[index] = track
				self.update = Date.init()
				return
			}
		}
	}
	public mutating func updatet(asset: CompositionAudioAssetProtocol) throws {
		for (index, _) in self.audioTracks.enumerated() {
			do {
				try self.audioTracks[index].updatet(asset: asset)
				self.update = Date.init()
			} catch {
			}
		}
	}
	public mutating func remove(trackId: CompositionAudioTrackId) throws {
		for (index, _) in self.audioTracks.enumerated() {
			if self.audioTracks[index].id == trackId {
				self.audioTracks.remove(at: index)
				self.update = Date.init()
			}
		}
	}
	public mutating func remove(assetId: CompositionAudioAssetId) throws {
		for (index, _) in self.audioTracks.enumerated() {
			do {
				try self.audioTracks[index].remove(assetId: assetId)
				self.update = Date.init()
			} catch {
			}
		}
	}
	public mutating func removeAssets(trackId: CompositionAudioTrackId) throws {
		for (index, _) in self.audioTracks.enumerated() {
			if self.audioTracks[index].id == trackId {
				try self.audioTracks[index].removeAllAssets()
			}
		}
		self.update = Date.init()
	}
	public mutating func swap(trackId: CompositionAudioTrackId, at: CompositionAudioAssetId, to: CompositionAudioAssetId) throws {
		var isSwap: Bool = false
		for (index, _) in self.audioTracks.enumerated() {
			if self.audioTracks[index].id == trackId {
				try self.audioTracks[index].swap(at: at, to: to)
				isSwap = true
			}
		}
		guard isSwap == true else {
			throw CompositionDataError.dataError
		}
		self.update = Date.init()
	}
}


extension CompositionDataProperty {
    /// setup: Video & Audio
    public mutating func setup(property: VideoCompositionProperty) throws {
		self.property = property
		try self.setup()
	}
	
	public mutating func setup() throws {
        do {
            self.audioMix.inputParameters = []
            var composition: AVMutableComposition = AVMutableComposition()
            var instructions: [AVVideoCompositionInstructionProtocol] = []
            for (index, _) in self.videoTracks.enumerated() {
                //if track.assets.count > 0 {
					var track: CompositionVideoTrackProtocol = self.videoTracks[index]
					try track.setup(composition: &composition, dataId: self.id, videoCompositionProperty: &self.property)
					self.videoTracks[index] = track
                    if let videoCompositionInstruction = self.videoTracks[index].videoCompositionInstruction {
                        instructions = instructions + videoCompositionInstruction
                    }
                    if let audioMixInputParameters = self.videoTracks[index].audioMixInputParameters {
                        self.audioMix.inputParameters.append(audioMixInputParameters)
                    }
                //}
            }

			for (index, _) in self.audioTracks.enumerated() {
				//if track.assets.count > 0 {
					var track: CompositionAudioTrackProtocol = self.audioTracks[index]
					try track.setup(composition: &composition, dataId: self.id, videoCompositionProperty: self.property)
					self.audioTracks[index] = track
					if let audioMixInputParameters = self.audioTracks[index].audioMixInputParameters {
						self.audioMix.inputParameters.append(audioMixInputParameters)
					}
				//}
			}

            if instructions.count > 0 {
                // VideoComposition 設定
                self.videoComposition = AVMutableVideoComposition()
				self.videoComposition?.frameDuration = CMTimeMake(value: 1, timescale: self.property.frameRate)
                self.videoComposition?.renderScale = self.property.renderScale
                self.videoComposition?.renderSize = self.property.renderSize
                self.videoComposition?.instructions = instructions
				switch self.property.renderType {
				case .openGL, .metal:
					self.videoComposition?.customVideoCompositorClass = MetalVideoRenderLayerCompositing.self
				}
            }
            self.composition = composition
        } catch {
            throw CompositionDataError.setupError
        }
    }
    
    public mutating func updateRenderLayer() throws {
        do {
            var instructions: [AVVideoCompositionInstructionProtocol] = []
            for (index, track) in self.videoTracks.enumerated() {
                if track.assets.count > 0 {
                    if let videoCompositionInstruction = self.videoTracks[index].videoCompositionInstruction {
                        instructions = instructions + videoCompositionInstruction
                    }
                }
            }
			
            if instructions.count > 0 {
                // VideoComposition 設定
                self.videoComposition = AVMutableVideoComposition()
				self.videoComposition?.frameDuration = CMTimeMake(value: 1, timescale: self.property.frameRate)
                self.videoComposition?.renderScale = self.property.renderScale
				self.videoComposition?.renderSize = self.property.renderSize
                self.videoComposition?.instructions = instructions
				switch self.property.renderType {
				case .openGL, .metal:
					self.videoComposition?.customVideoCompositorClass = MetalVideoRenderLayerCompositing.self
				}
            } else {
                throw CompositionDataError.setupError
            }
        } catch {
            throw CompositionDataError.setupError
        }
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - CompositionDataProtocol

public protocol CompositionDataProtocol: Codable {
    var __property: CompositionDataProperty { get set }
    var id: CompositionDataId { get }
    var create: Date { get }
    var update: Date { get }
    var videoTracks: [CompositionVideoTrackProtocol] { get }
    var audioTracks: [CompositionAudioTrackProtocol] { get }
    var property: VideoCompositionProperty { get }
    var composition: AVMutableComposition { get }
    var videoComposition: AVMutableVideoComposition? { get }
    var audioMix: AVMutableAudioMix { get }
    init(to: CompositionDataProperty)

	var isEmpty: Bool { get }

    mutating func setup(property: VideoCompositionProperty) throws
	mutating func setup() throws
    mutating func updateRenderLayer() throws
    
    mutating func add(track: CompositionVideoTrackProtocol) throws
    mutating func add(track: CompositionAudioTrackProtocol) throws
    mutating func add(trackId: CompositionVideoTrackId, asset: CompositionVideoAssetProtocol) throws
    mutating func add(trackId: CompositionAudioTrackId, asset: CompositionAudioAssetProtocol) throws
    func get(trackId: CompositionVideoTrackId) -> CompositionVideoTrackProtocol?
    func get(assetId: CompositionVideoAssetId) throws -> CompositionVideoAssetProtocol
    mutating func updatet(track: CompositionVideoTrackProtocol) throws
    mutating func updatet(asset: CompositionVideoAssetProtocol) throws
    mutating func remove(trackId: CompositionVideoTrackId) throws
    mutating func remove(assetId: CompositionVideoAssetId) throws
	func get(trackId: CompositionAudioTrackId) -> CompositionAudioTrackProtocol?
	func get(assetId: CompositionAudioAssetId) throws -> CompositionAudioAssetProtocol
	mutating func updatet(track: CompositionAudioTrackProtocol) throws
	mutating func updatet(asset: CompositionAudioAssetProtocol) throws
	mutating func remove(trackId: CompositionAudioTrackId) throws
	mutating func remove(assetId: CompositionAudioAssetId) throws
    mutating func fit()
	
    func duplicate() throws -> CompositionDataProtocol
}


// MARK: - CompositionDataProtocol Extention

extension CompositionDataProtocol {
    public var id: CompositionDataId { get { return self.__property.id } }
    public var create: Date { get { return self.__property.create } }
    public var update: Date { get { return self.__property.update } }
    public var videoTracks: [CompositionVideoTrackProtocol] { get { return self.__property.videoTracks } }
    public var audioTracks: [CompositionAudioTrackProtocol] { get { return self.__property.audioTracks } }
    public var property: VideoCompositionProperty { get { return self.__property.property } }
    public var composition: AVMutableComposition { get { return self.__property.composition } }
    public var videoComposition: AVMutableVideoComposition? { get { return self.__property.videoComposition } }
    public var audioMix: AVMutableAudioMix { get { return self.__property.audioMix } }
	
	public var isEmpty: Bool { get { return self.__property.isEmpty() } }
}

extension CompositionDataProtocol {
	/// setup: Video & Audio
	public mutating func setup(property: VideoCompositionProperty) throws {
		try self.__property.setup(property: property)
	}

	public mutating func setup() throws {
		try self.__property.setup()
	}
	
	public mutating func updateRenderLayer() throws {
		try self.__property.updateRenderLayer()
	}
	
	public func duplicate() throws -> CompositionDataProtocol {
		let property: CompositionDataProperty = CompositionDataProperty.init(
			id: CompositionDataId(),
			videoTracks: self.__property.videoTracks,
			audioTracks: self.__property.audioTracks,
			property: self.__property.property
		)
		return CompositionData.init(to: property)
	}
}



extension CompositionDataProtocol {
	public mutating func add(track: CompositionVideoTrackProtocol) throws {
		try self.__property.add(track: track)
	}
	public mutating func add(trackId: CompositionVideoTrackId, asset: CompositionVideoAssetProtocol) throws {
		try self.__property.add(trackId: trackId, asset: asset)
	}
	public func get(trackId: CompositionVideoTrackId) -> CompositionVideoTrackProtocol? {
		return self.__property.get(trackId: trackId)
	}
	public func get(assetId: CompositionVideoAssetId) throws -> CompositionVideoAssetProtocol {
		return try self.__property.get(assetId: assetId)
	}
	public mutating func updatet(track: CompositionVideoTrackProtocol) throws {
		try self.__property.updatet(track: track)
	}
	public mutating func updatet(asset: CompositionVideoAssetProtocol) throws {
		try self.__property.updatet(asset: asset)
	}
	public mutating func remove(trackId: CompositionVideoTrackId) throws {
		try self.__property.remove(trackId: trackId)
	}
	public mutating func remove(assetId: CompositionVideoAssetId) throws {
		try self.__property.remove(assetId: assetId)
	}
	public mutating func removeAssets(trackId: CompositionVideoTrackId) throws {
		try self.__property.removeAssets(trackId: trackId)
	}
	public mutating func fit() {
		self.__property.fit()
	}
	public mutating func swap(trackId: CompositionVideoTrackId, at: CompositionVideoAssetId, to: CompositionVideoAssetId) throws {
		try self.__property.swap(trackId: trackId, at: at, to: to)
	}
}

extension CompositionDataProtocol {
	public mutating func add(track: CompositionAudioTrackProtocol) throws {
		try self.__property.add(track: track)
	}
	public mutating func add(trackId: CompositionAudioTrackId, asset: CompositionAudioAssetProtocol) throws {
		try self.__property.add(trackId: trackId, asset: asset)
	}
	public func get(trackId: CompositionAudioTrackId) -> CompositionAudioTrackProtocol? {
		return self.__property.get(trackId: trackId)
	}
	public func get(assetId: CompositionAudioAssetId) throws -> CompositionAudioAssetProtocol {
		return try self.__property.get(assetId: assetId)
	}
	public mutating func updatet(track: CompositionAudioTrackProtocol) throws {
		try self.__property.updatet(track: track)
	}
	public mutating func updatet(asset: CompositionAudioAssetProtocol) throws {
		try self.__property.updatet(asset: asset)
	}
	public mutating func remove(trackId: CompositionAudioTrackId) throws {
		try self.__property.remove(trackId: trackId)
	}
	public mutating func remove(assetId: CompositionAudioAssetId) throws {
		try self.__property.remove(assetId: assetId)
	}
	public mutating func removeAssets(trackId: CompositionAudioTrackId) throws {
		try self.__property.removeAssets(trackId: trackId)
	}
	public mutating func swap(trackId: CompositionAudioTrackId, at: CompositionAudioAssetId, to: CompositionAudioAssetId) throws {
		try self.__property.swap(trackId: trackId, at: at, to: to)
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Codable

extension CompositionDataProperty {
    enum CodingKeys: String, CodingKey {
        case id
        case create
        case update
        case videoTracks
        case audioTracks
        case property
    }
}

extension CompositionDataProperty: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.create, forKey: .create)
        try container.encode(self.update, forKey: .update)
		if let a: [CompositionVideoTrack] = self.videoTracks as? [CompositionVideoTrack] {
			try container.encode(a, forKey: .videoTracks)
		}
		if let a: [CompositionAudioTrack] = self.audioTracks as? [CompositionAudioTrack] {
			try container.encode(a, forKey: .audioTracks)
		}
        try container.encode(self.property, forKey: .property)
    }
}

extension CompositionDataProperty: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(CompositionDataId.self, forKey: .id)
        self.create = try values.decode(Date.self, forKey: .create)
        self.update = try values.decode(Date.self, forKey: .update)
		do {
			self.videoTracks = try values.decode([CompositionVideoTrack].self, forKey: .videoTracks)
        	self.audioTracks = try values.decode([CompositionAudioTrack].self, forKey: .audioTracks)
		} catch {
			self.videoTracks = []
			self.audioTracks = []
		}
        self.property = try values.decode(VideoCompositionProperty.self, forKey: .property)
    }
}
