//
//  VideoCaptureViewEvent.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas

public class VideoCaptureViewEvent: NSObject {
    public var onStatusChange: ((_ status: VideoCaptureStatus)->Void)?
    public var onFrameUpdate: ((_ sampleBuffer: CMSampleBuffer, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject])->Void)?
    public var onPixelUpdate: ((_ pixelBuffer: CVPixelBuffer, _ depthData: AVDepthData?, _ metadataObjects: [AVMetadataObject])->Void)?
    public var onRecodingUpdate: ((_ recordedDuration: TimeInterval)->Void)?
    public var onRecodingComplete: ((_ result: Bool, _ filePath: URL)->Void)?

    deinit {
        MCDebug.deinitLog(self)
    }
}
