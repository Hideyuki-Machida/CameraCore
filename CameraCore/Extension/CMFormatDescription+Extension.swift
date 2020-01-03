//
//  CMFormatDescription+Extension.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/03.
//  Copyright © 2020 Donuts. All rights reserved.
//

import AVFoundation
import Foundation

public extension CMFormatDescription {
    static func create(from pixelBuffer: CVPixelBuffer) -> CMFormatDescription? {
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
        return formatDescription
    }
}
