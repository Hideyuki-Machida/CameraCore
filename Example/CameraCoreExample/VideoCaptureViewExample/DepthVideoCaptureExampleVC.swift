//
//  DepthVideoCaptureExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/04/07.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import CameraCore
import iOS_DummyAVAssets
import MetalCanvas
import UIKit

class DepthVideoCaptureExampleVC: UIViewController {
    var videoCaptureProperty = CCCapture.VideoCapture.Property(
        devicePosition: AVCaptureDevice.Position.back,
        deviceType: .builtInDualCamera,
        isAudioDataOutput: true,
        isDepthDataOutput: true,
        required: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps60),
        ],
        option: [
            //.colorSpace(AVCaptureColorSpace.P3_D65),
        ]
    )

    var camera: CCCapture.Camera?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    private var debuggerObservation: NSKeyValueObservation?
    
    @IBOutlet weak var drawView: CCView!

    deinit {
        self.camera?.triger.dispose()
        self.drawView.triger.dispose()
        self.debugger.triger.stop()
        self.debugger.triger.dispose()
        CameraCore.flush()
        MCDebug.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)

            try camera --> self.drawView

            camera.triger.start()
            self.camera = camera

            try self.debugger.setup.set(component: camera)
            try self.debugger.setup.set(component: self.drawView)

        } catch {
            
        }

        self.setDebuggerView()
        self.debugger.triger.start()
    }
}

extension DepthVideoCaptureExampleVC {
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
