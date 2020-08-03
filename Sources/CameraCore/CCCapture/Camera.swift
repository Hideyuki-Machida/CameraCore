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
import ProcessLogger_Swift

extension CCCapture {
    @objc public class Camera: NSObject, CCComponentProtocol {

        // MARK: - CCComponentProtocol
        public let setup: CCCapture.Camera.Setup = CCCapture.Camera.Setup()
        public let triger: CCCapture.Camera.Triger = CCCapture.Camera.Triger()
        public let pipe: CCCapture.Camera.Pipe = CCCapture.Camera.Pipe()
        public var debug: CCComponentDebug?

        
        public fileprivate(set) var property: CCCapture.VideoCapture.Property

        public var event: Event?
        public var status: Camera.Status = .setup {
            willSet {
                self.event?.onStatusChange.value = newValue
            }
        }

        public var capture: CCCapture.VideoCapture.VideoCaptureManager?
        public var depthData: CCVariable<AVDepthData?> = CCVariable(nil)
        public var metadataObjects: CCVariable<[AVMetadataObject]> = CCVariable([])
        
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
            ProcessLogger.deinitLog(self)
        }

    }
}


fileprivate extension CCCapture.Camera {
    func start() {
        guard self.status != .play else { return }
        ProcessLogger.log("CameraCore.Camera.play")
        self.depthData.value = nil
        self.capture?.play()
        self.status = .play
    }

    func stop() {
        ProcessLogger.log("CameraCore.Camera.pause")
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
            throw CCCapture.ErrorType.setup
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        self.capture?.onUpdateSampleBuffer = { [weak self] (sampleBuffer: CMSampleBuffer, captureVideoOrientation: AVCaptureVideoOrientation, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?) in

            guard
                let self = self,
                let captureInfo: CCCapture.VideoCapture.CaptureInfo = self.capture?.property.captureInfo
            else { return }

            if CMSampleBufferGetImageBuffer(sampleBuffer) != nil {
                // ピクセルデータ
                let currentCaptureItem: CCCapture.VideoCapture.CaptureData = CCCapture.VideoCapture.CaptureData(
                    sampleBuffer: sampleBuffer,
                    captureInfo: captureInfo,
                    depthData: self.depthData.value,
                    metadataObjects: self.metadataObjects.value,
                    mtlPixelFormat: MTLPixelFormat.bgra8Unorm,
                    outPutPixelFormatType: captureInfo.outPutPixelFormatType,
                    captureVideoOrientation: captureVideoOrientation
                )

                self.pipe.updateCaptureData(captureItem: currentCaptureItem)

                // デバッグ
                self.debug?.update(thred: Thread.current, queue: CCCapture.videoOutputQueue)
                self.debug?.update()
            } else {
                //self.pipe.outAudioPresentationTimeStamp = currentCaptureItem.presentationTimeStamp
            }
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        // AVDepthData & AVMetadataObject 取得
        self.capture?.onUpdateDepthData = { [weak self] (depthData: AVDepthData) in
            self?.depthData.value = depthData
        }
        
        self.capture?.onUpdateMetadataObjects = { [weak self] (metadataObjects: [AVMetadataObject]) in
            self?.metadataObjects.value = metadataObjects
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
        public var onStatusChange: CCVariable<CCCapture.Camera.Status?> = CCVariable(nil)
        public var onUpdate: CCVariable<CCCapture.VideoCapture.CaptureData?> = CCVariable(nil)
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

        // MARK: - Queue
        fileprivate let completeQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCCapture.Camera.completeQueue")

        fileprivate var camera: CCCapture.Camera?

        public var videoCaptureItem: CCVariable<CCCapture.VideoCapture.CaptureData?> = CCVariable(nil)

        func updateCaptureData(captureItem: CCCapture.VideoCapture.CaptureData) {
            self.videoCaptureItem.value = captureItem
            self.completeQueue.async { [weak self] in
                self?.videoCaptureItem.notice()
                self?.videoCaptureItem.value = nil
            }
        }

        fileprivate func _dispose() {
            self.videoCaptureItem.dispose()
            self.camera = nil
        }
    }
}
