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
        devicePosition: AVCaptureDevice.Position.front,
        deviceType: .builtInTrueDepthCamera,
        isDepthDataOutput: true,
        required: [
            .captureSize(Settings.PresetSize.p1280x720),
            .frameRate(Settings.PresetFrameRate.fps30),
        ]
    )

    private var camera: CCCapture.Camera?
    private var imageProcess: CCImageProcess.ImageProcess?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    private var depthMapLayer: DepthMapLayer?
    
    @IBOutlet weak var drawView: CCView!
    @IBOutlet weak var depthPrview: UIImageView!

    deinit {
        self.camera?.trigger.dispose()
        self.imageProcess?.trigger.dispose()
        self.drawView.trigger.dispose()
        self.debugger.trigger.stop()
        self.debugger.trigger.dispose()
        CameraCore.flush()
        ProcessLogger.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let camera: CCCapture.Camera = try CCCapture.Camera(property: self.videoCaptureProperty)
            let imageProcess: CCImageProcess.ImageProcess = try CCImageProcess.ImageProcess()
            let depthMapLayer: DepthMapLayer = try DepthMapLayer(depthPrview: self.depthPrview)

            imageProcess.renderLayers.value = [ depthMapLayer ]

            try camera --> imageProcess --> self.drawView

            camera.trigger.start()

            self.camera = camera
            self.imageProcess = imageProcess
            self.depthMapLayer = depthMapLayer

            try self.debugger.setup.set(component: camera)
            try self.debugger.setup.set(component: imageProcess)
            try self.debugger.setup.set(component: self.drawView)

        } catch {
        }

        self.setDebuggerView()
        self.debugger.trigger.start()
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

            self.debugger.outPut.data.bind() { (data: CCDebug.ComponentDebugger.Output.Data) in
                DispatchQueue.main.async {
                    debugView.set(debugData: data)
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
        public var devicePosition: AVCaptureDevice.Position = .front
        public fileprivate(set) var binarizationFilter: DepthVideoCaptureExampleVC.BinarizationFilter!
        public fileprivate(set) var humanMaskFilter: DepthVideoCaptureExampleVC.HumanMaskFilter!
        
        public init(depthPrview: UIImageView) throws {
            self.depthPrview = depthPrview
            self.binarizationFilter = try DepthVideoCaptureExampleVC.BinarizationFilter()
            self.humanMaskFilter = try DepthVideoCaptureExampleVC.HumanMaskFilter()
        }
        
        deinit {
            ProcessLogger.deinitLog(self)
        }

        /// キャッシュを消去
        public func dispose() {
        }

        public func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
            guard let depthData: AVDepthData = renderLayerCompositionInfo.userInfo[ RenderLayerCompositionInfo.Key.depthData.rawValue ] as? AVDepthData else { throw CCImageProcess.ErrorType.process }

            var depthPixelBuffer: CVPixelBuffer = depthData.depthDataMap
            var disparityPixelBuffer: CVPixelBuffer = depthData.convertToDisparity().depthDataMap
            let disparitWidth: CGFloat = CGFloat(CVPixelBufferGetWidth(disparityPixelBuffer))
            let disparitHeight: CGFloat = CGFloat(CVPixelBufferGetHeight(disparityPixelBuffer))
            let size: CGSize = CGSize(CGFloat(disparitWidth), CGFloat(disparitHeight))

            guard
                var disparitDestinationTexturePB: CVPixelBuffer = CVPixelBuffer.create(size: size),
                let disparitDestinationTexture: MTLTexture = MCCore.texture(pixelBuffer: &disparitDestinationTexturePB, mtlPixelFormat: .bgra8Unorm),
                let depthTexture: MTLTexture = MCCore.texture(pixelBuffer: &depthPixelBuffer, mtlPixelFormat: .r32Float),
                let disparityTexture: MTLTexture = MCCore.texture(pixelBuffer: &disparityPixelBuffer, mtlPixelFormat: .r32Float)
            else { throw CCImageProcess.ErrorType.process }

            //////////////////////////////////////////////////////////////////////////////////////////////
            // DepthDataMap値化
            try self.binarizationFilter.process(commandBuffer: commandBuffer, depthTexture: depthTexture, disparityTexture: disparityTexture, destination: disparitDestinationTexture)
            //////////////////////////////////////////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////////////////////////////////////////
            // DepthDataMapをTransforms
            let zAngle = self.devicePosition == .front ? -90 * Float.pi / 180 : 90 * Float.pi / 180
            let scale: Float = renderLayerCompositionInfo.renderSize.w / Float(disparitHeight)
            var mat: MCGeom.Matrix4x4 = MCGeom.Matrix4x4()
            mat.scale(x: scale, y: scale, z: 0.0)
            mat.rotateAroundX(xAngleRad: 0, yAngleRad: 0, zAngleRad: zAngle)
            let canvas: MCCanvas = try self.updateCanvas(size: renderLayerCompositionInfo.renderSize)

            let resultTexture: CCTexture = try CCTexture.init(texture: disparitDestinationTexture)
            
            try canvas.draw(commandBuffer: commandBuffer, objects: [
                try MCPrimitive.Image(
                    texture: resultTexture,
                    position: SIMD3<Float>(x: renderLayerCompositionInfo.renderSize.w / 2.0, y: renderLayerCompositionInfo.renderSize.h / 2.0, z: 0),
                    transform: mat,
                    anchorPoint: .center
                ),
            ])
            //////////////////////////////////////////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////////////////////////////////////////
            // DepthDataMapでMask
            try self.humanMaskFilter.process(commandBuffer: commandBuffer, source: source.texture, mask: canvas.texture!, destination: destination.texture)
            //////////////////////////////////////////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////////////////////////////////////////
            // DepthDataMapを表示
            let depthImage: CIImage
            if self.devicePosition == .front {
                depthImage  = CIImage(cvPixelBuffer: depthPixelBuffer, options: [:])
                .transformed(by: CGAffineTransform(rotationAngle: CGFloat.pi / 180 * 90))
                .transformed(by: CGAffineTransform.init(translationX: disparitHeight, y: 0))
            } else {
                depthImage  = CIImage(cvPixelBuffer: depthPixelBuffer, options: [:])
                .transformed(by: CGAffineTransform(rotationAngle: CGFloat.pi / 180 * -90))
                .transformed(by: CGAffineTransform.init(translationX: 0, y: disparitWidth))
            }

            DispatchQueue.main.async { [weak self] in
                self?.depthPrview.image = UIImage.init(ciImage: depthImage)
            }
            //////////////////////////////////////////////////////////////////////////////////////////////
        }
        
        func updateCanvas(size: MCSize) throws -> MCCanvas {
            guard
                let emptyPixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: CGSize.init(CGFloat(size.w), CGFloat(size.h)))
            else { throw CCImageProcess.ErrorType.process }
            var destinationTexture: CCTexture = try CCTexture(pixelBuffer: emptyPixelBuffer, planeIndex: 0)
            let canvas = try MCCanvas(destination: &destinationTexture, orthoType: .topLeft)
            return canvas
        }

    }
}

