//
//  Configuration.swift
//  CameraCore
//
//  Created by machidahideyuki on 2018/01/08.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import UIKit
import AVFoundation
import Foundation
import MetalCanvas
import ProcessLogger_Swift

public class Configuration {
    public static let shared: CameraCore.Configuration = CameraCore.Configuration()

    public let isMetalCanvas: Bool = MCCore.isMetalCanvas
    public private(set) var currentUIInterfaceOrientation: UIInterfaceOrientation = .portrait

    @objc func orientationChange() {
        DispatchQueue.main.async { [weak self] in
            // UIApplication.shared.statusBarOrientation.toAVCaptureVideoOrientation はメインスレッドからしか呼べない
            self?.currentUIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        }
    }

    // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange について
    // http://kentaroid.com/kcvpixelformattype%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6%E3%81%AE%E8%80%83%E5%AF%9F/
    public let sourcePixelBufferPixelFormatTypeKey: OSType = kCVPixelFormatType_32BGRA
    public let outputPixelBufferPixelFormatTypeKey: OSType = kCVPixelFormatType_32BGRA

    public let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()

    public let defaultUIInterfaceOrientation: UIInterfaceOrientation = .portrait
    public let defaultAVCaptureVideoOrientation: AVCaptureVideoOrientation = .portrait
    public let defaultDeviceFormatVideoOrientation: AVCaptureVideoOrientation = .landscapeRight

    public init() {
        self.orientationChange()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        ProcessLogger.deinitLog(self)
    }
}

public func configure() throws {
    Configuration.shared.orientationChange()
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    try MCCore.setup(contextOptions: [
        CIContextOption.workingColorSpace: colorSpace,
        CIContextOption.useSoftwareRenderer: NSNumber(value: false),
    ])
}

public func flush() {
    MCCore.flush()
}
