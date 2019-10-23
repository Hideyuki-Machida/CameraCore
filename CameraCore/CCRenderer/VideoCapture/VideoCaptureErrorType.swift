//
//  VideoCaptureErrorType.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/10/20.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation

extension CCRenderer.VideoCapture {
    public enum ErrorType: Error {
        case setupError
        case render
    }
}
