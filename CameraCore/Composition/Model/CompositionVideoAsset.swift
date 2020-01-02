//
//  CompositionVideoAssetTrack.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/08.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public struct CompositionVideoAsset: CompositionVideoAssetProtocol {
    public var __property: CompositionVideoAssetProperty
	public init(avAsset: AVURLAsset, volume: Float = 1.0, mute: Bool = false, rate: Float64 = 1.0, backgroundColor: UIColor = UIColor.black, layers: [RenderLayerProtocol], atTime: CMTime, trimTimeRange: CMTimeRange? = nil, contentMode: CompositionVideoAssetContentMode = .none, transform: CGAffineTransform? = nil, replacAudio: AVURLAsset? = nil) {
        
        let videoAssetTrack: AVAssetTrack? = avAsset.tracks(withMediaType: AVMediaType.video).first
		let audioAssetTrack: AVAssetTrack? = replacAudio != nil ? replacAudio!.tracks(withMediaType: AVMediaType.audio).first : avAsset.tracks(withMediaType: AVMediaType.audio).first
        let originalTimeRange: CMTimeRange = videoAssetTrack?.timeRange ?? CMTimeRange.init()
		let scaledOriginalTimeRange: CMTimeRange = CMTimeRange.convertTimeRange(timeRange: originalTimeRange, rate: 1.0, timescale: Configuration.timeScale)
        let trimTimeRange: CMTimeRange = trimTimeRange != nil ? trimTimeRange! : originalTimeRange
		let scaledTrimTimeRange: CMTimeRange = CMTimeRange.convertTimeRange(timeRange: trimTimeRange, rate: 1.0, timescale: Configuration.timeScale)

        self.__property = CompositionVideoAssetProperty.init(
            id: CompositionVideoAssetId(),
            create: Date.init(),
            update: Date.init(),
            dataId: nil,
            trackId: nil,
            avAsset: avAsset,
            videoAssetTrack: videoAssetTrack,
            audioAssetTrack: audioAssetTrack,
            originalTimeRange: scaledOriginalTimeRange,
			
            volume: volume,
            mute: mute,
            layers: layers,
            backgroundColor: backgroundColor,
            atTime: atTime,
            rate: rate,
            trimTimeRange: scaledTrimTimeRange,
            timeRange: rate == 1.0 ? scaledTrimTimeRange : CMTimeRange.convertTimeRange(timeRange: scaledTrimTimeRange, rate: rate, timescale: Configuration.timeScale),
            contentMode: contentMode,
            contentModeTransform: CGAffineTransform.identity,
			transform: transform ?? CGAffineTransform.identity,
			replacAudio: replacAudio
        )
    }
	
	public mutating func setup(videoCompositionProperty: VideoCompositionProperty) throws {
		try self.__property.setup(videoCompositionProperty: videoCompositionProperty)
	}
}


extension CompositionVideoAsset {
	enum CodingKeys: String, CodingKey {
		case __property
	}
}

extension CompositionVideoAsset: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.__property, forKey: .__property)
	}
}

extension CompositionVideoAsset: Decodable {
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.__property = try values.decode(CompositionVideoAssetProperty.self, forKey: .__property)
	}
}
