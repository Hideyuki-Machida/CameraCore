//
//  RTMPExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/08/03.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import CameraCore
import iOS_DummyAVAssets
import MetalCanvas
import UIKit
import ProcessLogger_Swift
import HaishinKit
import VideoToolbox

//MARK: - ViewController

class RTMPExampleVC: UIViewController {

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // RTMP設定
    enum RTMP: String {
        case url = "rtmpURL"
        case streamKey = "streamKey"
    }

    enum VideoBitrate: Int {
        case b256 = 256
        case b512 = 512
        case b1024 = 1024

        func byte() -> Int {
            return self.rawValue * 1024
        }
    }

    private var rtmpConnection: RTMPConnection = RTMPConnection()
    private var rtmpStream: RTMPStream!
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // コンポーネント設定
    var videoCaptureProperty: CCCapture.VideoCapture.Property = CCCapture.VideoCapture.Property(
        devicePosition: AVCaptureDevice.Position.back,
        deviceType: .builtInDualCamera,
        isAudioDataOutput: false,
        required: [
            .captureSize(Settings.PresetSize.p1280x720)
        ],
        option: []
    )

    private var camera: CCCapture.Camera?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    private var audioEngine: CCAudio.AudioEngine!
    private var audioPlayer: CCAudio.AudioPlayer!
    @IBOutlet weak var drawView: CCView!
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    deinit {
        self.camera?.triger.dispose()
        self.drawView.triger.dispose()
        self.debugger.triger.stop()
        self.debugger.triger.dispose()

        self.rtmpConnection.close()
        self.rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        self.rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        self.rtmpStream?.paused = true
        self.rtmpStream?.dispose()

        CameraCore.flush()
        ProcessLogger.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // RTMP設定
        self.rtmpStream = RTMPStream(connection: self.rtmpConnection)
        self.rtmpStream.audioSettings = [
            .muted: false,
            .bitrate: 32 * 1024,
        ]
        self.rtmpStream.videoSettings = [
            .width: 720 / 2,
            .height: 1280 / 2,
            .bitrate: VideoBitrate.b256.byte(),
            .profileLevel: kVTProfileLevel_H264_Baseline_3_1
        ]

        if RTMP.url.rawValue.contains("rtmp://") {
            self.rtmpStream.publish(RTMP.streamKey.rawValue)
            self.rtmpStream?.paused = true
        } else {
            self.connectButton.setTitle("RTMPのつなぎ先をコード内に記述してください。", for: UIControl.State.normal)
            self.connectButton.isUserInteractionEnabled = false
            self.connectButton.isEnabled = false
        }
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////

        do {
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // Camera コンポーネント設定
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)

            try camera --> self.drawView

            camera.pipe.videoCaptureItem.bind { [weak self] (captureData: CCCapture.VideoCapture.CaptureData?) in
                guard let captureData: CCCapture.VideoCapture.CaptureData = captureData else { return }
                // 映像配信
                self?.rtmpStream.appendSampleBuffer( captureData.sampleBuffer, withType: AVMediaType.video )
            }

            camera.triger.start()
            self.camera = camera
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////

            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // Audio コンポーネント設定
            let audioUrl: URL = iOS_DummyAVAssets.DummyAssetManager.AudioAsset.svg_girl_theme_01.url
            self.audioEngine = CCAudio.AudioEngine()
            self.audioPlayer = try CCAudio.AudioPlayer(url: audioUrl)
            self.audioPlayer.volume = 0.05
            self.audioEngine.pipe.audioCaptureItem.bind { [weak self] (sampleBuffer: CMSampleBuffer?) in
                guard let sampleBuffer: CMSampleBuffer = sampleBuffer else { return }
                // 音声配信
                self?.rtmpStream.appendSampleBuffer( sampleBuffer, withType: AVMediaType.audio)
            }
            
            try self.audioEngine --> self.audioPlayer
            try self.audioEngine.triger.start()
            try self.audioPlayer.triger.play()
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////

            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // デバッガー設定
            try self.debugger.setup.set(component: camera)
            try self.debugger.setup.set(component: self.drawView)
            self.setDebuggerView()
            self.debugger.triger.start()
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        } catch {
            
        }

    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // RTMP配信コントロール
    @IBOutlet weak var connectButton: UIButton!
    @IBAction func connectTapAction(_ sender: Any) {
        if !self.rtmpConnection.connected {
            // 配信開始
            self.rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
            self.rtmpConnection.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
            self.rtmpConnection.connect(RTMP.url.rawValue)
            self.rtmpStream.paused = false
        } else {
            self.rtmpConnection.close()
            self.rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
            self.rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
            self.rtmpStream.paused = true
            self.connectButton.setTitle("配信開始", for: UIControl.State.normal)
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
}


//MARK: - DebuggerView

extension RTMPExampleVC {
    public func setDebuggerView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let debugView: DebugView = Bundle.main.loadNibNamed("DebugView", owner: self, options: nil)?.first as! DebugView
            self.view.addSubview(debugView)

            self.debugger.outPut.data.bind() { (data: CCDebug.ComponentDebugger.Output.Data) in
                DispatchQueue.main.async {
                    debugView.set(debugData: data)
                }
            }

        }
    }
}


extension RTMPExampleVC {
    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        print("🍏rtmpStatusHandler:", code)

        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            DispatchQueue.main.async { [weak self] in
                self?.connectButton.setTitle("配信停止", for: UIControl.State.normal)
            }
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            DispatchQueue.main.async { [weak self] in
                self?.connectButton.setTitle("配信開始", for: UIControl.State.normal)

                let action: UIAlertController = UIAlertController(title: "ConnectClosed", message: "", preferredStyle: UIAlertController.Style.alert)

                let cancel: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: {
                    (_: UIAlertAction!) -> Void in
                })

                action.addAction(cancel)

                self?.present(action, animated: true, completion: nil)
            }
        default:
            break
        }
    }

    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        print("🍎rtmpErrorHandler:", notification)
    }
}
