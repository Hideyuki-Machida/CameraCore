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
import ProcessLogger_Swift

public extension CCVision {
    class Inference: NSObject, CCComponentProtocol {
        public let setup: CCVision.Inference.Setup = CCVision.Inference.Setup()
        public let triger: CCVision.Inference.Triger = CCVision.Inference.Triger()
        public let pipe: CCVision.Inference.Pipe = CCVision.Inference.Pipe()
        public var debug: CCComponentDebug?

        private let inferenceProcessQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCVision.Inference")
        private let inferenceProcessCompleteQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCVision.Inference.Complete")

        private var _currentItem: CCVision.Inference.Item?
        fileprivate var currentItem: CCVision.Inference.Item? {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._currentItem
            }
            set {
                objc_sync_enter(self)
                self._currentItem = newValue
                objc_sync_exit(self)
            }
        }

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
            self.isLoop = false
            self.setup.inference = self
            self.triger.inference = self
            self.pipe.inference = self
        }

        fileprivate func process(item: Item) {
            guard
                self.isProcess != true,
                self.processTimeStamp != item.timeStamp
            else { /* 画像データではないBuffer */ return }

            self.processTimeStamp = item.timeStamp
            self.isProcess = true

            var userInfo: [String : Any] = [:]
            
            for index in self.setup.process.indices {
                guard self.setup.process.indices.contains(index) else { continue }
                do {
                    try self.setup.process[index].process(
                        pixelBuffer: item.pixelBuffer,
                        timeStamp: item.timeStamp,
                        metadataObjects: item.metadataObjects,
                        userInfo: &userInfo
                    )
                } catch {
                }
             }

            self.pipe.userInfo = userInfo
            self.pipe.outTimeStamp = item.timeStamp
            self.debug?.update()
            self.isProcess = false
        }


        fileprivate var isLoop: Bool = false

        fileprivate func runLoop() {
            self.inferenceProcessQueue.async { [weak self] in
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
            guard
                let item: CCVision.Inference.Item = self.currentItem
            else { return }

            self.process(item: item)
        }


        deinit {
            self.dispose()
            ProcessLogger.deinitLog(self)
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

        public func start() {
            self.inference?.isLoop = true
            self.inference?.runLoop()
        }

        public func stop() {
            self.inference?.isLoop = false
        }

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
        
        private var _currentItem: CCVision.Inference.Item?
        fileprivate var currentItem: CCVision.Inference.Item? {
            get {
                objc_sync_enter(self)
                defer { objc_sync_exit(self) }
                return self._currentItem
            }
            set {
                objc_sync_enter(self)
                self._currentItem = newValue
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


        // MARK: - Pipe - input

        // MARK: input - CCCapture.Camera
        func input(camera: CCCapture.Camera) throws -> CCVision.Inference {
            let observation: NSKeyValueObservation = camera.pipe.observe(\.outPixelPresentationTimeStamp, options: [.new]) { [weak self] (object: CCCapture.Camera.Pipe, change) in
                guard
                    let self = self,
                    let captureData: CCCapture.VideoCapture.CaptureData = object.currentVideoCaptureItem,
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer)
                else { return }

                self.inference?.currentItem = CCVision.Inference.Item.init(
                    pixelBuffer: pixelBuffer,
                    timeStamp: captureData.presentationTimeStamp,
                    metadataObjects: captureData.metadataObjects
                )
            }

            self.observations.append(observation)
            return self.inference!
        }

        // MARK: input - CCPlayer
        func input(player: CCPlayer) throws -> CCVision.Inference {
            let observation: NSKeyValueObservation = player.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCPlayer.Pipe, change) in
                guard
                    let self = self,
                    let outTexture: CCTexture = object.outTexture,
                    let pixelBuffer: CVPixelBuffer = outTexture.pixelBuffer
                else { return }

                self.inference?.currentItem = CCVision.Inference.Item.init(
                    pixelBuffer: pixelBuffer,
                    timeStamp: outTexture.presentationTimeStamp,
                    metadataObjects: []
                )
            }
            self.observations.append(observation)

            return self.inference!
        }

        fileprivate func _dispose() {
            self.inference = nil
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
        }
    }

}

extension CCVision.Inference {
    struct Item {
        let pixelBuffer: CVPixelBuffer
        let timeStamp: CMTime
        let metadataObjects: [AVMetadataObject]
    }
}
