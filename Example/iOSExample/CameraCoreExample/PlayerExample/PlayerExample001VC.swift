//
//  PlayerExample001VC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/03/31.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import CameraCore
import iOS_DummyAVAssets
import MetalCanvas
import UIKit
import ProcessLogger_Swift

class PlayerExample001VC: UIViewController {
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
    
    private var debuggerObservation: NSKeyValueObservation?
    private var observations: [NSKeyValueObservation] = []
    private var player: CCPlayer = CCPlayer()
    private var imageProcess: CCImageProcess.ImageProcess?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    @IBOutlet weak var drawView: CCView!
    @IBOutlet weak var seekBar: UISlider!
    
    deinit {
        self.debuggerObservation?.invalidate()
        self.player.triger.dispose()
        self.drawView.triger.dispose()
        self.debugger.triger.dispose()
        self.observations.forEach { $0.invalidate() }
        self.observations.removeAll()

        CameraCore.flush()
        ProcessLogger.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //let url: URL = iOS_DummyAVAssets.AssetManager.VideoAsset.portrait002.url
        //let url: URL = URL(string: "https://devimages.apple.com.edgekey.net/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8")!
        //let url: URL = URL(string: "https://video-dev.github.io/streams/x36xhzz/x36xhzz.m3u8")!
        let url: URL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!
        //let url: URL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!
        
        
        //let imageProcess: CCImageProcess.ImageProcess = CCImageProcess.ImageProcess(isDisplayLink: true)
        do {
            //try self.player --> imageProcess --> self.drawView
            try self.player --> self.drawView
            self.player.setup.update(url: url)

            /*
            let playerStatusObservation: NSKeyValueObservation = self.player.event.observe(\.statuss, options: [.new]) { [weak self] (object: CCPlayer.Event, change) in
                guard
                    let self = self,
                    let statusId: Int = change.newValue,
                    let status: CCPlayer.Status = CCPlayer.Status.init(rawValue: statusId)
                else { return }
            }
            self.observations.append(playerStatusObservation)
*/
            let playerObservation: NSKeyValueObservation = self.player.event.observe(\.outProgress, options: [.new]) { [weak self] (object: CCPlayer.Event, change) in
                guard
                    let self = self,
                    let progress: TimeInterval = change.newValue
                else { return }

                DispatchQueue.main.async { [weak self] in
                    self?.seekBar.value = Float(progress)
                }
            }
            self.observations.append(playerObservation)

            //self.imageProcess = imageProcess

            try self.debugger.setup.set(component: self.player)
            try self.debugger.setup.set(component: self.drawView)

            self.debugger.triger.start()
            self.setDebuggerView()
        } catch {
            
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.player.triger.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.player.triger.pause()
    }

    
    @IBAction func seek(_ sender: UISlider) {
        self.player.triger.seek(progress: sender.value)
    }
    @IBAction func seekOut(_ sender: UISlider) {
        self.player.triger.play()
    }
}

extension PlayerExample001VC {
    public func setDebuggerView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let debugView: DebugView = Bundle.main.loadNibNamed("DebugView", owner: self, options: nil)?.first as! DebugView
            self.view.addSubview(debugView)

            self.debuggerObservation?.invalidate()
            self.debuggerObservation = self.debugger.outPut.observe(\.onUpdate, options: [.new]) { [weak self] (debuggerOutput: CCDebug.ComponentDebugger.Output, _) in
                DispatchQueue.main.async { [weak self] in
                    debugView.set(debugData: debuggerOutput.data)
                }
            }

        }
    }
}
