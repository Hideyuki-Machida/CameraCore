//
//  CCRecorder.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/03.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation

public struct CCRecorder {
    private init() {} // このstructはnamespace用途なのでインスタンス化防止

    internal enum ErrorType: Error {
        case setup
        case render
    }
}
