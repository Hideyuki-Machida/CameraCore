
//
//  MetalVideoCaptureViewExampleVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/12/17.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import CameraCore
import iOS_DummyAVAssets
import MetalCanvas
import UIKit

class VideoCaptureView002ExampleVC: UIViewController {
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var drawView: CCView!

    private var camera: CCCapture.Camera?
    private var imageProcess: CCImageProcess.ImageProcess?
    private var videoRecorder: CCRecorder.VideoRecorder?
    private var debugger: CCDebug.DebuggerC = CCDebug.DebuggerC()
    private var lutLayer: CCImageProcess.LutLayer!

    private var debuggerObservation: NSKeyValueObservation?
    
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

    deinit {
        self.camera?.triger.stop()
        self.camera?.triger.dispose()
        self.imageProcess?.triger.dispose()
        self.videoRecorder?.triger.dispose()
        self.drawView.triger.dispose()
        self.debugger.triger.stop()
        self.debugger.triger.dispose()

        MCDebug.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /////////////////////////////////////////////////////////////////////////////////////////////
        // VideoCaptureViewのイベント設定
        let event: CCCapture.Camera.Event = CCCapture.Camera.Event()

        // VideoCaptureViewにイベントをセット

        /////////////////////////////////////////////////////////////////////////////////////////////

        /////////////////////////////////////////////////////////////////////////////////////////////
        // VideoCaptureViewのセットアップ
        do {
            // RenderLayerでLutフィルターを設定
            self.lutLayer = try CCImageProcess.LutLayer(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: .dim3)

            // VideoCapturePropertyをセット
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)
            let imageProcess: CCImageProcess.ImageProcess = CCImageProcess.ImageProcess(isDisplayLink: false)
            let videoRecorder: CCRecorder.VideoRecorder = try CCRecorder.VideoRecorder()

            try camera --> imageProcess --> self.drawView
            try imageProcess --> videoRecorder

            camera.event = event
            camera.triger.start()
            
            self.camera = camera
            self.imageProcess = imageProcess
            self.videoRecorder = videoRecorder

            try self.debugger.setup.set(component: camera)
            try self.debugger.setup.set(component: imageProcess)
            try self.debugger.setup.set(component: self.drawView)
        } catch {
            MCDebug.errorLog("VideoCaptureView setup error")
        }
        /////////////////////////////////////////////////////////////////////////////////////////////
        
        self.setDebuggerView()
        self.debugger.triger.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // VideoCaptureViewのキャプチャスタート
        self.camera?.triger.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // VideoCaptureViewのキャプチャ停止
        self.camera?.triger.stop()
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

    @IBAction func setPresetFrameBtnTapAction(_ sender: UIButton) {
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

    @IBAction func recordingTapAction(_ sender: Any) {
        /*
        if self.videoCaptureView.isRecording {
            self.videoCaptureView.recordingStop()
            self.recordingButton.setTitle("撮影開始", for: UIControl.State.normal)
        } else {
            let filePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + "recordingVideo" + NSUUID().uuidString + ".mp4"

            do {
                try self.videoCaptureView.recordingStart(
                    CCRenderer.VideoCapture.CaptureWriter.Parameter(
                        outputFilePath: URL(fileURLWithPath: filePath),
                        presetFrame: Settings.PresetSize.p1280x720,
                        frameRate: 30,
                        devicePosition: AVCaptureDevice.Position.back,
                        croppingRect: CGRect(origin: CGPoint(), size: Settings.PresetSize.p1280x720.size()),
                        fileType: AVFileType.mp4,
                        videoCodecType: Settings.VideoCodec.hevc
                    )
                )
                self.recordingButton.setTitle("撮影ストップ", for: UIControl.State.normal)
            } catch {}
        }
         */
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
        case fps240 = "240 FPS"
    }

    @IBAction func setFPS() {
        let action: UIAlertController = UIAlertController(title: "FPS設定", message: "", preferredStyle: UIAlertController.Style.actionSheet)

        let action000: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps15.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .frameRate(.fps15))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps15.rawValue)
            }
        })

        let action001: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps24.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .frameRate(.fps24))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps24.rawValue)
            }
        })

        let action002: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps30.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .frameRate(.fps30))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps30.rawValue)
            }
        })

        let action003: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps60.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .frameRate(.fps60))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps60.rawValue)
            }
        })

        let action004: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps90.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .frameRate(.fps90))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps90.rawValue)
            }
        })

        let action005: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps120.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .frameRate(.fps120))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps120.rawValue)
            }
        })

        let action006: UIAlertAction = UIAlertAction(title: FrameRateLabel.fps240.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .frameRate(.fps240))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(FrameRateLabel.fps240.rawValue)
            }
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
            (_: UIAlertAction!) -> Void in
        })

        action.addAction(action000)
        action.addAction(action001)
        action.addAction(action002)
        action.addAction(action003)
        action.addAction(action004)
        action.addAction(action005)
        action.addAction(action006)
        action.addAction(cancel)

        self.present(action, animated: true, completion: nil)
    }
}

extension VideoCaptureView002ExampleVC {
    private enum ResolutionLabel: String {
        case p960x540
        case p1280x720
        case p1920x1080
    }

