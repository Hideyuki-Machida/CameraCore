//
//  VideoCaptureViewEvent.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public class VideoCaptureViewEvent: NSObject {
	public var onStatusChange: ((_ status: VideoCaptureStatus)->Void)?
	public var onPreviewUpdate: ((_ sampleBuffer: CMSampleBuffer)->Void)?
	public var onRecodingUpdate: ((_ recordedDuration: TimeInterval)->Void)?
	public var onRecodingComplete: ((_ result: Bool, _ filePath: URL)->Void)?
	public var onPixelUpdate: ((_ pixelBuffer: CVPixelBuffer)->Void)?
}
