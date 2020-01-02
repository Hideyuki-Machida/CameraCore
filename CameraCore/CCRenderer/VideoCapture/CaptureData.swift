//
//  CaptureData.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/12/28.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import CoreVideo
import Foundation
import MetalCanvas
import MetalPerformanceShaders

extension CCRenderer.VideoCapture {
    public struct CaptureData {
        let sampleBuffer: CMSampleBuffer
        let frameRate: Int32
        let depthData: AVDepthData?
        let metadataObjects: [AVMetadataObject]?
        let captureSize: MCSize
        let colorPixelFormat: MTLPixelFormat

        internal init(sampleBuffer: CMSampleBuffer, frameRate: Int32, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?, captureSize: MCSize, colorPixelFormat: MTLPixelFormat) {
            self.sampleBuffer = sampleBuffer
            self.frameRate = frameRate
            self.depthData = depthData
            self.metadataObjects = metadataObjects
            self.captureSize = captureSize
            self.colorPixelFormat = colorPixelFormat
        }
    }
}
