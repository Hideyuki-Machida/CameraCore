//
//  AVModuleCore.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/29.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import MetalCanvas

final public class AVModuleCore {
    public static var isMetalCanvas: Bool = MCCore.isMetalCanvas
    public static func setup() throws {
        try MCCore.setup(contextPptions: [
            CIContextOption.workingColorSpace : CGColorSpaceCreateDeviceRGB(),
            CIContextOption.useSoftwareRenderer : NSNumber(value: false)
        ])
    }
}
