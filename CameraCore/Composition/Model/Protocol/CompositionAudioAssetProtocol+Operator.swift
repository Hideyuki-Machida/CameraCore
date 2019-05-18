//
//  CompositionAudioAssetProtocol+Operator.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/24.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

extension CompositionAudioAssetProperty: Equatable {
	public static func == (left: CompositionAudioAssetProperty, right: CompositionAudioAssetProperty) -> Bool {
		guard
			left.id == right.id,
			left.dataId == right.dataId,
			left.trackId == right.trackId,
			left.avAsset == right.avAsset,
			left.audioAssetTrack == right.audioAssetTrack,
			left.originalTimeRange == right.originalTimeRange,
			left.volume == right.volume,
			left.mute == right.mute,
			//left.layers == right.layers,
			left.atTime == right.atTime,
			left.rate == right.rate,
			left.trimTimeRange == right.trimTimeRange,
			left.timeRange == right.timeRange
			else { return false }
		return true
	}
	public static func != (left: CompositionAudioAssetProperty, right: CompositionAudioAssetProperty) -> Bool {
		return !(left == right)
	}
}

extension CompositionAudioAssetProtocol {
	public static func == (left: CompositionAudioAssetProtocol, right: CompositionAudioAssetProtocol) -> Bool {
		return left.__property == right.__property
	}
	public static func != (left: CompositionAudioAssetProtocol, right: CompositionAudioAssetProtocol) -> Bool {
		return left.__property != right.__property
	}
}
