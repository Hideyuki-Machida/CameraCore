//
//  CCAudio.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation

public struct CCAudio {
    private init() {} // このstructはnamespace用途なのでインスタンス化防止

    public enum ErrorType: Error {
        case setup
        case render
    }
}
