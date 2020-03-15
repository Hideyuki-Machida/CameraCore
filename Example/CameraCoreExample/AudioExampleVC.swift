//
//  AudioExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/02/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import CameraCore
import iOS_DummyAVAssets
import UIKit

class AudioExampleVC: UIViewController {

    @IBOutlet weak var recordingButton: UIButton!

    var videoCaptureProperty = CCCapture.VideoCapture.Property(
        devicePosition: AVCaptureDevice.Position.back,
        isAudioDataOutput: false,
        required: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps30),
        ],
        option: [
            .colorSpace(AVCaptureColorSpace.P3_D65),
        ]
    )

    var camera: CCCapture.Camera!
    var audioEngine: CCAudio.AudioEngine!
    var audioPlayer: CCAudio.AudioPlayer!
    var audioMic: CCAudio.Mic!
    var videoRecorder: CCRecorder.VideoRecorder!
    var audioRecorder: CCRecorder.AudioRecorder!
    
    override func viewDidLoad() {
        do {
            self.videoRecorder = try CCRecorder.VideoRecorder()
            self.audioRecorder = try CCRecorder.AudioRecorder()

            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)
            self.camera = camera
            try self.camera --> self.videoRecorder

            let audioUrl: URL = iOS_DummyAVAssets.AssetManager.AudioAsset.svg_girl_theme_01.url
            self.audioEngine = CCAudio.AudioEngine()
            self.audioPlayer = try CCAudio.AudioPlayer(url: audioUrl)
            self.audioPlayer.volume = 0.05
            self.audioMic = try CCAudio.Mic()
            self.audioMic.volume = 1.0

            
            try self.audioEngine --> self.audioPlayer
            try self.audioEngine --> self.audioMic
            try self.audioEngine --> self.videoRecorder
            try self.audioEngine --> self.audioRecorder
            try self.audioEngine.start()
        } catch {
            print("error")
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            self.camera?.triger.play()
            try self.audioPlayer?.play()
        } catch {
            print("error")
        }
    }
    
    
    @IBAction func micSlider(slider: UISlider){
        self.audioMic.volume = slider.value
    }

    @IBAction func playerSlider(slider: UISlider){
        self.audioPlayer.volume = slider.value
    }

    
    @IBAction func recordingTapAction(_ sender: Any) {
        self.videoRecording()
        //self.audioRecording()
    }

}

extension AudioExampleVC {
    func videoRecording() {
        if self.videoRecorder.isRecording {
            self.recordingButton.setTitle("撮影開始", for: UIControl.State.normal)
            self.videoRecorder.stop()
        } else {
            let filePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + "recordingVideo" + NSUUID().uuidString + ".mp4"

            do {
                var param = CCRecorder.CaptureWriter.Parameter(
                    outputFilePath: URL(fileURLWithPath: filePath),
                    presetFrame: Settings.PresetSize.p1280x720,
                    frameRate: 30,
                    devicePosition: AVCaptureDevice.Position.back,
                    croppingRect: CGRect(origin: CGPoint(), size: Settings.PresetSize.p1280x720.size(orientation: UIInterfaceOrientation.portrait).toCGSize()),
                    fileType: AVFileType.mp4,
                    videoCodecType: Settings.VideoCodec.hevc
                )

                try self.videoRecorder.setup(parameter: param)
                self.videoRecorder.start()
                self.recordingButton.setTitle("撮影ストップ", for: UIControl.State.normal)
            } catch {}
        }
    }
}

extension AudioExampleVC {
    func audioRecording() {
        if self.audioRecorder.isRecording {
            self.recordingButton.setTitle("撮影開始", for: UIControl.State.normal)
            self.audioRecorder.stop()
        } else {
            do {
                try self.audioRecorder.start()
                self.recordingButton.setTitle("撮影ストップ", for: UIControl.State.normal)
            } catch {
                
            }
        }
    }
}
