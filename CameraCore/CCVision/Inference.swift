//
//  Inference.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/07.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas


public extension CCVision {
    class Inference: NSObject, CCComponentProtocol {
        public let setup: CCVision.Inference.Setup = CCVision.Inference.Setup()
        public let triger: CCVision.Inference.Triger = CCVision.Inference.Triger()
        public let pipe: CCVision.Inference.Pipe = CCVision.Inference.Pipe()
        public var debug: CCComponentDebug?

        private let inferenceProcessQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCVision.Inference")
        private let inferenceProcessCompleteQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCVision.Inference.Complete")

        private var _isProcess: Bool = false
        fileprivate(set) var isProcess: Bool {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._isProcess
            }
            set {
                objc_sync_enter(self)
                self._isProcess = newValue
                objc_sync_exit(self)
            }
        }

        private var _processTimeStamp: CMTime = CMTime.zero
        fileprivate(set) var processTimeStamp: CMTime {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._processTimeStamp
            }
            set {
                objc_sync_enter(self)
                self._processTimeStamp = newValue
                objc_sync_exit(self)
            }
        }

        public override init() {
            super.init()
            self.setup.inference = self
            self.triger.inference = self
            self.pipe.inference = self
        }

        fileprivate func process(pixelBuffer: CVPixelBuffer, timeStamp: CMTime) {
            guard
                self.isProcess != true,
                self.processTimeStamp != timeStamp
            else { /* 画像データではないBuffer */ return }

            self.processTimeStamp = timeStamp
            self.isProcess = true

            var userInfo: [String : Any] = [:]
            
            for index in self.setup.process.indices {
                guard self.setup.process.indices.contains(index) else { continue }
                do {
                    try self.setup.process[index].process(pixelBuffer: pixelBuffer, timeStamp: timeStamp, userInfo: &userInfo)
                } catch {
                }
             }

            self.pipe.userInfo = userInfo
            self.pipe.outTimeStamp = timeStamp
            self.debug?.update()
            self.isProcess = false
        }
        
        deinit {
            self.dispose()
            MCDebug.deinitLog(self)
        }
        
    }
}

fileprivate extension CCVision.Inference {
    func dispose() {
        self.setup._dispose()
        self.triger._dispose()
        self.pipe._dispose()
    }
}

extension CCVision.Inference {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var inference: CCVision.Inference?

        private var _process: [CCVisionInferenceProtocol] = []
        public var process: [CCVisionInferenceProtocol] {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._process
            }
            set {
                objc_sync_enter(self)
                self._process = newValue
                objc_sync_exit(self)
            }
        }

        fileprivate func _dispose() {
            self.inference = nil
        }
    }

    // MARK: - Triger
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var inference: CCVision.Inference?

        public func dispose() {
            self.inference?.dispose()
        }

        fileprivate func _dispose() {
            self.inference = nil
        }
    }

}

extension CCVision.Inference {
    // MARK: - Pipe
    public class Pipe: NSObject, CCComponentPipeProtocol {
        fileprivate var observations: [NSKeyValueObservation] = []
        
        private var _currentCaptureItem: CCCapture.VideoCapture.CaptureData?
        fileprivate var currentCaptureItem: CCCapture.VideoCapture.CaptureData? {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._currentCaptureItem
            }
            set {
                objc_sync_enter(self)
                self._currentCaptureItem = newValue
                objc_sync_exit(self)
            }
        }

        private var _userInfo: [String : Any] = [:]
        public var userInfo: [String : Any] {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._userInfo
            }
            set {
                objc_sync_enter(self)
                self._userInfo = newValue
                objc_sync_exit(self)
            }
        }

        private var _outTimeStamp: CMTime = CMTime.zero
        @objc dynamic public var outTimeStamp: CMTime {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._outTimeStamp
            }
            set {
                objc_sync_enter(self)
                self._outTimeStamp = newValue
                objc_sync_exit(self)
            }
        }

        fileprivate var inference: CCVision.Inference?
        fileprivate var isLoop: Bool = true

        func input(camera: CCCapture.Camera) -> CCVision.Inference {
            self.runLoop()

            let observation: NSKeyValueObservation = camera.pipe.observe(\.outVideoCapturePresentationTimeStamp, options: [.new]) { [weak self] (object: CCCapture.Camera.Pipe, change) in
                guard
                    let self = self,
                    let captureData: CCCapture.VideoCapture.CaptureData = object.currentVideoCaptureItem
                else { return }
                self.currentCaptureItem = captureData
            }

            self.observations.append(observation)
            return self.inference!
       }

        fileprivate func _dispose() {
            self.inference = nil
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
        }
        
        fileprivate func runLoop() {
            self.inference?.inferenceProcessQueue.async { [weak self] in
                guard let self = self else { return }
                let interval: TimeInterval = 1.0 / (60 * 2)
                let timer: Timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.updateDisplay), userInfo: nil, repeats: true)
                RunLoop.current.add(timer, forMode: RunLoop.Mode.tracking)
                while self.isLoop {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: interval))
                }
            }
        }

        @objc private func updateDisplay() {
            guard let currentCaptureItem: CCCapture.VideoCapture.CaptureData = self.currentCaptureItem else { return }
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(currentCaptureItem.sampleBuffer) else { return }
            self.inference?.process(pixelBuffer: pixelBuffer, timeStamp: currentCaptureItem.presentationTimeStamp)
        }
    }

}
