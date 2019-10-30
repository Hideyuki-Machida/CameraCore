
//
//  MetalVideoCaptureViewExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/12/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import MetalCanvas
import CameraCore
import iOS_DummyAVAssets

class VideoCaptureView002ExampleVC: UIViewController {

    @IBOutlet weak var videoCaptureView: CameraCore.VideoCaptureView!
    @IBOutlet weak var recordingButton: UIButton!

    var lutLayer: LutLayer!

    var videoCaputurePropertys = CCRenderer.VideoCapture.Propertys.init(
        
        devicePosition: AVCaptureDevice.Position.back,
        isAudioDataOutput: true,
        required: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps30),
            .isDepthDataOut(false)
        ],
        option: [
            .colorSpace(AVCaptureColorSpace.P3_D65)
        ]
    )


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
        event.onPreviewUpdate = { (sampleBuffer: CMSampleBuffer) in
            //print(sampleBuffer)
        }
        event.onPixelUpdate = { (pixelBuffer: CVPixelBuffer) in
            //print(pixelBuffer)
        }
        event.onDepthDataUpdate = { (depthData: AVDepthData?) in
            guard let depthData = depthData else { return }
            print(depthData)
        }
        event.onMetadataObjectsUpdate = { (metadataObjects: [AVMetadataObject]?) in
            guard let metadataObjects = metadataObjects else { return }
            print(metadataObjects)
        }

        self.videoCaptureView.event = event
        do {
            self.lutLayer = try LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: LutLayer.Dimension.d3)

            try self.videoCaptureView.setup(self.videoCaputurePropertys)
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

    @IBAction func setDeviceTypeBtnTapAction(_ sender: UIButton) {
        self.setDeviceType()
    }

    @IBAction func setFPSBtnTapAction(_ sender: UIButton) {
        self.setFPS()
    }

    @IBAction func setPresetiFrameBtnTapAction(_ sender: UIButton) {
        self.setResolution()
    }

    @IBAction func setTouchBtnTapAction(_ sender: UIButton) {
        self.setTouch()
    }

    @IBAction func setPositionBtnTapAction(_ sender: UIButton) {
        self.setPosition()
    }

    @IBAction func setFilterBtnTapAction(_ sender: UIButton) {
        self.setFilter()
    }

    @IBAction func setMetaDataOutBtnTapAction(_ sender: UIButton) {
        self.setMetaDataOut()
    }

    @IBAction func setDepthDataOutBtnTapAction(_ sender: UIButton) {
        self.setDepthDataOut()
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
                        videoCodecType: Settings.VideoCodec.hevc
                    )
                )
                self.recordingButton.setTitle("撮影ストップ", for: UIControl.State.normal)
            } catch {
                
            }

        }
    }
    
}


extension VideoCaptureView002ExampleVC {
    
    private enum FrameRateLabel: String {
        case fps15 = "15 FPS"
        case fps24 = "24 FPS"
        case fps30 = "30 FPS"
        case fps60 = "60 FPS"
        case fps90 = "90 FPS"
        case fps120 = "120 FPS"
    }
    
    @IBAction func setFPS() {
        let action: UIAlertController = UIAlertController(title: "FPS設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let action000: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps15.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .frameRate(.fps15))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps15.rawValue)
            }
        })

        let action001: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps24.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .frameRate(.fps24))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps24.rawValue)
            }
        })
        
        let action002: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps30.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .frameRate(.fps30))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps30.rawValue)
            }
        })
        
        let action003: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps60.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .frameRate(.fps60))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps60.rawValue)
            }
        })
        
        let action004: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps90.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .frameRate(.fps90))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps90.rawValue)
            }
        })
        
        let action005: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps120.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .frameRate(.fps120))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps120.rawValue)
            }
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })

        action.addAction(action000)
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(action003)
        action.addAction(action004)
        action.addAction(action005)
        action.addAction(cancel)
        
        self.present(action, animated: true, completion: nil)
    }
}


extension VideoCaptureView002ExampleVC {
    private enum ResolutionLabel: String {
        case p960x540 = "p960x540"
        case p1280x720 = "p1280x720"
        case p1920x1080 = "p1920x1080"
    }

    func setResolution() {
        let action: UIAlertController = UIAlertController(title: "撮影解像度設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let action001: UIAlertAction = UIAlertAction(title: ResolutionLabel.p960x540.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .captureSize(.p960x540))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(ResolutionLabel.p960x540.rawValue)
            }
        })

        let action002: UIAlertAction = UIAlertAction(title: ResolutionLabel.p1280x720.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .captureSize(.p1280x720))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(ResolutionLabel.p1280x720.rawValue)
            }
        })

        let action003: UIAlertAction = UIAlertAction(title: ResolutionLabel.p1920x1080.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .captureSize(.p1920x1080))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(ResolutionLabel.p1920x1080.rawValue)
            }
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(action003)
        action.addAction(cancel)
        
        self.present(action, animated: true, completion: nil)
    }
}


extension VideoCaptureView002ExampleVC {
    private enum TouchLabel: String {
        case on = "ON"
        case off = "OFF"
    }

    func setTouch() {
        let action: UIAlertController = UIAlertController(title: "Touch設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let action001: UIAlertAction = UIAlertAction(title: TouchLabel.on.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.videoCaptureView.capture!.isTouchActive = true
        })
        
