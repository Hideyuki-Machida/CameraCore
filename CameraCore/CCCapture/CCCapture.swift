//
//  CCCapture.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/12/31.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation

public struct CCCapture {
    static let videoOutputQueue: DispatchQueue = DispatchQueue(label: "CCCapture.videoOutputQueue")
    static let audioOutputQueue: DispatchQueue = DispatchQueue(label: "CCCapture.audioOutputQueue")
    static let depthOutputQueue: DispatchQueue = DispatchQueue(label: "CCCapture.depthOutputQueue")

    private init() {} // このstructはnamespace用途なのでインスタンス化防止

    internal enum ErrorType: Error {
        case setup
        case render
    }
}
