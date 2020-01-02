//
//  VideoCaptureViewEvent.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import Foundation

public class VideoCaptureViewEvent: NSObject {
    public var onStatusChange: ((_ status: VideoCaptureView.Status) -> Void)?
    public var onFrameUpdate: ((_ sampleBuffer: CMSampleBuffer) -> Void)?
    public var onPixelUpdate: ((_ pixelBuffer: CVPixelBuffer) -> Void)?
    public var onRecodingUpdate: ((_ recordedDuration: TimeInterval) -> Void)?
    public var onRecodingComplete: ((_ result: Bool, _ filePath: URL) -> Void)?
}
