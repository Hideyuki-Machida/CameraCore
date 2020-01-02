//
//  CompositionTrackProtocol+Operator.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/26.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

extension CompositionVideoTrackProperty: Equatable {
    public static func == (left: CompositionVideoTrackProperty, right: CompositionVideoTrackProperty) -> Bool {
        guard
            left.id == right.id,
            left.dataId == right.dataId,
            left.compositionVideoTrack == right.compositionVideoTrack,
            left.compositionAudioTrack == right.compositionAudioTrack,
            //left.videoCompositionInstruction == left.videoCompositionInstruction,
            left.audioMixInputParameters == right.audioMixInputParameters
            else { return false }
        //left.assets == right.assets,
        return true
    }
    public static func != (left: CompositionVideoTrackProperty, right: CompositionVideoTrackProperty) -> Bool {
        return !(left == right)
    }
}

extension CompositionVideoTrackProtocol {
    public static func == (left: CompositionVideoTrackProtocol, right: CompositionVideoTrackProtocol) -> Bool {
        return left.__property == right.__property
    }
    public static func != (left: CompositionVideoTrackProtocol, right: CompositionVideoTrackProtocol) -> Bool {
        return left.__property != right.__property
    }
}
