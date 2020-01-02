//
//  Configuration.swift
//  CameraCore
//
//  Created by machidahideyuki on 2018/01/08.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation

struct Configuration {
    public static let defaultVideoCaptureProperty = CCRenderer.VideoCapture.Property(
        devicePosition: AVCaptureDevice.Position.back,
        deviceType: AVCaptureDevice.DeviceType.builtInDualCamera,
        option: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps30),
        ]
    )

    // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange について
    // http://kentaroid.com/kcvpixelformattype%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6%E3%81%AE%E8%80%83%E5%AF%9F/
    public static let sourcePixelBufferPixelFormatTypeKey: OSType = kCVPixelFormatType_32BGRA
    public static let outputPixelBufferPixelFormatTypeKey: OSType = kCVPixelFormatType_32BGRA

    public static let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
}
