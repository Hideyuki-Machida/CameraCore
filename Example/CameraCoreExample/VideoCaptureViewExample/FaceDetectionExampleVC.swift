//
//  FaceDetectionExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/05/04.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CameraCore
import MetalCanvas

@available(iOS 12, *)
class FaceDetectionExampleVC: UIViewController {
    var videoCaptureProperty = CCCapture.VideoCapture.Property(
        //devicePosition: AVCaptureDevice.Position.front,
        devicePosition: AVCaptureDevice.Position.back,
        //deviceType: .builtInTrueDepthCamera,
        deviceType: .builtInDualCamera,
        metadata: [.face],
        required: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps60),
        ],
        option: [
            .colorSpace(AVCaptureColorSpace.P3_D65)
        ]
    )

    private var camera: CCCapture.Camera?
    private var inference: CCVision.Inference?
    private var imageProcess: CCImageProcess.ImageProcess?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    private var debuggerObservation: NSKeyValueObservation?
    
    @IBOutlet weak var drawView: CCView!

    deinit {
        self.camera?.triger.dispose()
        self.inference?.triger.dispose()
        self.imageProcess?.triger.dispose()
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
            let inference: CCVision.Inference = CCVision.Inference()
            let imageProcess: CCImageProcess.ImageProcess = CCImageProcess.ImageProcess(isDisplayLink: false)
            inference.setup.process = [ try FaceDetectionExampleVC.FaceDetectionProcess() ]
            imageProcess.renderLayers = [ try FaceDetectionExampleVC.FaceDetectionMapLayer() ]

            try camera --> imageProcess --> self.drawView
            try camera --> inference --> imageProcess

            camera.triger.start()

            self.camera = camera
            self.inference = inference
            self.imageProcess = imageProcess

            try self.debugger.setup.set(component: camera)
            try self.debugger.setup.set(component: inference)
            try self.debugger.setup.set(component: imageProcess)
            try self.debugger.setup.set(component: self.drawView)

        } catch {
            
        }

        self.setDebuggerView()
        self.debugger.triger.start()
    }
}

@available(iOS 12, *)
extension FaceDetectionExampleVC {
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


import Vision

@available(iOS 12, *)
extension FaceDetectionExampleVC {
    struct FaceDetectionResult {
        var boundingBox: CGRect
        var landmarks: VNFaceLandmarks2D
    }
}

@available(iOS 12, *)
extension FaceDetectionExampleVC {
    final public class FaceDetectionProcess: CCVisionInferenceProtocol {
        public var id: CCImageProcess.RenderLayerId = CCImageProcess.RenderLayerId.init()

        public var result: [FaceDetectionResult] = []
        public var isDetection: Bool = false
        
        public init() throws {
        }

        deinit {
            MCDebug.deinitLog(self)
        }

        public func dispose() {
        }

        public func process(pixelBuffer: CVPixelBuffer, timeStamp: CMTime, metadataObjects: [AVMetadataObject], userInfo: inout [String : Any]) throws {

            guard self.isDetection == false else { return }

            if self.result.count >= 1 {
                userInfo[ "FaceDetectionResult" ] = self.result
            }

            let w: Int = CVPixelBufferGetWidth(pixelBuffer)
            let h: Int = CVPixelBufferGetHeight(pixelBuffer)

            var faceObservations: [VNFaceObservation] = []
            for metadataObject in metadataObjects {
                guard let metadataObject: AVMetadataFaceObject = metadataObject as? AVMetadataFaceObject else { continue }
                self.isDetection = true

                let normalRect: CGRect = VNNormalizedRectForImageRect(metadataObject.bounds, w, h)
                let rollAngle: NSNumber = metadataObject.rollAngle as NSNumber
                let yawAngle: NSNumber = metadataObject.yawAngle as NSNumber
                let faceObservation: VNFaceObservation = VNFaceObservation(requestRevision: 1, boundingBox: normalRect, roll: rollAngle, yaw: yawAngle)
                faceObservations.append(faceObservation)
            }

            guard faceObservations.count >= 1 else {
                self.isDetection = false
                self.result.removeAll()
                return
            }

            var result: [FaceDetectionResult] = []
            let faceLandmarksRequest: VNDetectFaceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { [weak self] (request, error) in
                guard let self = self else { return }
                self.isDetection = false
                self.result.removeAll()
                if error != nil {
                    print("FaceDetection error: \(String(describing: error)).")
                }
                
                guard
                    let faceDetectionRequest: VNDetectFaceLandmarksRequest = request as? VNDetectFaceLandmarksRequest,
                    let results: [VNFaceObservation] = faceDetectionRequest.results as? [VNFaceObservation]
                else {
                    return
                }
                
                for faceObservation: VNFaceObservation in results {
                    guard
                        let landmarks: VNFaceLandmarks2D = faceObservation.landmarks,
                        landmarks.confidence >= 0.3
                    else {
                        continue
                    }

                    let faceDetectionResult: FaceDetectionResult = FaceDetectionResult.init(boundingBox: faceObservation.boundingBox, landmarks: landmarks)
                    result.append(faceDetectionResult)
                }
                self.result = result
                self.isDetection = false
            })

            faceLandmarksRequest.inputFaceObservations = faceObservations
            let imageRequestHandler: VNImageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try imageRequestHandler.perform([faceLandmarksRequest])

        }
    }
}

