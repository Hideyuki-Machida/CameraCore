//
//  AVCaptureVideoOrientation+Extension.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/01/16.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        @unknown default:
            return .portrait
        }
    }

    init(orientation: UIInterfaceOrientation) {
        switch orientation {
        case .landscapeRight: self = .landscapeRight
        case .landscapeLeft: self = .landscapeLeft
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: self = .portrait
        }
    }
}
