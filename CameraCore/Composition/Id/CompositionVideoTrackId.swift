//
//  CompositionVideoTrackId.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/23.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

public struct CompositionVideoTrackId: Codable {
    public let key: String
    public init() {
        self.key = NSUUID().uuidString
    }
}

extension CompositionVideoTrackId: Equatable {
    public static func ==(lhs: CompositionVideoTrackId, rhs: CompositionVideoTrackId) -> Bool{
        return lhs.key == rhs.key
    }
}

extension CompositionVideoTrackId {
    public static func !=(lhs: CompositionVideoTrackId, rhs: CompositionVideoTrackId) -> Bool{
        return lhs.key != rhs.key
    }
}
