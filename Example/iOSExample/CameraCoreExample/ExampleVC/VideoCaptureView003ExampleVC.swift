//
//  VideoCaptureView003ExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/11/04.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import UIKit
import AVFoundation
import MetalCanvas
import CameraCore
import iOS_DummyAVAssets

class VideoCaptureView003ExampleVC: UIViewController {

    @IBOutlet weak var videoCaptureView: CameraCore.VideoCaptureView!
    @IBOutlet weak var recordingButton: UIButton!

    var lutLayer: LutLayer!

    var videoCaputurePropertys = CCRenderer.VideoCapture.Propertys.init(
        devicePosition: AVCaptureDevice.Position.back,
        isAudioDataOutput: true,
        required: [
            .captureSize(Settings.PresetSize.p960x540),
            .frameRate(Settings.PresetFrameRate.fps60),
            .isDepthDataOut(false)
        ],
        option: [
            .colorSpace(AVCaptureColorSpace.P3_D65)
        ]
    )


    deinit {
        self.videoCaptureView.pause()
        self.videoCaptureView.dispose()
        MCDebug.deinitLog(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            let faceDetactionLayer: FaceDetactionLayer = try FaceDetactionLayer.init(renderSize: Settings.PresetSize.p1280x720.size())
            self.videoCaptureView.renderLayers = [faceDetactionLayer]
            try self.videoCaptureView.setup(self.videoCaputurePropertys)
        } catch {
            MCDebug.errorLog("videoCaptureView: Setting Error")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCaptureView.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCaptureView.pause()
        self.videoCaptureView.dispose()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


final public class FaceDetactionLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.custom
    public let id: RenderLayerId
    public var customIndex: Int = 0
    fileprivate let faceDetector: MCVision.Detection.Face = MCVision.Detection.Face()
    fileprivate var faces: [MCVision.Detection.Face.Item] = []
    fileprivate var destinationTexture: MCTexture

    public init(renderSize: CGSize) throws {
        self.id = RenderLayerId()
        self.destinationTexture = try MCTexture.init(renderSize: renderSize)
    }
    
    /// キャッシュを消去
    public func dispose() {
    }
}

extension FaceDetactionLayer: CVPixelBufferRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        self.faces = try self.faceDetector.detection(pixelBuffer: &pixelBuffer, renderSize: renderLayerCompositionInfo.renderSize) { [weak self] ( faces: [MCVision.Detection.Face.Item] ) in
            //print(faces)
            //self?.faces = faces
        }

        var drawItems: [MCPrimitiveTypeProtocol] = []
        for face in self.faces {
            for point in face.allPoints {
                let p: MCPoint = MCPoint.init(
                    ppsition: SIMD3<Float>.init(x: Float(point.x), y: Float(point.y), z: 0),
                    color: MCColor.init(hex: "0x00FF00"), size: 5.0
                )
                drawItems.append(p)
            }
        }
        
        guard drawItems.count >= 1 else { return }
        var t: MCTexture = try MCTexture.init(pixelBuffer: &pixelBuffer, planeIndex: 0)
        // キャンバスを生成
        let canvas: MCCanvas = try MCCanvas.init(destination: &t, orthoType: .topLeft)
        try canvas.draw(commandBuffer: &commandBuffer, objects: drawItems)
    }
}
