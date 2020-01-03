//
//  Camera.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/12/31.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas
import MetalKit
import UIKit

extension CCCapture {
    @objc public class Camera: NSObject {
        fileprivate(set) public var property: CCCapture.VideoCapture.Property
        
        public var event: Event?
        public var status: Camera.Status = .setup {
            willSet {
                self.event?.onStatusChange?(newValue)
            }
        }

        public var onUpdate: ((_ currentCaptureItem: CCCapture.VideoCapture.CaptureData)->Void)?
        public var capture: CCCapture.VideoCapture.VideoCaptureManager?

        public init(_ property: CCCapture.VideoCapture.Property) throws {
            self.property = property

            super.init()
            try self.setup(property)
        }
        
        deinit {
            MCDebug.deinitLog(self)
        }

        public func setup(_ property: CCCapture.VideoCapture.Property) throws {
            self.property = property

            ///////////////////////////////////////////////////////////////////////////////////////////////////
            do {
                self.capture = try CCCapture.VideoCapture.VideoCaptureManager(property: property)
            } catch {
                self.capture = nil
                throw CCRenderer.ErrorType.setup
            }
            ///////////////////////////////////////////////////////////////////////////////////////////////////

            ///////////////////////////////////////////////////////////////////////////////////////////////////
            self.capture?.onUpdate = { [weak self] (sampleBuffer: CMSampleBuffer, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?) in

                guard
                    let self = self,
                    let captureSize: MCSize = self.capture?.property.captureInfo.presetSize.size(isOrientation: true),
                    let frameRate: Int32 = self.capture?.property.captureInfo.frameRate

                    else { return }
                
                let currentCaptureItem: CCCapture.VideoCapture.CaptureData = CCCapture.VideoCapture.CaptureData(
                    sampleBuffer: sampleBuffer,
                    frameRate: frameRate,
                    depthData: depthData,
                    metadataObjects: metadataObjects,
                    captureSize: captureSize,
                    colorPixelFormat: MTLPixelFormat.bgra8Unorm
                )

                self.onUpdate?(currentCaptureItem)
                self.event?.onUpdate?(currentCaptureItem)
            }
            ///////////////////////////////////////////////////////////////////////////////////////////////////
        }

        public func play() {
            guard self.status != .play else { return }
            MCDebug.log("CameraCore.VideoRecordingPlayer.play")
            self.capture?.play()
            self.status = .play
        }

        public func pause() {
            MCDebug.log("CameraCore.VideoRecordingPlayer.pause")
            self.capture?.stop()
            self.status = .pause
        }

        public func dispose() {
            MCDebug.log("CameraCore.VideoRecordingPlayer.dispose")
            self.capture?.stop()
            self.status = .setup
            self.capture = nil
        }
    }
}

extension CCCapture.Camera {
    public func update(property: CCCapture.VideoCapture.Property) throws {
        try self.capture?.update(property: property)
        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // 描画用テクスチャを生成
        guard let captureSize: MCSize = self.capture?.property.captureInfo.presetSize.size(isOrientation: true) else { return }
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
}

extension CCCapture.Camera {
    public enum Status {
        case setup
        case update
        case ready
        case play
        case pause
        case seek
        case dispose
    }

    public class Event: NSObject {
        public var onStatusChange: ((_ status: CCCapture.Camera.Status) -> Void)?
        public var onUpdate: ((_ captureData: CCCapture.VideoCapture.CaptureData) -> Void)?
    }
}
