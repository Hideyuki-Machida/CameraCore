//
//  AudioRecorder.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/17.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation

extension CCRecorder {
    public class AudioRecorder {
        var audioFile: AVAudioFile?
        public var isRecording: Bool = false

        public init() throws {
        }
    }
}

public extension CCRecorder.AudioRecorder {
    func setup(parameter: CCRecorder.CaptureWriter.Parameter) {
        CCRecorder.CaptureWriter.setup(parameter)
    }

    func start() throws {
        self.isRecording = true
        
        
        let format: AVAudioFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16,
        sampleRate: 44100.0,
        channels: 1,
        interleaved: true)!

        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath = URL(fileURLWithPath: documentDir + "/sample.caf")

        // オーディオファイル
        self.audioFile = try AVAudioFile(forWriting: filePath, settings: format.settings)
    }
    
    func stop() {
        self.isRecording = false
    }
}

extension CCRecorder.AudioRecorder {
    func pipe(audioEngine: CCAudio.AudioEngine) throws {
        /*
        audioEngine.onUpdatePCMBuffer = { [weak self] (pcmBuffer: AVAudioPCMBuffer) in
            guard self?.isRecording == true else { return }
            do {
                try self?.audioFile?.write(from: pcmBuffer)
            } catch {
                
            }
        }
 */
    }
}
