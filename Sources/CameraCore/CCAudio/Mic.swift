//
//  Mic.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation

extension CCAudio {
    public class Mic {
        var audioEngine: AVAudioEngine = AVAudioEngine()
        public var volume: Float {
            get {
                return self.audioEngine.inputNode.volume
            }
            set {
                self.audioEngine.inputNode.volume = newValue
            }
        }
        public init() throws {
            /*
            // Bluetooth接続を許可
            try AVAudioSession.sharedInstance()
                .setCategory(.playAndRecord,
                             mode: .voiceChat,
                             options: .allowBluetoothA2DP)
 */
        }
    }
}

extension CCAudio.Mic {
    func pipe(audioEngine: inout AVAudioEngine) throws -> CCAudio.Mic {

        audioEngine.inputNode.volume = self.audioEngine.inputNode.volume
        self.audioEngine = audioEngine
        self.audioEngine.connect(self.audioEngine.inputNode, to: self.audioEngine.mainMixerNode, format: self.audioEngine.inputNode.inputFormat(forBus: 0))
        return self
    }
}
