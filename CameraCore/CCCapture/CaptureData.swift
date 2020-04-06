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

extension CCCapture.VideoCapture {
    public struct CaptureData {
        let sampleBuffer: CMSampleBuffer
        let captureInfo: CCCapture.VideoCapture.CaptureInfo
        let depthData: AVDepthData?
        let metadataObjects: [AVMetadataObject]?
        let mtlPixelFormat: MTLPixelFormat
        let outPutPixelFormatType: MCPixelFormatType
        let presentationTimeStamp: CMTime
        let captureVideoOrientation: AVCaptureVideoOrientation

        internal init(sampleBuffer: CMSampleBuffer, captureInfo: CCCapture.VideoCapture.CaptureInfo, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?, mtlPixelFormat: MTLPixelFormat, outPutPixelFormatType: MCPixelFormatType, captureVideoOrientation: AVCaptureVideoOrientation) {
            self.sampleBuffer = sampleBuffer
            self.captureInfo = captureInfo
            self.depthData = depthData
            self.metadataObjects = metadataObjects
            self.mtlPixelFormat = mtlPixelFormat
            self.outPutPixelFormatType = outPutPixelFormatType
            self.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.captureVideoOrientation = captureVideoOrientation
        }
    }
}
