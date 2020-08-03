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
import ProcessLogger_Swift

@available(iOS 13.0, *)
class ARVideoCaptureExampleVC: UIViewController {
    private var camera: CCARCapture.cARCamera = CCARCapture.cARCamera(mode: .faceTracking)
    private var imageProcess: CCImageProcess.ImageProcess?
    var inference: CCVision.Inference?
    var videoRecorder: CCRecorder.VideoRecorder?
    private var debugger: CCDebug.ComponentDebugger = CCDebug.ComponentDebugger()
    private var depthMapLayer: DepthMapLayer?

    @IBOutlet weak var drawView: CCView!
    @IBOutlet weak var sorcePrview: UIImageView!
    @IBOutlet weak var depthPrview: UIImageView!


    deinit {
        self.camera.triger.dispose()
        self.drawView.triger.dispose()
        self.imageProcess?.triger.dispose()
        self.debugger.triger.stop()
        self.debugger.triger.dispose()
        CameraCore.flush()
        ProcessLogger.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let inference: CCVision.Inference = CCVision.Inference()
            let imageProcess: CCImageProcess.ImageProcess = try CCImageProcess.ImageProcess()
            let depthMapLayer: DepthMapLayer = try DepthMapLayer(sorcePrview: self.sorcePrview, depthPrview: self.depthPrview)
            imageProcess.renderLayers.value = [ depthMapLayer ]

            let videoRecorder: CCRecorder.VideoRecorder = try CCRecorder.VideoRecorder()

            if #available(iOS 11.3, *) {
                print(ARWorldTrackingConfiguration.supportedVideoFormats)
            } else {
                // Fallback on earlier versions
            }

            
            try self.camera --> imageProcess --> self.drawView

            self.videoRecorder = videoRecorder
            self.imageProcess = imageProcess
            self.depthMapLayer = depthMapLayer

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

@available(iOS 13.0, *)
extension ARVideoCaptureExampleVC {
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

import ARKit

@available(iOS 13.0, *)
extension ARVideoCaptureExampleVC {
    final public class DepthMapLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.custom
        public let id: CCImageProcess.RenderLayerId = CCImageProcess.RenderLayerId()
        public var customIndex: Int = 0
        public var devicePosition: AVCaptureDevice.Position = .back

        private let sorcePrview: UIImageView
        private let depthPrview: UIImageView
        private var matteGenerator: ARMatteGenerator!
        private var canvas: MCCanvas?
        
        private let yCbCrToRGBFilter: MCFilter.ColorSpace.YCbCrToRGB
        private let renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()

        public init(sorcePrview: UIImageView, depthPrview: UIImageView) throws {
            self.sorcePrview = sorcePrview
            self.depthPrview = depthPrview
            self.yCbCrToRGBFilter = try MCFilter.ColorSpace.YCbCrToRGB()
            self.matteGenerator = ARMatteGenerator.init(device: MCCore.device, matteResolution: ARMatteGenerator.Resolution.full)
        }
        
        deinit {
            ProcessLogger.deinitLog(self)
        }

        /// キャッシュを消去
        public func dispose() {
        }

