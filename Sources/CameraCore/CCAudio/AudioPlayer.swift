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
        print(duration)
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

        self.player.installTap(onBus: 0, bufferSize: 4096, format: nil) { (a: AVAudioPCMBuffer, t: AVAudioTime) in
            a.audioBufferList
            guard let nodeTime: AVAudioTime = self.player.lastRenderTime else { return }
            guard let playerTime: AVAudioTime = self.player.playerTime(forNodeTime: t) else { return }
            let currentTime = (Double(playerTime.sampleTime) / sampleRate)
            if currentTime >= duration {
                self.player.stop()
            }
            print(currentTime)
        }

        self.player.play()
    }
    /*
    func hasNothingMethod(frameCount: AVAudioFrameCount, bufferList: UnsafeMutablePointer<AudioBufferList>, status: UnsafeMutablePointer<OSStatus>?) -> AVAudioEngineManualRenderingStatus {
        print(11111)
    }
 */
}


extension CCAudio.AudioPlayer {
    func pipe(audioEngine: inout AVAudioEngine) throws -> CCAudio.AudioPlayer {
        self.audioEngine = audioEngine
        self.audioEngine.attach(self.player)
        let mainMixer: AVAudioMixerNode = self.audioEngine.mainMixerNode

        self.audioEngine.connect(player, to: mainMixer, format: audioFile.processingFormat)
        return self
    }
}
