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

extension CCARCapture {
    @objc public class cARCamera: NSObject, CCComponentProtocol {
        // MARK: - CCComponentProtocol
        public let setup: CCARCapture.cARCamera.Setup = CCARCapture.cARCamera.Setup()
        public let triger: CCARCapture.cARCamera.Triger = CCARCapture.cARCamera.Triger()
        public let pipe: CCARCapture.cARCamera.Pipe = CCARCapture.cARCamera.Pipe()
        public var debug: CCComponentDebug?

        let session: ARSession = ARSession.init()
        
        public override init() {
            super.init()

            self.setup.camera = self
            self.triger.camera = self
            self.pipe.camera = self
        }
        
        fileprivate func start() {
            // Create a session configuration
            let configuration = ARWorldTrackingConfiguration()
            self.session.delegate = self
            self.session.run(configuration)
        }

        deinit {
            self.dispose()
            MCDebug.deinitLog(self)
        }

        func dispose() {
            self.setup._dispose()
            self.triger._dispose()
            self.pipe._dispose()
        }
    }

}

extension CCARCapture.cARCamera: ARSessionDelegate {
    public func session(_ session: ARSession, didUpdate: [ARAnchor]) {
        
    }
    public func session(_ session: ARSession, didUpdate: ARFrame) {
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


extension CCARCapture.cARCamera {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var camera: CCARCapture.cARCamera?

        fileprivate func _dispose() {
            self.camera = nil
        }
    }

    // MARK: - Triger
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var camera: CCARCapture.cARCamera?

        public func start() {
            self.camera?.start()
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
