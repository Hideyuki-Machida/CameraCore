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
        public let setup: CCCapture.Camera.Setup = CCCapture.Camera.Setup()
        public let triger: CCCapture.Camera.Triger = CCCapture.Camera.Triger()
        public let pipe: CCCapture.Camera.Pipe = CCCapture.Camera.Pipe()
        
        public fileprivate(set) var property: CCCapture.VideoCapture.Property {
            willSet {
                self.onUpdateCaptureProperty?(newValue)
            }
        }

        public var event: Event?
        public var status: Camera.Status = .setup {
            willSet {
                self.event?.onStatusChange?(newValue)
            }
        }

        public var onUpdateCaptureProperty: ((_ property: CCCapture.VideoCapture.Property) -> Void)?

        public var capture: CCCapture.VideoCapture.VideoCaptureManager?

        public init(property: CCCapture.VideoCapture.Property) throws {
            self.property = property

            super.init()
            try self.setupProperty(property: property)
            
            self.setup.camera = self
            self.triger.camera = self
            self.pipe.camera = self

        }

        deinit {
            MCDebug.deinitLog(self)
        }

    }
}


extension CCCapture.Camera {
    fileprivate func play() {
        guard self.status != .play else { return }
        MCDebug.log("CameraCore.VideoRecordingPlayer.play")
        self.capture?.play()
        self.status = .play
    }

    fileprivate func pause() {
        MCDebug.log("CameraCore.VideoRecordingPlayer.pause")
        self.capture?.stop()
        self.status = .pause
    }

    fileprivate func dispose() {
        MCDebug.log("CameraCore.VideoRecordingPlayer.dispose")
        self.capture?.stop()
        self.status = .setup
        self.capture = nil
        self.setup.camera = nil
        self.triger.camera = nil
        self.pipe.camera = nil
    }
}

fileprivate extension CCCapture.Camera {
    func setupProperty(property: CCCapture.VideoCapture.Property) throws {
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
        self.capture?.onUpdate = { [weak self] (sampleBuffer: CMSampleBuffer, captureVideoOrientation: AVCaptureVideoOrientation, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?) in

            guard
                let self = self,
                let captureInfo: CCCapture.VideoCapture.CaptureInfo = self.capture?.property.captureInfo
            else { return }

            let currentCaptureItem: CCCapture.VideoCapture.CaptureData = CCCapture.VideoCapture.CaptureData(
                sampleBuffer: sampleBuffer,
                captureInfo: captureInfo,
                depthData: depthData,
                metadataObjects: metadataObjects,
                colorPixelFormat: MTLPixelFormat.bgra8Unorm,
                captureVideoOrientation: captureVideoOrientation
            )


            self.pipe.currentCaptureItem = currentCaptureItem
            self.pipe.outPresentationTimeStamp = currentCaptureItem.presentationTimeStamp
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////
    }

    func updateProperty(property: CCCapture.VideoCapture.Property) throws {
        try self.capture?.update(property: property)
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

extension CCCapture.Camera {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var camera: CCCapture.Camera?

        public func setup(property: CCCapture.VideoCapture.Property) throws {
            try self.camera?.setupProperty(property: property)
        }
        public func update(property: CCCapture.VideoCapture.Property) throws {
            try self.camera?.updateProperty(property: property)
        }

        fileprivate func _dispose() {
            self.camera = nil
        }
    }

    // MARK: - Triger
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var camera: CCCapture.Camera?
        
        public func play() {
            self.camera?.play()
        }

        public func pause() {
            self.camera?.pause()
        }
        public func dispose() {
            self.camera?.dispose()
        }

        fileprivate func _dispose() {
            self.camera = nil
        }
    }

    // MARK: - Pipe
    public class Pipe: NSObject, CCComponentPipeProtocol {
        fileprivate var camera: CCCapture.Camera?

        private var _currentCaptureItem: CCCapture.VideoCapture.CaptureData?
        public var currentCaptureItem: CCCapture.VideoCapture.CaptureData? {
            get {
                objc_sync_enter(self)
                let currentCaptureItem: CCCapture.VideoCapture.CaptureData? = self._currentCaptureItem
                objc_sync_exit(self)
                return currentCaptureItem
            }
            set {
                objc_sync_enter(self)
                self._currentCaptureItem = newValue
                objc_sync_exit(self)
            }
        }

        private var _outPresentationTimeStamp: CMTime = CMTime.zero
        @objc dynamic public var outPresentationTimeStamp: CMTime {
            get {
                objc_sync_enter(self)
                let presentationTimeStamp: CMTime = self._outPresentationTimeStamp
                objc_sync_exit(self)
                return presentationTimeStamp
            }
            set {
                objc_sync_enter(self)
                self._outPresentationTimeStamp = newValue
                objc_sync_exit(self)
            }
        }

        public var outCaptureData: ((_ currentCaptureItem: CCCapture.VideoCapture.CaptureData) -> Void)?
        
        fileprivate func _dispose() {
            self.camera = nil
        }
    }
}

