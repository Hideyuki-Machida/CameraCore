
//
//  RendererNameSpace.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/01/09.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation

public struct CCRenderer {
    public enum ErrorType: Error {
        case deviceFormat
        case rendering
    }
    public struct VideoCapture {}
    public struct ARRenderer {}
}
