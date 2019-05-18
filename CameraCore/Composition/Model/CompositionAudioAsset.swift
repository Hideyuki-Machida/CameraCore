//
//  CompositionAudioAsset.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/18.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public struct CompositionAudioAsset: CompositionAudioAssetProtocol {
    public var __property: CompositionAudioAssetProperty
	public init(avAsset: AVURLAsset, volume: Float = 1.0, mute: Bool = false, rate: Float64 = 1.0, atTime: CMTime, trimTimeRange: CMTimeRange? = nil, fadeInTime: TimeInterval = 0.0, fadeOutTime: TimeInterval = 0.0) {
        
        let audioAssetTrack: AVAssetTrack? = avAsset.tracks(withMediaType: AVMediaType.audio).first
        let originalTimeRange: CMTimeRange = audioAssetTrack?.timeRange ?? CMTimeRange.init()
		let scaledOriginalTimeRange: CMTimeRange = CMTimeRange.convertTimeRange(timeRange: originalTimeRange, rate: 1.0, timescale: Configuration.timeScale)
        let trimTimeRange: CMTimeRange = trimTimeRange != nil ? trimTimeRange! : originalTimeRange
		let scaledTrimTimeRange: CMTimeRange = CMTimeRange.convertTimeRange(timeRange: trimTimeRange, rate: 1.0, timescale: Configuration.timeScale)
		
        self.__property = CompositionAudioAssetProperty.init(
            id: CompositionAudioAssetId(),
            create: Date.init(),
            update: Date.init(),
            dataId: nil,
            trackId: nil,
            avAsset: avAsset,
            audioAssetTrack: audioAssetTrack,
            originalTimeRange: scaledOriginalTimeRange,
            volume: volume,
            mute: mute,
            layers: [],
            atTime: atTime,
            rate: rate,
            trimTimeRange: scaledTrimTimeRange,
            timeRange: rate == 1.0 ? scaledTrimTimeRange : CMTimeRange.convertTimeRange(timeRange: scaledTrimTimeRange, rate: rate, timescale: Configuration.timeScale),
			fadeInTime: fadeInTime,
			fadeOutTime: fadeOutTime
        )
    }
	
	public mutating func setup(videoCompositionProperty: VideoCompositionProperty) throws {
		try self.__property.setup(videoCompositionProperty: videoCompositionProperty)
	}
}

extension CompositionAudioAsset {
	enum CodingKeys: String, CodingKey {
		case __property
	}
}

extension CompositionAudioAsset: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.__property, forKey: .__property)
	}
}

extension CompositionAudioAsset: Decodable {
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.__property = try values.decode(CompositionAudioAssetProperty.self, forKey: .__property)
	}
}
