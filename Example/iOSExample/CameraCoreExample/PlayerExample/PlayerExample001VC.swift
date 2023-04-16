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

    private var player: CCPlayer = CCPlayer()
    private var imageProcess: CCImageProcess.ImageProcess?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    @IBOutlet weak var drawView: CCView!
    @IBOutlet weak var seekBar: UISlider!
    
    deinit {
        self.player.trigger.dispose()
        self.drawView.trigger.dispose()
        self.debugger.trigger.dispose()

        CameraCore.flush()
        ProcessLogger.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //let url: URL = iOS_DummyAVAssets.AssetManager.VideoAsset.portrait002.url
        //let url: URL = URL(fileURLWithPath: "https://devimages.apple.com.edgekey.net/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8")
        //let url: URL = URL(string: "https://devimages.apple.com.edgekey.net/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8")!
        //let url: URL = URL(string: "https://video-dev.github.io/streams/x36xhzz/x36xhzz.m3u8")!
        let url: URL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!
        //let url: URL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!
        //let url: URL = URL(string: "http://infinite-set.heteml.jp/hls/h264_256/playlist.m3u8")!
        //let url: URL = URL(string: "http://infinite-set.heteml.jp/hls/h265_256/output.m3u8")!
        //let url: URL = URL(string: "http://infinite-set.heteml.jp/hls/h265_256_ts/output.m3u8")!
        //let url: URL = URL(string: "http://infinite-set.heteml.jp/hls/h264_256_fmp4/output.m3u8")!
        //let url: URL = URL(string: "http://infinite-set.heteml.jp/hls/h265_256.mp4")!
        //let url: URL = URL(string: "http://infinite-set.heteml.jp/hls/h265_256_fmp4/stream.m3u8")!
        
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
            self.player.event.outProgress.bind() { [weak self] (progress: TimeInterval) in
                DispatchQueue.main.async { [weak self] in
                    self?.seekBar.value = Float(progress)
                }
            }

            //self.imageProcess = imageProcess

            try self.debugger.setup.set(component: self.player)
            try self.debugger.setup.set(component: self.drawView)

            self.debugger.trigger.start()
            self.setDebuggerView()
        } catch {
            
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.player.trigger.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.player.trigger.pause()
    }

    
    @IBAction func seek(_ sender: UISlider) {
        self.player.trigger.seek(progress: sender.value)
    }
    @IBAction func seekOut(_ sender: UISlider) {
        self.player.trigger.play()
    }
}

extension PlayerExample001VC {
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
