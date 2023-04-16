//
//  File.swift
//  
//
//  Created by hideyuki machida on 2022/02/08.
//

import Foundation
import AVFoundation

extension CCAudio {
    public class Microphone {

        // MARK: - CCComponentProtocol
        public let setup: CCAudio.Microphone.Setup = CCAudio.Microphone.Setup()
        public let trigger: CCAudio.Microphone.Trigger = CCAudio.Microphone.Trigger()
        public let pipe: CCAudio.Microphone.Pipe = CCAudio.Microphone.Pipe()
        public var debug: CCComponentDebug?

        public let engine: AVAudioEngine = AVAudioEngine()

        public init() {
            self.engine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] (audioPCMBuffer: AVAudioPCMBuffer, audioTime: AVAudioTime) in
            //self.engine.mainMixerNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] (audioPCMBuffer: AVAudioPCMBuffer, audioTime: AVAudioTime) in
                guard let buffer: CMSampleBuffer = CMSampleBuffer.create(audioPCMBuffer: audioPCMBuffer, audioTime: audioTime) else { return }
                self?.pipe.audioCaptureSampleBuffer = buffer
            }

            self.setup.audioEngine = self
            self.trigger.audioEngine = self
            self.pipe.audioEngine = self
        }
    }
}

fileprivate extension CCAudio.Microphone {
    func start() throws {
        try self.engine.start()
    }

    func stop() {
        self.engine.stop()
    }

    func dispose() {
        self.engine.stop()
        self.setup._dispose()
        self.trigger._dispose()
        self.pipe._dispose()
    }
}

public extension CCAudio.Microphone {

    // MARK: - Setup
    class Setup: CCComponentSetupProtocol {
        fileprivate var audioEngine: CCAudio.Microphone?

        fileprivate func _dispose() {
            self.audioEngine = nil
        }
    }

    // MARK: - Trigger
    class Trigger: CCComponentTriggerProtocol {
        fileprivate var audioEngine: CCAudio.Microphone?
        
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

        fileprivate var audioEngine: CCAudio.Microphone?

        @Published public var audioCaptureSampleBuffer: CMSampleBuffer?

        fileprivate func _dispose() {
            self.audioEngine = nil
        }
    }
}
