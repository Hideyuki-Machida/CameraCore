//
//  RenderLayerId.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/08/25.
//  Copyright © 2018年 町田 秀行. All rights reserved.
//

import Foundation

public extension CCImageProcess {
    struct RenderLayerId: Codable {
        public let key: String
        public init() {
            self.key = NSUUID().uuidString
        }
    }
}

extension CCImageProcess.RenderLayerId: Equatable {
    public static func ==(lhs: CCImageProcess.RenderLayerId, rhs: CCImageProcess.RenderLayerId) -> Bool{
        return lhs.key == rhs.key
    }
}

extension CCImageProcess.RenderLayerId {
    public static func !=(lhs: CCImageProcess.RenderLayerId, rhs: CCImageProcess.RenderLayerId) -> Bool{
        return lhs.key != rhs.key
    }
}
