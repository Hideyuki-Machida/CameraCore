//
//  VideoCaptureViewExample001VC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/12/31.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import CoreVideo
import AVFoundation
import CameraCore
import iOS_DummyAVAssets
import MetalCanvas
import UIKit
import ProcessLogger_Swift

class VideoCaptureView001ExampleVC: UIViewController {
    @IBOutlet weak var recordingButton: UIButton!

    var videoCaptureProperty = CCCapture.VideoCapture.Property(
        devicePosition: AVCaptureDevice.Position.back,
        isAudioDataOutput: true,
        required: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps60),
        ],
        option: [
            .colorSpace(AVCaptureColorSpace.P3_D65),
        ]
    )
    
    var camera: CCCapture.Camera?
    var videoRecorder: CCRecorder.VideoRecorder?

    @IBOutlet weak var drawView: CCView!
    
    deinit {
        self.camera?.triger.dispose()
        self.drawView.triger.dispose()
        self.videoRecorder?.triger.dispose()
        CameraCore.flush()
        ProcessLogger.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)
            try camera --> self.drawView
            let videoRecorder: CCRecorder.VideoRecorder = try CCRecorder.VideoRecorder()
            try camera --> videoRecorder
            camera.triger.start()
            self.camera = camera
            self.videoRecorder = videoRecorder
        } catch {
            
        }

    }

    @IBAction func recordingTapAction(_ sender: Any) {

        if self.videoRecorder?.isRecording == true {
            self.videoRecorder?.triger.stop()
            self.recordingButton.setTitle("撮影開始", for: UIControl.State.normal)
        } else {
            let filePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + "recordingVideo" + NSUUID().uuidString + ".mp4"
            let size: MCSize = Settings.PresetSize.p1280x720.size(orientation: AVCaptureVideoOrientation.portrait)
            do {
                let parameter: CCRecorder.CaptureWriter.Parameter = CCRecorder.CaptureWriter.Parameter(
                    outputFilePath: URL(fileURLWithPath: filePath),
                    presetFrame: Settings.PresetSize.p1280x720,
                    frameRate: 30,
                    devicePosition: AVCaptureDevice.Position.back,
                    croppingRect: CGRect(origin: CGPoint(), size: size.toCGSize()),
                    fileType: AVFileType.mp4,
                    videoCodecType: Settings.VideoCodec.hevc
                )
                try self.videoRecorder?.setup.setup(parameter: parameter)
                self.videoRecorder?.triger.start()
                self.recordingButton.setTitle("撮影ストップ", for: UIControl.State.normal)
            } catch {}
        }

    }
}
