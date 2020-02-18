//
//  CCRenderer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/01/09.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation

public struct CCRenderer {
    private init() {} // このstructはnamespace用途なのでインスタンス化防止

    internal enum ErrorType: Error {
        case setup
        case render
    }
}
