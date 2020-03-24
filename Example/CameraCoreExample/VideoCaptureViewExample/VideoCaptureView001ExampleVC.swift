//
//  VideoCaptureViewExample001VC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/12/31.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import CameraCore
import iOS_DummyAVAssets
import MetalCanvas
import UIKit

class VideoCaptureView001ExampleVC: UIViewController {
    var videoCaptureProperty = CCCapture.VideoCapture.Property(
        devicePosition: AVCaptureDevice.Position.back,
        isAudioDataOutput: true,
        required: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps30),
        ],
        option: [
            .colorSpace(AVCaptureColorSpace.P3_D65),
        ]
    )
    
    var camera: CCCapture.Camera?
    var inference: CCVision.Inference?
    var videoRecorder: CCRecorder.VideoRecorder?
    @IBOutlet weak var drawView: CCView!
    
    deinit {
        self.camera?.triger.dispose()
        self.drawView.triger.dispose()
        self.inference?.triger.dispose()
        self.videoRecorder?.triger.dispose()
        CameraCore.flush()
        MCDebug.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)
            let inference: CCVision.Inference = CCVision.Inference()
            let videoRecorder: CCRecorder.VideoRecorder = try CCRecorder.VideoRecorder()
            //try camera --> imageRecognition --> self.drawView
            try camera --> self.drawView
            try camera --> videoRecorder
            camera.triger.start()
            self.camera = camera
            self.inference = inference
            self.videoRecorder = videoRecorder
        } catch {
            
        }

    }
}