        let action002: UIAlertAction = UIAlertAction(title: TouchLabel.off.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.videoCaptureView.capture!.isTouchActive = false
        })
        
        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(cancel)
        
        self.present(action, animated: true, completion: nil)

    }
}

extension VideoCaptureView002ExampleVC {
    private enum PositionLabel: String {
        case front = "front"
        case back = "back"
    }

    func setPosition() {
        let action: UIAlertController = UIAlertController(title: "Position設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let action001: UIAlertAction = UIAlertAction(title: PositionLabel.front.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.devicePosition = .front
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(PositionLabel.front.rawValue)
            }
        })
        
        let action002: UIAlertAction = UIAlertAction(title: PositionLabel.back.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.devicePosition = .back
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(PositionLabel.back.rawValue)
            }
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(cancel)
        
        self.present(action, animated: true, completion: nil)
    }

}

extension VideoCaptureView002ExampleVC {
    private enum FilterLabel: String {
        case ON = "ON"
        case OFF = "OFF"
    }

    func setFilter() {
        let action: UIAlertController = UIAlertController(title: "Filter設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let action001: UIAlertAction = UIAlertAction(title: FilterLabel.ON.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.videoCaptureView.renderLayers = [ self.lutLayer ]
        })
        
        let action002: UIAlertAction = UIAlertAction(title: FilterLabel.OFF.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.videoCaptureView.renderLayers = []
        })
        
        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(cancel)
        
        self.present(action, animated: true, completion: nil)
    }
}

extension VideoCaptureView002ExampleVC {
    private enum DeviceType: String {
        case builtInWideAngleCamera = "builtInWideAngleCamera"
        case builtInDualCamera = "builtInDualCamera"
        case builtInTelephotoCamera = "builtInTelephotoCamera"
        case builtInTrueDepthCamera = "builtInTrueDepthCamera"
        func item() -> AVCaptureDevice.DeviceType {
            switch self {
            case .builtInWideAngleCamera: return .builtInWideAngleCamera
            case .builtInTelephotoCamera: return .builtInTelephotoCamera
            case .builtInDualCamera: return .builtInDualCamera
            case .builtInTrueDepthCamera: return .builtInTrueDepthCamera
            }
        }
    }

    func setDeviceType() {
        
        let action: UIAlertController = UIAlertController(title: "カメラデバイスタイプ設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let action001: UIAlertAction = UIAlertAction(title: DeviceType.builtInWideAngleCamera.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.deviceType = DeviceType.builtInWideAngleCamera.item()
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(DeviceType.builtInWideAngleCamera.rawValue)
            }
        })

        let action002: UIAlertAction = UIAlertAction(title: DeviceType.builtInDualCamera.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.deviceType = DeviceType.builtInDualCamera.item()
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(DeviceType.builtInDualCamera.rawValue)
            }
        })

        let action003: UIAlertAction = UIAlertAction(title: DeviceType.builtInTelephotoCamera.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.deviceType = DeviceType.builtInTelephotoCamera.item()
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(DeviceType.builtInTelephotoCamera.rawValue)
            }
        })

        let action004: UIAlertAction = UIAlertAction(title: DeviceType.builtInTrueDepthCamera.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.deviceType = DeviceType.builtInTrueDepthCamera.item()
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog(DeviceType.builtInTrueDepthCamera.rawValue)
            }
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(action003)
        action.addAction(action004)
        action.addAction(cancel)
        
        self.present(action, animated: true, completion: nil)
    }

}

extension VideoCaptureView002ExampleVC {
    private enum MetaDataLabel: String {
        case ON = "ON"
        case OFF = "OFF"
    }

    func setMetaDataOut() {
        let action: UIAlertController = UIAlertController(title: "MetaData(Face)設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let action001: UIAlertAction = UIAlertAction(title: MetaDataLabel.ON.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.metadataObjects = [.face]
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog("MetaData: " + MetaDataLabel.ON.rawValue)
            }
        })
        
        let action002: UIAlertAction = UIAlertAction(title: MetaDataLabel.OFF.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.metadataObjects = []
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog("MetaData: " + MetaDataLabel.OFF.rawValue)
            }
        })
        
        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(cancel)
        
        self.present(action, animated: true, completion: nil)
    }
}

extension VideoCaptureView002ExampleVC {
    private enum DepthLabel: String {
        case ON = "ON"
        case OFF = "OFF"
    }

    func setDepthDataOut() {
        let action: UIAlertController = UIAlertController(title: "Depth設定", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let action001: UIAlertAction = UIAlertAction(title: DepthLabel.ON.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                self.videoCaputurePropertys.devicePosition = .back
                self.videoCaputurePropertys.deviceType = DeviceType.builtInDualCamera.item()
                try self.videoCaputurePropertys.swap(property: .isDepthDataOut(true))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog("Depth: " + DepthLabel.ON.rawValue)
            }
        })
        
        let action002: UIAlertAction = UIAlertAction(title: DepthLabel.OFF.rawValue, style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            do {
                try self.videoCaputurePropertys.swap(property: .isDepthDataOut(false))
                try self.videoCaptureView.update(propertys: self.videoCaputurePropertys)
            } catch {
                MCDebug.errorLog("Depth: " + DepthLabel.OFF.rawValue)
            }
        })
        
        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            (action: UIAlertAction!) -> Void in
        })
        
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(cancel)
        
        self.present(action, animated: true, completion: nil)
    }
}
