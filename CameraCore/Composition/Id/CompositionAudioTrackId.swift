//
//  CompositionAudioTrackId.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/24.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

public struct CompositionAudioTrackId: Codable {
	public let key: String
	public init() {
		self.key = NSUUID().uuidString
	}
}

extension CompositionAudioTrackId: Equatable {
	public static func ==(lhs: CompositionAudioTrackId, rhs: CompositionAudioTrackId) -> Bool{
		return lhs.key == rhs.key
	}
}

extension CompositionAudioTrackId {
	public static func !=(lhs: CompositionAudioTrackId, rhs: CompositionAudioTrackId) -> Bool{
		return lhs.key != rhs.key
	}
}
