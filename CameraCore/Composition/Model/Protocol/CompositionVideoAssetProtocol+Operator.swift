//
//  CompositionAssetProtocol+Operator.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/26.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

extension CompositionVideoAssetProperty: Equatable {
    public static func == (left: CompositionVideoAssetProperty, right: CompositionVideoAssetProperty) -> Bool {
        guard
            left.id == right.id,
            left.dataId == right.dataId,
            left.trackId == right.trackId,
            left.avAsset == right.avAsset,
            left.videoAssetTrack == right.videoAssetTrack,
            left.audioAssetTrack == right.audioAssetTrack,
            left.originalTimeRange == right.originalTimeRange,
            left.volume == right.volume,
            left.mute == right.mute,
            //left.layers == right.layers,
            left.backgroundColor == right.backgroundColor,
            left.atTime == right.atTime,
            left.rate == right.rate,
            left.trimTimeRange == right.trimTimeRange,
            left.timeRange == right.timeRange
            else { return false }
        return true
    }
    public static func != (left: CompositionVideoAssetProperty, right: CompositionVideoAssetProperty) -> Bool {
        return !(left == right)
    }
}

extension CompositionVideoAssetProtocol {
    public static func == (left: CompositionVideoAssetProtocol, right: CompositionVideoAssetProtocol) -> Bool {
        return left.__property == right.__property
    }
    public static func != (left: CompositionVideoAssetProtocol, right: CompositionVideoAssetProtocol) -> Bool {
        return left.__property != right.__property
    }
}
