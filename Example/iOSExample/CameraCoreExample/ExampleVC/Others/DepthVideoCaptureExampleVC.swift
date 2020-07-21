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
import ProcessLogger_Swift


//MARK: - ViewController

@available(iOS 11.1, *)
class DepthVideoCaptureExampleVC: UIViewController {
    var videoCaptureProperty = CCCapture.VideoCapture.Property(
        //devicePosition: AVCaptureDevice.Position.front,
        devicePosition: AVCaptureDevice.Position.back,
        //deviceType: .builtInTrueDepthCamera,
        deviceType: .builtInDualCamera,
        isDepthDataOutput: true,
        required: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps60),
        ]
    )

    private var camera: CCCapture.Camera?
    private var imageProcess: CCImageProcess.ImageProcess?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    private var debuggerObservation: NSKeyValueObservation?
    private var depthMapLayer: DepthMapLayer?
    
    @IBOutlet weak var drawView: CCView!
    @IBOutlet weak var depthPrview: UIImageView!

    deinit {
        self.camera?.triger.dispose()
        self.imageProcess?.triger.dispose()
        self.drawView.triger.dispose()
        self.debugger.triger.stop()
        self.debugger.triger.dispose()
        CameraCore.flush()
        ProcessLogger.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)
            let imageProcess: CCImageProcess.ImageProcess = try CCImageProcess.ImageProcess()
            let depthMapLayer: DepthMapLayer = try DepthMapLayer(depthPrview: self.depthPrview)
            imageProcess.renderLayers = [ depthMapLayer ]

            try camera --> imageProcess --> self.drawView

            camera.triger.start()
            self.camera = camera
            self.imageProcess = imageProcess
            self.depthMapLayer = depthMapLayer

            try self.debugger.setup.set(component: camera)
            try self.debugger.setup.set(component: imageProcess)
            try self.debugger.setup.set(component: self.drawView)

        } catch {
        }

        self.setDebuggerView()
        self.debugger.triger.start()
    }

    @IBAction func changeDeviceAction(_ sender: Any) {
        do {
            if self.videoCaptureProperty.captureInfo.devicePosition == .front {
                self.videoCaptureProperty.devicePosition = .back
                self.depthMapLayer?.devicePosition = .back
                self.videoCaptureProperty.deviceType = .builtInDualCamera
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            } else {
                self.videoCaptureProperty.devicePosition = .front
                self.depthMapLayer?.devicePosition = .front
                self.videoCaptureProperty.deviceType = .builtInTrueDepthCamera
                try self.camera?.setup.update(property: self.videoCaptureProperty)
            }
        } catch {
            ProcessLogger.errorLog("changeDeviceAction")
        }

    }

}


//MARK: - DebuggerView

@available(iOS 11.1, *)
extension DepthVideoCaptureExampleVC {
    public func setDebuggerView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let debugView: DebugView = Bundle.main.loadNibNamed("DebugView", owner: self, options: nil)?.first as! DebugView
            self.view.addSubview(debugView)

            self.debuggerObservation?.invalidate()
            self.debuggerObservation = self.debugger.outPut.observe(\.onUpdate, options: [.new]) { (debuggerOutput: CCDebug.ComponentDebugger.Output, _) in
                DispatchQueue.main.async {
                    debugView.set(debugData: debuggerOutput.data)
                }
            }

        }
    }
}


//MARK: - RenderLayer

import Vision

@available(iOS 11.1, *)
extension DepthVideoCaptureExampleVC {
    final public class DepthMapLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.custom
        public let id: CCImageProcess.RenderLayerId = CCImageProcess.RenderLayerId()
        public var customIndex: Int = 0
        private let depthPrview: UIImageView
        public var devicePosition: AVCaptureDevice.Position = .back
        
        public init(depthPrview: UIImageView) throws {
            self.depthPrview = depthPrview
        }
        
        deinit {
            ProcessLogger.deinitLog(self)
        }

        /// キャッシュを消去
        public func dispose() {
        }

        public func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
            guard let depthData: AVDepthData = renderLayerCompositionInfo.userInfo[ RenderLayerCompositionInfo.Key.depthData.rawValue ] as? AVDepthData else { throw CCImageProcess.ErrorType.process }

            let w: CGFloat = CGFloat(CVPixelBufferGetWidth(depthData.depthDataMap))
            let h: CGFloat = CGFloat(CVPixelBufferGetHeight(depthData.depthDataMap))

            let depthImage: CIImage
            if devicePosition == .front {
                depthImage  = CIImage(cvPixelBuffer: depthData.depthDataMap, options: [:])
                .transformed(by: CGAffineTransform(rotationAngle: CGFloat.pi / 180 * 90))
                .transformed(by: CGAffineTransform.init(translationX: h, y: 0))
            } else {
                depthImage  = CIImage(cvPixelBuffer: depthData.depthDataMap, options: [:])
                .transformed(by: CGAffineTransform(rotationAngle: CGFloat.pi / 180 * -90))
                .transformed(by: CGAffineTransform.init(translationX: 0, y: w))
            }

            DispatchQueue.main.async { [weak self] in
                self?.depthPrview.image = UIImage.init(ciImage: depthImage)
            }
        }
    }
}
