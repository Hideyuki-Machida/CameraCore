//
//  CaptureData.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/04/04.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import ARKit
import MetalCanvas

extension CCARCapture {
    public struct CaptureData {
        public let arFrame: ARFrame
        public let captureInfo: CCCapture.VideoCapture.CaptureInfo
        public let mtlPixelFormat: MTLPixelFormat
        public let outPutPixelFormatType: MCPixelFormatType
        public let presentationTimeStamp: CMTime
        public let captureVideoOrientation: AVCaptureVideoOrientation

        internal init(arFrame: ARFrame, captureInfo: CCCapture.VideoCapture.CaptureInfo, mtlPixelFormat: MTLPixelFormat, outPutPixelFormatType: MCPixelFormatType, captureVideoOrientation: AVCaptureVideoOrientation) {
            self.arFrame = arFrame
            self.captureInfo = captureInfo
            self.mtlPixelFormat = mtlPixelFormat
            self.outPutPixelFormatType = outPutPixelFormatType
            let scale = 60
            self.presentationTimeStamp = CMTime.init(value: CMTimeValue(arFrame.timestamp * Double(scale)), timescale: CMTimeScale(scale))
            self.captureVideoOrientation = captureVideoOrientation
        }

    }
}
