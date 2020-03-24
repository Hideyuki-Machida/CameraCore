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
    @objc public class Camera: NSObject, CCComponentProtocol {

        // MARK: - CCComponentProtocol
        public let setup: CCCapture.Camera.Setup = CCCapture.Camera.Setup()
        public let triger: CCCapture.Camera.Triger = CCCapture.Camera.Triger()
        public let pipe: CCCapture.Camera.Pipe = CCCapture.Camera.Pipe()
        public var debugger: ComponentDebugger?

        
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
            self.dispose()
            MCDebug.deinitLog(self)
        }

    }
}


fileprivate extension CCCapture.Camera {
    func start() {
        guard self.status != .play else { return }
        MCDebug.log("CameraCore.Camera.play")
        self.capture?.play()
        self.status = .play
    }

    func stop() {
        MCDebug.log("CameraCore.Camera.pause")
        self.capture?.stop()
        self.status = .pause
    }

    func dispose() {
        self.capture?.stop()
        self.status = .setup
        self.capture = nil
        self.setup._dispose()
        self.triger._dispose()
        self.pipe._dispose()
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

            if CMSampleBufferGetImageBuffer(sampleBuffer) != nil {
                // ピクセルデータ
                let currentCaptureItem: CCCapture.VideoCapture.CaptureData = CCCapture.VideoCapture.CaptureData(
                    sampleBuffer: sampleBuffer,
                    captureInfo: captureInfo,
                    depthData: depthData,
                    metadataObjects: metadataObjects,
                    colorPixelFormat: MTLPixelFormat.bgra8Unorm,
                    captureVideoOrientation: captureVideoOrientation
                )

                self.pipe.currentVideoCaptureItem = currentCaptureItem
                self.pipe.outVideoCapturePresentationTimeStamp = currentCaptureItem.presentationTimeStamp

                // デバッグ
                self.debugger?.update()
            }
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
        
        public func start() {
            self.camera?.start()
        }

        public func stop() {
            self.camera?.stop()
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

        private var _currentVideoCaptureItem: CCCapture.VideoCapture.CaptureData?
        public var currentVideoCaptureItem: CCCapture.VideoCapture.CaptureData? {
            get {
                objc_sync_enter(self)
                let currentVideoCaptureItem: CCCapture.VideoCapture.CaptureData? = self._currentVideoCaptureItem
                objc_sync_exit(self)
                return currentVideoCaptureItem
            }
            set {
                objc_sync_enter(self)
                self._currentVideoCaptureItem = newValue
                objc_sync_exit(self)
            }
        }

        private var _outVideoCapturePresentationTimeStamp: CMTime = CMTime.zero
        @objc dynamic public var outVideoCapturePresentationTimeStamp: CMTime {
            get {
                objc_sync_enter(self)
                let videoCapturePresentationTimeStamp: CMTime = self._outVideoCapturePresentationTimeStamp
                objc_sync_exit(self)
                return videoCapturePresentationTimeStamp
            }
            set {
                objc_sync_enter(self)
                self._outVideoCapturePresentationTimeStamp = newValue
                objc_sync_exit(self)
            }
        }

        public var outVideoCaptureData: ((_ currentVideoCaptureItem: CCCapture.VideoCapture.CaptureData) -> Void)?
        
        fileprivate func _dispose() {
            self.camera = nil
        }
    }
}

