//
//  ARVideoCaptureExampleVC.swift
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
import ARKit

class ARVideoCaptureExampleVC: UIViewController {
    var camera: CCARCapture.cARCamera = CCARCapture.cARCamera(mode: .faceTracking)
    private var imageProcess: CCImageProcess.ImageProcess?
    var inference: CCVision.Inference?
    var videoRecorder: CCRecorder.VideoRecorder?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    private var debuggerObservation: NSKeyValueObservation?

    @IBOutlet weak var drawView: CCView!
    
    deinit {
        self.camera.triger.dispose()
        self.drawView.triger.dispose()
        self.imageProcess?.triger.dispose()
        self.debugger.triger.stop()
        self.debugger.triger.dispose()
        CameraCore.flush()
        MCDebug.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let inference: CCVision.Inference = CCVision.Inference()
            let imageProcess: CCImageProcess.ImageProcess = CCImageProcess.ImageProcess(isDisplayLink: true)
            let videoRecorder: CCRecorder.VideoRecorder = try CCRecorder.VideoRecorder()

            if #available(iOS 11.3, *) {
                print(ARWorldTrackingConfiguration.supportedVideoFormats)
            } else {
                // Fallback on earlier versions
            }

            
            //try self.camera --> imageProcess --> self.drawView
            try self.camera --> imageProcess --> self.drawView

            self.videoRecorder = videoRecorder
            self.imageProcess = imageProcess

            self.camera.triger.start()
            try self.debugger.setup.set(component: self.camera)
            try self.debugger.setup.set(component: imageProcess)
            try self.debugger.setup.set(component: self.drawView)

        } catch {
            
        }

        self.setDebuggerView()
        self.debugger.triger.start()
    }
}

extension ARVideoCaptureExampleVC {
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