        public func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {

            guard let pixelBuffer: CVPixelBuffer = source.pixelBuffer else { return }

            try self.yCbCrToRGB(commandBuffer: commandBuffer, pixelBuffer: pixelBuffer, destination: &destination, renderLayerCompositionInfo: &renderLayerCompositionInfo)

            try self.yCbCrToRGB(commandBuffer: commandBuffer, pixelBuffer: pixelBuffer, destination: &destination, renderLayerCompositionInfo: &renderLayerCompositionInfo)
            
            let destination = destination
            guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else { return }
            let w: CGFloat = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
            let h: CGFloat = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
            
            //////////////////////////////////////////////////////////////////////////////////////////////
            // yCbCr to RGB
            var textureY: MCTexture = try MCTexture(pixelBuffer: source.pixelBuffer!, mtlPixelFormat: .r8Unorm, planeIndex: 0)
            var textureCbCr: MCTexture = try MCTexture(pixelBuffer: source.pixelBuffer!, mtlPixelFormat: .rg8Unorm, planeIndex: 1)

            self.renderPassDescriptor.colorAttachments[0].texture = destination.texture
            //try self.yCbCrToRGBFilter.process(commandBuffer: commandBuffer, capturedImageTextureY: &textureY, capturedImageTextureCbCr: &textureCbCr, renderPassDescriptor: self.renderPassDescriptor, renderSize: CGSize(w, h))
            //////////////////////////////////////////////////////////////////////////////////////////////

            //////////////////////////////////////////////////////////////////////////////////////////////
            var mat: MCGeom.Matrix4x4 = MCGeom.Matrix4x4()
            //mat.rotateX(radians: 1.0 * Float.pi)
            self.canvas = try self.updateCanvas(size: MCSize.init(w: h, h: w))

            try self.canvas?.draw(commandBuffer: commandBuffer, objects: [
                try MCPrimitive.Image(
                    texture: source,
                    position: SIMD3<Float>(x: 0, y: 0, z: 0),
                    transform: mat,
                    anchorPoint: .center
                ),
            ])

            /*
            guard
                source.size == destination.size,
                let blitEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
            else { throw RenderLayerErrorType.renderingError }
            blitEncoder.copy(from: source.texture,
                             sourceSlice: 0,
                             sourceLevel: 0,
                             sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                             sourceSize: MTLSizeMake(source.texture.width, source.texture.height, source.texture.depth),
                             to: destination.texture,
                             destinationSlice: 0,
                             destinationLevel: 0,
                             destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blitEncoder.endEncoding()

            destination = self.canvas!.mcTexture
            //////////////////////////////////////////////////////////////////////////////////////////////
*/

            guard
                let arFrame: ARFrame = renderLayerCompositionInfo.userInfo[ RenderLayerCompositionInfo.Key.arFrame.rawValue ] as? ARFrame
            else { throw CCImageProcess.ErrorType.process }

            let alphaTexture: MTLTexture = self.matteGenerator.generateMatte(from: arFrame, commandBuffer: commandBuffer)
            //CVPixelBuffer.create(image: <#T##CGImage#>, pixelFormat: <#T##OSType#>)
            print(CVPixelBufferGetPlaneCount(pixelBuffer))
            //let dilatedDepthTexture = self.matteGenerator.generateDilatedDepth(from: arFrame, commandBuffer: commandBuffer)
            commandBuffer.addCompletedHandler { (commandBuffer: MTLCommandBuffer) in
                //print(alphaTexture)
                DispatchQueue.main.async { [weak self] in
                    let inImage: CIImage = CIImage(mtlTexture: source.texture, options: nil)!
                    let maskImage: CIImage = CIImage(mtlTexture: alphaTexture, options: nil)!
                    let bgImage: CIImage = CIImage(mtlTexture: alphaTexture, options: nil)!
                    // ブレンド
                    let params = ["inputMaskImage": maskImage, "inputBackgroundImage": bgImage]
                    let outImage = inImage.applyingFilter("CIBlendWithMask", parameters: params)

                    self?.sorcePrview.image = UIImage.init(ciImage: outImage)
                    self?.depthPrview.image = UIImage.init(ciImage: CIImage(mtlTexture: alphaTexture, options: nil)!)
                }
            }

        }
        
        func yCbCrToRGB(commandBuffer: MTLCommandBuffer, pixelBuffer: CVPixelBuffer, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
            let destination = destination
            guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else { return }
            let w: CGFloat = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
            let h: CGFloat = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
            
            //////////////////////////////////////////////////////////////////////////////////////////////
            // yCbCr to RGB
            var textureY: MCTexture = try MCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: .r8Unorm, planeIndex: 0)
            var textureCbCr: MCTexture = try MCTexture(pixelBuffer: pixelBuffer, mtlPixelFormat: .rg8Unorm, planeIndex: 1)

            self.renderPassDescriptor.colorAttachments[0].texture = destination.texture
            //try self.yCbCrToRGBFilter.process(commandBuffer: commandBuffer, capturedImageTextureY: &textureY, capturedImageTextureCbCr: &textureCbCr, renderPassDescriptor: self.renderPassDescriptor, renderSize: CGSize(w, h))
            //////////////////////////////////////////////////////////////////////////////////////////////
        }

        func updateCanvas(size: MCSize) throws -> MCCanvas {
            guard
                let emptyPixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: CGSize.init(CGFloat(size.w), CGFloat(size.h)))
            else { throw CCImageProcess.ErrorType.process }
            var destinationTexture: CCTexture = try CCTexture(pixelBuffer: emptyPixelBuffer, planeIndex: 0)
            let canvas = try MCCanvas(destination: &destinationTexture, orthoType: .center)
            return canvas
        }

    }
}
