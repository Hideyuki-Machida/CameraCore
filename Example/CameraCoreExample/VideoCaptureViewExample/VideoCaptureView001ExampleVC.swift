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
    var imageRecognition: CCVision.ImageRecognition?
    @IBOutlet weak var drawView: CCView!
    
    deinit {
        MCDebug.deinitLog(self)
        //self.camera.rem
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)
            let imageRecognition: CCVision.ImageRecognition = CCVision.ImageRecognition()
            //try camera --> imageRecognition --> self.drawView
            try camera --> self.drawView
            camera.triger.play()
            self.camera = camera
            self.imageRecognition = imageRecognition
        } catch {
            
        }

    }
}
