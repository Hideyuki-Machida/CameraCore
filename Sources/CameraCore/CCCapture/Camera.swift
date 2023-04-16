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
import Combine

extension CCCapture {
    @objc public class Camera: NSObject, CCComponentProtocol {

        // MARK: - CCComponentProtocol
        public let setup: CCCapture.Camera.Setup = CCCapture.Camera.Setup()
        public let trigger: CCCapture.Camera.Trigger = CCCapture.Camera.Trigger()
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
        fileprivate var cancellableBag: [AnyCancellable] = []
        
        public init(property: CCCapture.VideoCapture.Property) throws {
            self.property = property

            super.init()
            try self.setupProperty(property: property)
            
            self.setup.camera = self
            self.trigger.camera = self
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
        self.trigger._dispose()
        self.pipe._dispose()
    }
}

fileprivate extension CCCapture.Camera {
    func setupProperty(property: CCCapture.VideoCapture.Property) throws {
        self.property = property

        ///////////////////////////////////////////////////////////////////////////////////////////////////
        do {
            let capture: CCCapture.VideoCapture.VideoCaptureManager = try CCCapture.VideoCapture.VideoCaptureManager(property: property)
            self.capture = capture
            ///////////////////////////////////////////////////////////////////////////////////////////////////
            capture.sampleBuffer.sink(receiveValue: { [weak self] (item: CCCapture.VideoCapture.VideoCaptureOutput.Item) in
                guard
                    let self = self,
                    let captureInfo: CCCapture.VideoCapture.CaptureInfo = self.capture?.property.captureInfo
                else { return }

                if CMSampleBufferGetImageBuffer(item.sampleBuffer) != nil {
                    // ピクセルデータ
                    let currentCaptureItem: CCCapture.VideoCapture.CaptureData = CCCapture.VideoCapture.CaptureData(
                        sampleBuffer: item.sampleBuffer,
                        captureInfo: captureInfo,
                        depthData: self.depthData.value,
                        metadataObjects: self.metadataObjects.value,
                        mtlPixelFormat: MTLPixelFormat.bgra8Unorm,
                        outPutPixelFormatType: captureInfo.outPutPixelFormatType,
                        captureVideoOrientation: item.devicePosition
                    )

                    self.pipe.videoCaptureItem.send(currentCaptureItem)

                    // デバッグ
                    self.debug?.update(thred: Thread.current, queue: CCCapture.videoOutputQueue)
                    self.debug?.update()
                } else {
                    let currentCaptureItem: CCCapture.VideoCapture.CaptureData = CCCapture.VideoCapture.CaptureData(
                        sampleBuffer: item.sampleBuffer,
                        captureInfo: captureInfo,
                        depthData: nil,
                        metadataObjects: self.metadataObjects.value,
                        mtlPixelFormat: MTLPixelFormat.bgra8Unorm,
                        outPutPixelFormatType: captureInfo.outPutPixelFormatType,
                        captureVideoOrientation: item.devicePosition
                    )

                    self.pipe.audioCaptureItem.send(currentCaptureItem)
                }
            }).store(in: &self.cancellableBag)
            ///////////////////////////////////////////////////////////////////////////////////////////////////

            ///////////////////////////////////////////////////////////////////////////////////////////////////
            // AVDepthData & AVMetadataObject 取得
            var depthData: PassthroughSubject<AVDepthData, Never> {
                get {
                    return capture.depthData
                }
            }
            var metadataObjects: PassthroughSubject<[AVMetadataObject], Never> {
                get {
                    return capture.metadataObjects
                }
            }

        } catch {
            self.capture = nil
            throw CCCapture.ErrorType.setup
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////


        /*
        self.capture?.onUpdateDepthData = { [weak self] (depthData: AVDepthData) in
            self?.depthData.value = depthData
        }
        
        self.capture?.onUpdateMetadataObjects = { [weak self] (metadataObjects: [AVMetadataObject]) in
            self?.metadataObjects.value = metadataObjects
        }
         */
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

    // MARK: - Trigger
    public class Trigger: CCComponentTriggerProtocol {
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

        //public var videoCaptureItem: PassthroughSubject<CCCapture.VideoCapture.CaptureData?, Error>
        //public var audioCaptureItem: CCCapture.VideoCapture.CaptureData?
        public let videoCaptureItem: PassthroughSubject<CCCapture.VideoCapture.CaptureData, Error> = PassthroughSubject<CCCapture.VideoCapture.CaptureData, Error>()
        public let audioCaptureItem: PassthroughSubject<CCCapture.VideoCapture.CaptureData, Error> = PassthroughSubject<CCCapture.VideoCapture.CaptureData, Error>()

        override init() {
            super.init()
        }

        fileprivate func _dispose() {
            //self.videoCaptureItem.dispose()
            self.camera = nil
        }
    }
}
