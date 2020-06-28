//
//  UIInterfaceOrientation+Extension.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit

public extension UIInterfaceOrientation {
    var toAVCaptureVideoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .unknown: return nil
        case .portrait: return AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown: return AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft: return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight: return AVCaptureVideoOrientation.landscapeRight
        @unknown default:
            return nil
        }
    }
}
