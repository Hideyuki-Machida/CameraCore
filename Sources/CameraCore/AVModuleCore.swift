//
//  AVModuleCore.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/29.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import Foundation
import MetalCanvas
import CoreImage

public final class AVModuleCore {
    public static let isMetalCanvas: Bool = MCCore.isMetalCanvas
    public static func setup() throws {
        try MCCore.setup(contextOptions: [
            CIContextOption.workingColorSpace: CGColorSpaceCreateDeviceRGB(),
            CIContextOption.useSoftwareRenderer: NSNumber(value: false),
        ])
    }
}
