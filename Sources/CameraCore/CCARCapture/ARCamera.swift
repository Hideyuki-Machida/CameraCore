//
//  ARCamera.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/04/04.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import MetalCanvas
import ARKit
import ProcessLogger_Swift

@available(iOS 13.0, *)
extension CCARCapture {
    @objc public class cARCamera: NSObject, CCComponentProtocol {
        public enum Mode {
            case worldTracking
            case orientationTracking
            case faceTracking
            
            var configuration: ARConfiguration {
                switch self {
                case .worldTracking:
                    return ARWorldTrackingConfiguration()
                case .orientationTracking:
                    return AROrientationTrackingConfiguration()
                case .faceTracking:
                    return ARFaceTrackingConfiguration()
                }
            }
        }

        // MARK: - CCComponentProtocol
        public let setup: CCARCapture.cARCamera.Setup = CCARCapture.cARCamera.Setup()
        public let trigger: CCARCapture.cARCamera.Trigger = CCARCapture.cARCamera.Trigger()
        public let pipe: CCARCapture.cARCamera.Pipe = CCARCapture.cARCamera.Pipe()
        public var debug: CCComponentDebug?

        var configuration: ARConfiguration
        let session: ARSession = ARSession.init()
        
        public init(mode: CCARCapture.cARCamera.Mode) {

            self.configuration = mode.configuration
            self.configuration.frameSemantics = .personSegmentation
            super.init()
            
            self.setup.camera = self
            self.trigger.camera = self
            self.pipe.camera = self
        }
        
        fileprivate func start() {
            self.session.delegate = self
            self.session.run(self.configuration)
        }

        deinit {
            self.dispose()
            ProcessLogger.deinitLog(self)
        }

        func dispose() {
            self.setup._dispose()
            self.trigger._dispose()
            self.pipe._dispose()
        }
    }

}

@available(iOS 13.0, *)
extension CCARCapture.cARCamera: ARSessionDelegate {
    public func session(_ session: ARSession, didUpdate: [ARAnchor]) {
        
    }
    public func session(_ session: ARSession, didUpdate: ARFrame) {
        didUpdate.timestamp
        let captureInfo: CCCapture.VideoCapture.CaptureInfo = CCCapture.VideoCapture.CaptureInfo()
        captureInfo.updateAr()
        let captureData: CCARCapture.CaptureData = CCARCapture.CaptureData.init(
            arFrame: didUpdate,
            captureInfo: captureInfo,
            mtlPixelFormat: MTLPixelFormat.bgra8Unorm,
            outPutPixelFormatType: MCPixelFormatType.kCV420YpCbCr8BiPlanarFullRange,
            captureVideoOrientation: .portrait
        )

        self.pipe.captureData = captureData
        self.pipe.arFrame = didUpdate
        self.pipe.ouTimeStamp = captureData.presentationTimeStamp
    }
}


@available(iOS 13.0, *)
extension CCARCapture.cARCamera {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var camera: CCARCapture.cARCamera?

        fileprivate func _dispose() {
            self.camera = nil
        }
    }

    // MARK: - Trigger
    public class Trigger: CCComponentTriggerProtocol {
        fileprivate var camera: CCARCapture.cARCamera?

        public func start() {
            self.camera?.start()
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
        fileprivate var camera: CCARCapture.cARCamera?

        public var captureData: CCARCapture.CaptureData?
        public var arFrame: ARFrame?
        @objc dynamic public var ouTimeStamp: CMTime = CMTime.zero

        fileprivate func _dispose() {
            self.camera = nil
        }
    }
}
