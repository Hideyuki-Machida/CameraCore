//
//  CompositionVideoAssetId.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/23.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

public struct CompositionVideoAssetId: Codable {
    public let key: String
    public init() {
        self.key = NSUUID().uuidString
    }
}

extension CompositionVideoAssetId: Equatable {
    public static func ==(lhs: CompositionVideoAssetId, rhs: CompositionVideoAssetId) -> Bool{
        return lhs.key == rhs.key
    }
}

extension CompositionVideoAssetId {
    public static func !=(lhs: CompositionVideoAssetId, rhs: CompositionVideoAssetId) -> Bool{
        return lhs.key != rhs.key
    }
}
