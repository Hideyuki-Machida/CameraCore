//
//  CompositionAudioAssetId.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/24.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

public struct CompositionAudioAssetId: Codable {
	public let key: String
	public init() {
		self.key = NSUUID().uuidString
	}
}

extension CompositionAudioAssetId: Equatable {
	public static func ==(lhs: CompositionAudioAssetId, rhs: CompositionAudioAssetId) -> Bool{
		return lhs.key == rhs.key
	}
}

extension CompositionAudioAssetId {
	public static func !=(lhs: CompositionAudioAssetId, rhs: CompositionAudioAssetId) -> Bool{
		return lhs.key != rhs.key
	}
}
