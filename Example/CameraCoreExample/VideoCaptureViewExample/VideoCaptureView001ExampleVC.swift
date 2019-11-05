//
//  VideoCaptureView001ExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/10/15.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import UIKit
import AVFoundation
import MetalCanvas
import CameraCore
import iOS_DummyAVAssets

class VideoCaptureView001ExampleVC: UIViewController {
        
    @IBOutlet weak var videoCaptureView: CameraCore.VideoCaptureView!
    @IBOutlet weak var recordingButton: UIButton!
    
    deinit {
        self.videoCaptureView.pause()
        self.videoCaptureView.dispose()
        MCDebug.deinitLog(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let event: VideoCaptureViewEvent = VideoCaptureViewEvent()
        event.onRecodingUpdate = { (recordedDuration: TimeInterval) in
            print(recordedDuration)
        }
        event.onRecodingComplete = { (result: Bool, filePath: URL) in
            print(result)
            print(filePath)
            if result {
            } else {
            }
        }
        event.onFrameUpdate = { (sampleBuffer: CMSampleBuffer, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]) in
            //print(sampleBuffer)
        }

        self.videoCaptureView.event = event
        do {
            try self.videoCaptureView.setup()
        } catch {
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCaptureView.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCaptureView.pause()
        self.videoCaptureView.dispose()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func recordingTapAction(_ sender: Any) {
        if self.videoCaptureView.isRecording {
            self.videoCaptureView.recordingStop()
            self.recordingButton.setTitle("撮影開始", for: UIControl.State.normal)
        } else {
            let filePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + "recordingVideo" + NSUUID().uuidString + ".mp4"

            do {
                try self.videoCaptureView.recordingStart(
                    CCRenderer.VideoCapture.CaptureWriter.Paramator.init(
                        outputFilePath: URL.init(fileURLWithPath: filePath),
                        presetiFrame: Settings.PresetSize.p1280x720,
                        frameRate: .fps60,
                        devicePosition: AVCaptureDevice.Position.back,
                        croppingRect: CGRect.init(origin: CGPoint.init(), size: Settings.PresetSize.p1280x720.size()),
                        fileType: AVFileType.mp4,
                        videoCodecType: Settings.VideoCodec.h264
                    )
                )
                self.recordingButton.setTitle("撮影ストップ", for: UIControl.State.normal)
            } catch {
                
            }

        }
    }

}
