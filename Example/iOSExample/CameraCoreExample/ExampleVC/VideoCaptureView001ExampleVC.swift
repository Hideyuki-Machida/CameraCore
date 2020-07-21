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

    @IBOutlet weak var drawView: CCView!
    
    deinit {
        self.camera?.triger.dispose()
        self.drawView.triger.dispose()
        CameraCore.flush()
        ProcessLogger.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)
            try camera --> self.drawView
            camera.triger.start()
            self.camera = camera
        } catch {
            
        }

    }
}
