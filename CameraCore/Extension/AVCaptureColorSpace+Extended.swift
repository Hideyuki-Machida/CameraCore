//
//  AVCaptureColorSpace+Extended.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/10/23.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation

extension AVCaptureColorSpace {
    var toString: String {
        switch self {
        case .sRGB: return "sRGB"
        case .P3_D65: return "P3_D65"
        @unknown default: return "sRGB"
        }
    }
}
