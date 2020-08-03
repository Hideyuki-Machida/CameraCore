//
//  AudioEngine.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/16.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation

extension CCAudio {
    public class AudioEngine {

        // MARK: - CCComponentProtocol
        public let setup: CCAudio.AudioEngine.Setup = CCAudio.AudioEngine.Setup()
        public let triger: CCAudio.AudioEngine.Triger = CCAudio.AudioEngine.Triger()
        public let pipe: CCAudio.AudioEngine.Pipe = CCAudio.AudioEngine.Pipe()
        public var debug: CCComponentDebug?

        public let engine: AVAudioEngine = AVAudioEngine()

        public init() {
            self.engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] (audioPCMBuffer: AVAudioPCMBuffer, audioTime: AVAudioTime) in
                guard let buffer: CMSampleBuffer = CMSampleBuffer.create(audioPCMBuffer: audioPCMBuffer, audioTime: audioTime) else { return }
                self?.pipe.updateCaptureData(captureItem: buffer)
            }

            self.setup.audioEngine = self
            self.triger.audioEngine = self
            self.pipe.audioEngine = self
        }
    }
}

fileprivate extension CCAudio.AudioEngine {
    func start() throws {
        try self.engine.start()
    }

    func stop() {
        self.engine.stop()
    }

    func dispose() {
        self.engine.stop()
        self.setup._dispose()
        self.triger._dispose()
        self.pipe._dispose()
    }
}

public extension CCAudio.AudioEngine {

    // MARK: - Setup
    class Setup: CCComponentSetupProtocol {
        fileprivate var audioEngine: CCAudio.AudioEngine?

        fileprivate func _dispose() {
            self.audioEngine = nil
        }
    }

    // MARK: - Triger
    class Triger: CCComponentTrigerProtocol {
        fileprivate var audioEngine: CCAudio.AudioEngine?
        
        public func start() throws {
            try self.audioEngine?.start()
        }

        public func stop() {
            self.audioEngine?.stop()
        }

        public func dispose() {
            self.audioEngine?.dispose()
        }

        fileprivate func _dispose() {
            self.audioEngine = nil
        }
    }

    // MARK: - Pipe
    class Pipe: NSObject, CCComponentPipeProtocol {

        // MARK: - Queue
        fileprivate let completeQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCAudio.AudioEngine.completeQueue")

        fileprivate var audioEngine: CCAudio.AudioEngine?

        public var audioCaptureItem: CCVariable<CMSampleBuffer?> = CCVariable(nil)

        func updateCaptureData(captureItem: CMSampleBuffer) {
            self.audioCaptureItem.value = captureItem
            self.completeQueue.async { [weak self] in
                self?.audioCaptureItem.notice()
                self?.audioCaptureItem.value = nil
            }
        }

        fileprivate func _dispose() {
            self.audioCaptureItem.dispose()
            self.audioEngine = nil
        }
    }
}
