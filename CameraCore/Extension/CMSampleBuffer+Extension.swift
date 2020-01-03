//
//  CMSampleBuffer+Extension.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/03.
//  Copyright © 2020 Donuts. All rights reserved.
//

import AVFoundation
import Foundation

public extension CMSampleBuffer {
    static func create(from pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription, timingInfo: inout CMSampleTimingInfo) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil,
                                           refcon: nil, formatDescription: formatDescription, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
        return sampleBuffer
    }
}
