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

        fileprivate var currentItem: CCVariable<CCVision.Inference.Item?> = CCVariable(nil)
        fileprivate(set) var isProcess: CCVariable<Bool> = CCVariable(false)
        fileprivate(set) var processTimeStamp: CCVariable<CMTime> = CCVariable(CMTime.zero)

        public override init() {
            super.init()
            self.isLoop = false
            self.setup.inference = self
            self.triger.inference = self
            self.pipe.inference = self
        }

        fileprivate func process(item: Item) {
            guard
                self.isProcess.value != true,
                self.processTimeStamp.value != item.timeStamp
            else { /* 画像データではないBuffer */ return }

            self.processTimeStamp.value = item.timeStamp
            self.isProcess.value = true

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

            self.pipe.outUpdate(userInfo: userInfo)
            self.debug?.update()
            self.isProcess.value = false
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
                let item: CCVision.Inference.Item = self.currentItem.value
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
        private let completeQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCVision.Inference.Complete")
        
        fileprivate var observations: [NSKeyValueObservation] = []
        
        //fileprivate var currentItem: CCVariable<CCVision.Inference.Item?> = CCVariable(nil)
        fileprivate var inference: CCVision.Inference?

        public var userInfo: CCVariable<[String : Any]> = CCVariable([:])

        // MARK: - Pipe - input

        // MARK: input - CCCapture.Camera
        func input(camera: CCCapture.Camera) throws -> CCVision.Inference {
            camera.pipe.videoCaptureItem.bind() { [weak self] (captureData: CCCapture.VideoCapture.CaptureData?) in
                guard
                    let self = self,
                    let captureData: CCCapture.VideoCapture.CaptureData = captureData,
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer)
                else { return }

                self.inference?.currentItem.value = CCVision.Inference.Item.init(
                    pixelBuffer: pixelBuffer,
                    timeStamp: captureData.presentationTimeStamp,
                    metadataObjects: captureData.metadataObjects
                )
            }

            return self.inference!
        }

        // MARK: input - CCPlayer
        func input(player: CCPlayer) throws -> CCVision.Inference {
            player.pipe.outTexture.bind() { [weak self] (outTexture: CCTexture?) in
                guard
                    let self = self,
                    let outTexture: CCTexture = outTexture,
                    let pixelBuffer: CVPixelBuffer = outTexture.pixelBuffer
                else { return }

                self.inference?.currentItem.value = CCVision.Inference.Item.init(
                    pixelBuffer: pixelBuffer,
                    timeStamp: outTexture.presentationTimeStamp,
                    metadataObjects: []
                )
            }

            return self.inference!
        }

        fileprivate func outUpdate(userInfo: [String : Any]) {
            self.userInfo.value = userInfo
            self.completeQueue.async { [weak self] in
                self?.userInfo.dispatch()
                self?.userInfo.value.removeAll()
            }
        }

        fileprivate func _dispose() {
            self.inference = nil
            self.userInfo.dispose()
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
