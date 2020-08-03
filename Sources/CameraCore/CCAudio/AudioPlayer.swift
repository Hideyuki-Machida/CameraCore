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
        public let setup: CCAudio.AudioEngine.Setup = CCAudio.AudioEngine.Setup()
        public let triger: CCAudio.AudioEngine.Triger = CCAudio.AudioEngine.Triger()
        public let pipe: CCAudio.AudioEngine.Pipe = CCAudio.AudioEngine.Pipe()
        public var debug: CCComponentDebug?

        let audioFile: AVAudioFile
        var audioEngine: AVAudioEngine = AVAudioEngine()
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
            self.audioEngine.attach(self.player)
            let mainMixer: AVAudioMixerNode = self.audioEngine.mainMixerNode

            self.audioEngine.connect(player, to: mainMixer, format: audioFile.processingFormat)
        }
    }
}


public extension CCAudio.AudioPlayer {
    func play() throws {
        let sampleRate: Double = self.audioFile.fileFormat.sampleRate
        let length: AVAudioFramePosition = self.audioFile.length
        let duration = Double(length) / sampleRate
        var output = self.audioEngine.outputNode
        
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
        //self.setup._dispose()
        //self.triger._dispose()
        //self.pipe._dispose()
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

        fileprivate var audioPlayer: CCAudio.AudioPlayer?

        fileprivate func _dispose() {
            self.audioPlayer = nil
        }
        
        func input(audioEngine: inout CCAudio.AudioEngine) throws -> CCAudio.AudioPlayer {
            let audioEngine: AVAudioEngine = audioEngine.engine
            audioEngine.attach(self.audioPlayer!.player)

            let mainMixer: AVAudioMixerNode = audioEngine.mainMixerNode

            audioEngine.connect(self.audioPlayer!.player, to: mainMixer, format: self.audioPlayer!.audioFile.processingFormat)
            return self.audioPlayer!
        }
    }

    func pipe(audioEngine: inout AVAudioEngine) throws -> CCAudio.AudioPlayer {
        self.audioEngine = audioEngine
        self.audioEngine.attach(self.player)
        let mainMixer: AVAudioMixerNode = self.audioEngine.mainMixerNode

        self.audioEngine.connect(player, to: mainMixer, format: audioFile.processingFormat)
        return self
    }
}
