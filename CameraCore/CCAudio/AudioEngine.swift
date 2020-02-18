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
        var onUpdatePCMBuffer: ((_ pcmBuffer: AVAudioPCMBuffer)->Void)?
        var onUpdateSampleBuffer: ((_ sampleBuffer: CMSampleBuffer)->Void)?
        
        let engine: AVAudioEngine = AVAudioEngine()
        public init() {
            //self.engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] (audioPCMBuffer: AVAudioPCMBuffer, audioTime: AVAudioTime) in
            self.engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] (audioPCMBuffer: AVAudioPCMBuffer, audioTime: AVAudioTime) in
                self?.onUpdatePCMBuffer?(audioPCMBuffer)
                guard let buffer: CMSampleBuffer = CMSampleBuffer.create(audioPCMBuffer: audioPCMBuffer, audioTime: audioTime) else { return }
                self?.onUpdateSampleBuffer?(buffer)
            }
        }
    }
}

public extension CCAudio.AudioEngine {
    func start() throws {
        try self.engine.start()
    }

    func stop() {
        self.engine.stop()
    }
}