@available(iOS 12, *)
extension FaceDetectionExampleVC {
    final public class FaceDetectionMapLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.custom
        public let id: CCImageProcess.RenderLayerId = CCImageProcess.RenderLayerId()
        public var customIndex: Int = 0

        let boundColor: MCColor = MCColor.init(hex: "#FF0000")
        let landmarksColor: MCColor = MCColor.init(hex: "#FFFF00")

        public init() throws {
        }

        deinit {
            MCDebug.deinitLog(self)
        }

        /// キャッシュを消去
        public func dispose() {
        }
        
        public func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
            
            guard
                var destinationPixelBuffer: CVPixelBuffer = destination.pixelBuffer
            else { throw CCImageProcess.ErrorType.process }

            let w: Int = CVPixelBufferGetWidth(destinationPixelBuffer)
            let h: Int = CVPixelBufferGetHeight(destinationPixelBuffer)

            try self.mapFaceBound(commandBuffer: commandBuffer, destinationPixelBuffer: &destinationPixelBuffer, w: w, h: h, renderLayerCompositionInfo: &renderLayerCompositionInfo)
            try self.mapFaceLandmarks(commandBuffer: commandBuffer, destinationPixelBuffer: &destinationPixelBuffer, w: w, h: h, renderLayerCompositionInfo: &renderLayerCompositionInfo)

        }

        func mapFaceBound(commandBuffer: MTLCommandBuffer, destinationPixelBuffer: inout CVPixelBuffer, w: Int, h: Int, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
            var objects: [MCPrimitiveTypeProtocol] = []
            guard let metadataObjects: [AVMetadataFaceObject] = renderLayerCompositionInfo.metadataObjects as? [AVMetadataFaceObject] else { return }
            for face in metadataObjects {

                let p: CGPoint = face.bounds.origin
                let size: CGSize = face.bounds.size

                let rectPoint: [MCPrimitive.Point] = [
                    try MCPrimitive.Point(position: SIMD3<Float>(Float(p.x), Float(p.y), 0.0), color: self.boundColor, size: 10.0),
                    try MCPrimitive.Point(position: SIMD3<Float>(Float(p.x + size.width), Float(p.y), 0.0), color: self.boundColor, size: 10.0),
                    try MCPrimitive.Point(position: SIMD3<Float>(Float(p.x), Float(p.y + size.height), 0.0), color: self.boundColor, size: 10.0),
                    try MCPrimitive.Point(position: SIMD3<Float>(Float(p.x + size.width), Float(p.y + size.height), 0.0), color: self.boundColor, size: 10.0)
                ]
                objects.append(contentsOf: rectPoint)
            }
            let canvas: MCCanvas = try MCCanvas.init(pixelBuffer: &destinationPixelBuffer, orthoType: MCCanvas.OrthoType.topLeft, renderSize: renderLayerCompositionInfo.renderSize.toCGSize())
            try canvas.draw(commandBuffer: commandBuffer, objects: objects)
        }

        func mapFaceLandmarks(commandBuffer: MTLCommandBuffer, destinationPixelBuffer: inout CVPixelBuffer, w: Int, h: Int, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
            var objects: [MCPrimitiveTypeProtocol] = []
            if let faceDetectionResult: [FaceDetectionResult] = renderLayerCompositionInfo.inferenceUserInfo[ "FaceDetectionResult" ] as? [FaceDetectionResult] {
                for face: FaceDetectionResult in faceDetectionResult {
                    let boundingBox = VNImageRectForNormalizedRect(face.boundingBox, w, h)
                    let p: CGPoint = boundingBox.origin
                    let size: CGSize = boundingBox.size

                    let rectPoint: [MCPrimitive.Point] = [
                        try MCPrimitive.Point(position: SIMD3<Float>(Float(p.x), Float(p.y), 0.0), color: self.landmarksColor, size: 10.0),
                        try MCPrimitive.Point(position: SIMD3<Float>(Float(p.x + size.width), Float(p.y), 0.0), color: self.landmarksColor, size: 10.0),
                        try MCPrimitive.Point(position: SIMD3<Float>(Float(p.x), Float(p.y + size.height), 0.0), color: self.landmarksColor, size: 10.0),
                        try MCPrimitive.Point(position: SIMD3<Float>(Float(p.x + size.width), Float(p.y + size.height), 0.0), color: self.landmarksColor, size: 10.0)
                    ]
                    objects.append(contentsOf: rectPoint)

                    if let points: [CGPoint] = face.landmarks.allPoints?.normalizedPoints {

                        for po in points {
                            let point: CGPoint = VNImagePointForFaceLandmarkPoint(SIMD2.init(w: po.x, h: po.y), face.boundingBox, w, h)
                            let x: Float = Float(point.x)
                            let y: Float = Float(point.y)

                            let poo: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(x, y, 0.0), color: self.landmarksColor, size: 5.0)
                            objects.append(poo)
                        }
                    }

                    let canvas: MCCanvas = try MCCanvas.init(pixelBuffer: &destinationPixelBuffer, orthoType: MCCanvas.OrthoType.bottomLeft, renderSize: renderLayerCompositionInfo.renderSize.toCGSize())
                    try canvas.draw(commandBuffer: commandBuffer, objects: objects)

                }
            }

        }
    }

}
