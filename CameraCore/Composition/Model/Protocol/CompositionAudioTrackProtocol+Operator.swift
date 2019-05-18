//
//  CompositionAudioTrackProtocol+Operator.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/24.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

extension CompositionAudioTrackProperty: Equatable {
	public static func == (left: CompositionAudioTrackProperty, right: CompositionAudioTrackProperty) -> Bool {
		guard
			left.id == right.id,
			left.dataId == right.dataId,
			left.compositionAudioTrack == right.compositionAudioTrack,
			//left.videoCompositionInstruction == left.videoCompositionInstruction,
			left.audioMixInputParameters == right.audioMixInputParameters
			else { return false }
		//left.assets == right.assets,
		return true
	}
	public static func != (left: CompositionAudioTrackProperty, right: CompositionAudioTrackProperty) -> Bool {
		return !(left == right)
	}
}

extension CompositionAudioTrackProtocol {
	public static func == (left: CompositionAudioTrackProtocol, right: CompositionAudioTrackProtocol) -> Bool {
		return left.__property == right.__property
	}
	public static func != (left: CompositionAudioTrackProtocol, right: CompositionAudioTrackProtocol) -> Bool {
		return left.__property != right.__property
	}
}
