//
//  ImageRecognition.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/07.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas



public extension CCVision.ImageRecognition {
    class Events: MCVisionImageRecognitionEventsProtocol {
        public var onUpdate: ((_ result: [String : VisionResultProtocol]) ->Void)?
        public var onUpdateResult: ((_ captureData: CCCapture.VideoCapture.CaptureData, _ result: [String : VisionResultProtocol]) ->Void)?
        required public init() {}
    }

    func pipe(camera: CCCapture.Camera) -> CCVision.ImageRecognition {
        let _events: CCVision.ImageRecognition.Events = CCVision.ImageRecognition.Events()
        self.set(events: _events)
        camera.pipe.outCaptureData = { [weak self] (captureData: CCCapture.VideoCapture.CaptureData) in
            guard
                let self = self
            else { return }
            guard var pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
            _events.onUpdate = { [weak _events] (result: [String : VisionResultProtocol]) in
                _events?.onUpdateResult?(captureData, result)
            }

            do {
                let sorce: CCTexture = try CCTexture.init(pixelBuffer: pixelBuffer, planeIndex: 0)
                try self.process(sorce: sorce, queue: CCCapture.videoOutputQueue)
            } catch {
                
            }
        }
        return self
    }
}
