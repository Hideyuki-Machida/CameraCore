//
//  CCCapture.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/12/31.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation

public struct CCCapture {
    private init() {} // このstructはnamespace用途なのでインスタンス化防止

    internal enum ErrorType: Error {
        case setup
        case render
    }
}