    func setResolution() {
        let action: UIAlertController = UIAlertController(title: "撮影解像度設定", message: "", preferredStyle: UIAlertController.Style.actionSheet)

        let action001: UIAlertAction = UIAlertAction(title: ResolutionLabel.p960x540.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .captureSize(.p960x540))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(ResolutionLabel.p960x540.rawValue)
            }
        })

        let action002: UIAlertAction = UIAlertAction(title: ResolutionLabel.p1280x720.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .captureSize(.p1280x720))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(ResolutionLabel.p1280x720.rawValue)
            }
        })

        let action003: UIAlertAction = UIAlertAction(title: ResolutionLabel.p1920x1080.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                try self.videoCaptureProperty.swap(property: .captureSize(.p1920x1080))
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(ResolutionLabel.p1920x1080.rawValue)
            }
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
            (_: UIAlertAction!) -> Void in
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
        let action: UIAlertController = UIAlertController(title: "Touch設定", message: "", preferredStyle: UIAlertController.Style.actionSheet)

        let action001: UIAlertAction = UIAlertAction(title: TouchLabel.on.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            self.camera?.capture!.isTorchActive = true
        })

        let action002: UIAlertAction = UIAlertAction(title: TouchLabel.off.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            self.camera?.capture!.isTorchActive = false
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
            (_: UIAlertAction!) -> Void in
        })

        action.addAction(action001)
        action.addAction(action002)
        action.addAction(cancel)

        self.present(action, animated: true, completion: nil)
    }
}

extension VideoCaptureView002ExampleVC {
    private enum PositionLabel: String {
        case front
        case back
    }

    func setPosition() {
        let action: UIAlertController = UIAlertController(title: "Position設定", message: "", preferredStyle: UIAlertController.Style.actionSheet)

        let action001: UIAlertAction = UIAlertAction(title: PositionLabel.front.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                self.videoCaptureProperty.devicePosition = .front
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(PositionLabel.front.rawValue)
            }
        })

        let action002: UIAlertAction = UIAlertAction(title: PositionLabel.back.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                self.videoCaptureProperty.devicePosition = .back
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(PositionLabel.back.rawValue)
            }
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
            (_: UIAlertAction!) -> Void in
        })

        action.addAction(action001)
        action.addAction(action002)
        action.addAction(cancel)

        self.present(action, animated: true, completion: nil)
    }
}

extension VideoCaptureView002ExampleVC {
    private enum FilterLabel: String {
        case ON
        case OFF
    }

    func setFilter() {
        let action: UIAlertController = UIAlertController(title: "Filter設定", message: "", preferredStyle: UIAlertController.Style.actionSheet)

        let action001: UIAlertAction = UIAlertAction(title: FilterLabel.ON.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            self.imageProcess?.renderLayers = [self.lutLayer, self.lutLayer, self.lutLayer, self.lutLayer, self.lutLayer, self.lutLayer]
        })

        let action002: UIAlertAction = UIAlertAction(title: FilterLabel.OFF.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            self.imageProcess?.renderLayers = []
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
            (_: UIAlertAction!) -> Void in
        })

        action.addAction(action001)
        action.addAction(action002)
        action.addAction(cancel)

        self.present(action, animated: true, completion: nil)
    }
}

extension VideoCaptureView002ExampleVC {
    private enum DeviceType: String {
        case builtInWideAngleCamera
        case builtInDualCamera
        case builtInTelephotoCamera
        func item() -> AVCaptureDevice.DeviceType {
            switch self {
            case .builtInWideAngleCamera: return .builtInWideAngleCamera
            case .builtInTelephotoCamera: return .builtInTelephotoCamera
            case .builtInDualCamera: return .builtInDualCamera
            }
        }
    }

    func setDeviceType() {
        let action: UIAlertController = UIAlertController(title: "カメラデバイスタイプ設定", message: "", preferredStyle: UIAlertController.Style.actionSheet)

        let action001: UIAlertAction = UIAlertAction(title: DeviceType.builtInWideAngleCamera.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                self.videoCaptureProperty.deviceType = DeviceType.builtInWideAngleCamera.item()
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(DeviceType.builtInWideAngleCamera.rawValue)
            }
        })

        let action002: UIAlertAction = UIAlertAction(title: DeviceType.builtInDualCamera.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                self.videoCaptureProperty.deviceType = DeviceType.builtInDualCamera.item()
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(DeviceType.builtInDualCamera.rawValue)
            }
        })

        let action003: UIAlertAction = UIAlertAction(title: DeviceType.builtInTelephotoCamera.rawValue, style: UIAlertAction.Style.default, handler: {
            (_: UIAlertAction!) -> Void in
            do {
                self.videoCaptureProperty.deviceType = DeviceType.builtInTelephotoCamera.item()
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } catch {
                MCDebug.errorLog(DeviceType.builtInTelephotoCamera.rawValue)
            }
        })

        let cancel: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
            (_: UIAlertAction!) -> Void in
        })

        action.addAction(action001)
        action.addAction(action002)
        action.addAction(action003)
        action.addAction(cancel)

        self.present(action, animated: true, completion: nil)
    }
}


extension VideoCaptureView002ExampleVC {
    public func setDebuggerView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let debugView: DebugView = Bundle.main.loadNibNamed("DebugView", owner: self, options: nil)?.first as! DebugView
            self.view.addSubview(debugView)

            self.debuggerObservation?.invalidate()
            self.debuggerObservation = self.debugger.outPut.observe(\.onUpdate, options: [.new]) { [weak self] (debuggerOutput: CCDebug.DebuggerC.Output, _) in
                DispatchQueue.main.async { [weak self] in
                    debugView.set(debugData: debuggerOutput.data)
                }
            }

        }
    }
}
