//
//  AudioPlayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation

extension CCAudio {
    public class AudioPlayer {
        // MARK: - CCComponentProtocol
        public let setup: CCAudio.AudioPlayer.Setup = CCAudio.AudioPlayer.Setup()
        public let triger: CCAudio.AudioPlayer.Triger = CCAudio.AudioPlayer.Triger()
        public let pipe: CCAudio.AudioPlayer.Pipe = CCAudio.AudioPlayer.Pipe()
        public var debug: CCComponentDebug?

        let audioFile: AVAudioFile
        let player: AVAudioPlayerNode = AVAudioPlayerNode()

        public var volume: Float {
            get {
                return self.player.volume
            }
            set {
                self.player.volume = newValue
            }
        }

        public init(url: URL) throws {
            self.audioFile = try AVAudioFile(forReading: url)

            self.setup.audioPlayer = self
            self.triger.audioPlayer = self
            self.pipe.audioPlayer = self
        }
    }
}


fileprivate extension CCAudio.AudioPlayer {
    func play() throws {
        guard self.pipe.audioEngine?.engine.isRunning == true else { return }

        let sampleRate: Double = self.audioFile.fileFormat.sampleRate
        let length: AVAudioFramePosition = self.audioFile.length
        let duration = Double(length) / sampleRate
        //var output = self.audioEngine.outputNode
        
        /*
        var reverb = AVAudioUnitReverb()
        //reverbの設定
        reverb.loadFactoryPreset(.largeRoom2)
        reverb.wetDryMix = 100
        self.audioEngine.attach(reverb)
        self.audioEngine.connect(self.player, to: reverb, format: self.audioFile.processingFormat)
        self.audioEngine.connect(reverb, to: output, format: self.audioFile.processingFormat)
*/
        //self.player.scheduleFile(self.audioFile, at: nil, completionHandler: nil)

        self.player.scheduleFile(self.audioFile, at: nil) {
            //self.audioEngine.mainMixerNode.removeTap(onBus: 0)
            //let nodeTime: AVAudioTime = self.player.lastRenderTime!
            //let playerTime: AVAudioTime = self.player.playerTime(forNodeTime: nodeTime)!
            //let currentTime = (Double(playerTime.sampleTime) / sampleRate)
            //print(currentTime)
            //self.audioEngine.stop()
        }

        self.player.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] (a: AVAudioPCMBuffer, t: AVAudioTime) in
            a.audioBufferList
            guard
                let self = self,
                let nodeTime: AVAudioTime = self.player.lastRenderTime,
                let playerTime: AVAudioTime = self.player.playerTime(forNodeTime: t)
            else { return }

            let currentTime = (Double(playerTime.sampleTime) / sampleRate)
            if currentTime >= duration {
                self.player.stop()
            }
            //print(currentTime)
        }

        self.player.play()
    }

    func pause() {
        self.player.pause()
    }

    func dispose() {
        self.player.pause()
        self.setup._dispose()
        self.triger._dispose()
        self.pipe._dispose()
    }
}

public extension CCAudio.AudioPlayer {

    // MARK: - Setup
    class Setup: CCComponentSetupProtocol {
        fileprivate var audioPlayer: CCAudio.AudioPlayer?

        fileprivate func _dispose() {
            self.audioPlayer = nil
        }
    }

    // MARK: - Triger
    class Triger: CCComponentTrigerProtocol {
        fileprivate var audioPlayer: CCAudio.AudioPlayer?
        
        public func play() throws {
            try self.audioPlayer?.play()
        }

        public func pause() {
            self.audioPlayer?.pause()
        }

        public func dispose() {
            self.audioPlayer?.dispose()
        }

        fileprivate func _dispose() {
            self.audioPlayer = nil
        }
    }

    // MARK: - Pipe
    class Pipe: NSObject, CCComponentPipeProtocol {

        // MARK: - Queue
        fileprivate let completeQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCAudio.AudioPlayer.completeQueue")

        fileprivate var audioEngine: CCAudio.AudioEngine?
        fileprivate var audioPlayer: CCAudio.AudioPlayer?

        fileprivate func _dispose() {
            self.audioPlayer = nil
        }
        
        func input(audioEngine: inout CCAudio.AudioEngine) throws -> CCAudio.AudioPlayer {
            audioEngine.engine.attach(self.audioPlayer!.player)
            let mainMixer: AVAudioMixerNode = audioEngine.engine.mainMixerNode
            audioEngine.engine.connect(self.audioPlayer!.player, to: mainMixer, format: self.audioPlayer!.audioFile.processingFormat)
            self.audioEngine = audioEngine

            return self.audioPlayer!
        }
    }
}