@available(iOS 11.1, *)
extension DepthVideoCaptureExampleVC {
    final public class BinarizationFilter {

        fileprivate var intensityBuffer: MTLBuffer
        public var value: Float = 1.0 {
            willSet {
                do {
                    self.intensityBuffer = try MCCore.makeBuffer(data: [newValue])
                } catch {}
            }
        }

        public fileprivate(set) var library: MTLLibrary!
        fileprivate let pipelineState: MTLComputePipelineState
        fileprivate let threadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)

        init() throws {
            let metallibURL: URL = Bundle.main.url(forResource: "default", withExtension: "metallib")!
            self.library = try MCCore.device.makeLibrary(filepath: metallibURL.path)
            let kernel: MTLFunction = self.library.makeFunction(name: "kernel_Binarization")!
            self.pipelineState = try MCCore.device.makeComputePipelineState(function: kernel)
            self.intensityBuffer = try MCCore.makeBuffer(data: [self.value])
        }

        
        public func process(commandBuffer: MTLCommandBuffer, depthTexture: MTLTexture, disparityTexture: MTLTexture, destination: MTLTexture) throws {

            let threadgroupCount = MTLSize(
                width: Int(destination.width) / self.threadsPerThreadgroup.width,
                height: Int(destination.height) / self.threadsPerThreadgroup.height,
                depth: 1
            )

            let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
            encoder.setComputePipelineState(self.pipelineState)
            encoder.setTexture(disparityTexture, index: 0)
            encoder.setTexture(destination, index: 1)
            encoder.setBuffer(self.intensityBuffer, offset: 0, index: 0)
            encoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: self.threadsPerThreadgroup)
            encoder.endEncoding()
        }
    }
}

@available(iOS 11.1, *)
extension DepthVideoCaptureExampleVC {
    final public class HumanMaskFilter {

        fileprivate var intensityBuffer: MTLBuffer
        public var value: Float = 0 {
            willSet {
                do {
                    self.intensityBuffer = try MCCore.makeBuffer(data: [newValue])
                } catch {}
            }
        }

        public fileprivate(set) var library: MTLLibrary!
        fileprivate let pipelineState: MTLComputePipelineState
        fileprivate let threadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)

        init() throws {
            let metallibURL: URL = Bundle.main.url(forResource: "default", withExtension: "metallib")!
            self.library = try MCCore.device.makeLibrary(filepath: metallibURL.path)
            let kernel: MTLFunction = self.library.makeFunction(name: "kernel_Mask")!
            self.pipelineState = try MCCore.device.makeComputePipelineState(function: kernel)
            self.intensityBuffer = try MCCore.makeBuffer(data: [self.value])
        }

        
        public func process(commandBuffer: MTLCommandBuffer, source: MTLTexture, mask: MTLTexture, destination: MTLTexture) throws {

            let threadgroupCount = MTLSize(
                width: Int(destination.width) / self.threadsPerThreadgroup.width,
                height: Int(destination.height) / self.threadsPerThreadgroup.height,
                depth: 1
            )

            let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
            encoder.setComputePipelineState(self.pipelineState)
            encoder.setTexture(source, index: 0)
            encoder.setTexture(mask, index: 1)
            encoder.setTexture(destination, index: 2)
            encoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: self.threadsPerThreadgroup)
            encoder.endEncoding()
        }
    }
}
