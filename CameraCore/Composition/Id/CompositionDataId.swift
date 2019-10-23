//
//  CompositionDataId.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/23.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

public struct CompositionDataId: Codable {
    public let key: String
    public init() {
        self.key = NSUUID().uuidString
    }
}

extension CompositionDataId: Equatable {
    public static func ==(lhs: CompositionDataId, rhs: CompositionDataId) -> Bool{
        return lhs.key == rhs.key
    }
}

extension CompositionDataId {
    public static func !=(lhs: CompositionDataId, rhs: CompositionDataId) -> Bool{
        return lhs.key != rhs.key
    }
}
