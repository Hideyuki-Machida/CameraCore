//
//  CustomOperator.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/01.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas

let processQueue: DispatchQueue = DispatchQueue(label: "CameraCore.ProcessQueue")
let drawQueue: DispatchQueue = DispatchQueue(label: "CameraCore.DrawQueue")

infix operator --> : AdditionPrecedence

@discardableResult
public func --> (left: CCCapture.Camera, right: CCRenderer.PostProcess) -> CCRenderer.PostProcess {
    left.onUpdate = { [weak left, weak right] (currentCaptureItem: CCCapture.VideoCapture.CaptureData) in
        processQueue.async { [weak left, weak right] in
            guard let left: CCCapture.Camera = left, let right: CCRenderer.PostProcess = right, !right.isProcess else { return }
            let captureSize: MCSize = left.property.captureInfo.presetSize.size(isOrientation: true)
            right.updateOutTexture(captureSize: captureSize, colorPixelFormat: MTLPixelFormat.bgra8Unorm)
            let presentationTimeStamp: CMTime = CMSampleBufferGetPresentationTimeStamp(currentCaptureItem.sampleBuffer)
            guard presentationTimeStamp != right.presentationTimeStamp else { return }
            do {
                try right.process(captureData: currentCaptureItem, queue: drawQueue)
            } catch {
                
            }
        }
    }
    return right
}

@discardableResult
public func --> (left: CCRenderer.PostProcess, right: CCView) -> CCView {
    do {
        try right.setup()
    } catch {
        
    }

    left.onUpdate = { [weak right] (outTexture: MCTexture, presentationTimeStamp: CMTime) in
        drawQueue.async { [weak right] in
            do {
                right?.drawTexture = outTexture.texture
                right?.presentationTimeStamp = presentationTimeStamp
            } catch {
                
            }
        }
    }
    left.onUpdatePixelBuffer = { (outPixelBuffer: CVPixelBuffer, presentationTimeStamp: CMTime) in
        drawQueue.async { [weak right] in
            do {
                var outPixelBuffer = outPixelBuffer
                right?.drawTexture = try MCCore.texture(pixelBuffer: &outPixelBuffer, colorPixelFormat: MTLPixelFormat.bgra8Unorm)
                right?.presentationTimeStamp = presentationTimeStamp
            } catch {
                    
            }
        }
    }

    return right
}

@discardableResult
public func --> (left: CCCapture.Camera, right: CCView) -> CCView {
    do {
        try right.setup()
    } catch {
        
    }

    left.onUpdate = { [weak left, weak right] (captureData: CCCapture.VideoCapture.CaptureData) in
        drawQueue.async { [weak left, weak right] in
            guard var pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer) else { /* 画像データではないBuffer */ return }
            let presentationTimeStamp: CMTime = CMSampleBufferGetPresentationTimeStamp(captureData.sampleBuffer)
            do {
                right?.drawTexture = try MCCore.texture(pixelBuffer: &pixelBuffer, colorPixelFormat: MTLPixelFormat.bgra8Unorm)
                right?.presentationTimeStamp = presentationTimeStamp
            } catch {
                
            }
        }
    }

    return right
}
