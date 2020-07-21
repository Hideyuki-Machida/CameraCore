//
//  QRCodeCaptureExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/05/03.
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
class QRCodeCaptureExampleVC: UIViewController {

    var videoCaptureProperty: CCCapture.VideoCapture.Property = CCCapture.VideoCapture.Property(
        devicePosition: AVCaptureDevice.Position.back,
        deviceType: .builtInDualCamera,
        isAudioDataOutput: false,
        metadata: [.qr],
        required: [
            .captureSize(Settings.PresetSize.p1280x720)
        ],
        option: []
    )

    private var camera: CCCapture.Camera?
    private var imageProcess: CCImageProcess.ImageProcess?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    private var debuggerObservation: NSKeyValueObservation?

    @IBOutlet weak var drawView: CCView!

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
            imageProcess.renderLayers.value = [try QRCodeLayer()]

            try camera --> imageProcess --> self.drawView

            camera.triger.start()
            self.camera = camera
            self.imageProcess = imageProcess

            try self.debugger.setup.set(component: camera)
            try self.debugger.setup.set(component: imageProcess)
            try self.debugger.setup.set(component: self.drawView)

        } catch {
            
        }

        self.setDebuggerView()
        self.debugger.triger.start()
    }
}


//MARK: - DebuggerView

@available(iOS 11.1, *)
extension QRCodeCaptureExampleVC {
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

final public class QRCodeLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.custom
    public let id: CCImageProcess.RenderLayerId = CCImageProcess.RenderLayerId()
    public var customIndex: Int = 0

    public init() throws {
    }

    deinit {
        ProcessLogger.deinitLog(self)
    }

    /// キャッシュを消去
    public func dispose() {
    }

    public func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {

        guard
            var destinationPixelBuffer: CVPixelBuffer = destination.pixelBuffer
        else { throw CCImageProcess.ErrorType.process }

        var objects: [MCPrimitiveTypeProtocol] = []

        for metadataObject in renderLayerCompositionInfo.metadataObjects {
            guard let metadataObject: AVMetadataMachineReadableCodeObject = metadataObject as? AVMetadataMachineReadableCodeObject else { continue }

            let color: MCColor = MCColor(hex: "#FF0000")
            let pointSize: Float = 10.0
            
            let p: CGPoint = metadataObject.bounds.origin
            let size: CGSize = metadataObject.bounds.size
            let tl: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x), Float(p.y), 0.0), color: color, size: pointSize)
            objects.append(tl)
            let tr: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x + size.width), Float(p.y), 0.0), color: color, size: pointSize)
            objects.append(tr)
            let bl: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x), Float(p.y + size.height), 0.0), color: color, size: pointSize)
            objects.append(bl)
            let br: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x + size.width), Float(p.y + size.height), 0.0), color: color, size: pointSize)
            objects.append(br)
        }

        let canvas: MCCanvas = try MCCanvas.init(pixelBuffer: &destinationPixelBuffer, orthoType: MCCanvas.OrthoType.topLeft, renderSize: renderLayerCompositionInfo.renderSize.toCGSize())
        try canvas.draw(commandBuffer: commandBuffer, objects: objects)
    }
}
