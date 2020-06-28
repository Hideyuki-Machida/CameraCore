//
//  CCImageProcessing.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/01.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation

public struct CCImageProcess {
    private init() {} // このstructはnamespace用途なのでインスタンス化防止
    
    public enum ErrorType: Error {
        case setup
        case process
        case render
    }
}
