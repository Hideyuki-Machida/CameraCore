//
//  RenderLayerId.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/08/25.
//  Copyright © 2018年 町田 秀行. All rights reserved.
//

import Foundation

public struct RenderLayerId: Codable {
    public let key: String
    public init() {
        self.key = NSUUID().uuidString
    }
}

extension RenderLayerId: Equatable {
    public static func ==(lhs: RenderLayerId, rhs: RenderLayerId) -> Bool{
        return lhs.key == rhs.key
    }
}

extension RenderLayerId {
    public static func !=(lhs: RenderLayerId, rhs: RenderLayerId) -> Bool{
        return lhs.key != rhs.key
    }
}
