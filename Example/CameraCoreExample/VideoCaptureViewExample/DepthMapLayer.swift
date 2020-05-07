//
//  DepthMapLayer.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/09/22.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas
import CameraCore
import Vision

final public class DepthMapLayer: RenderLayerProtocol {
	public let type: RenderLayerType = RenderLayerType.custom
	public let id: CCImageProcess.RenderLayerId = CCImageProcess.RenderLayerId()
	public var customIndex: Int = 0
	
	public init() throws {
	}
	
    deinit {
        MCDebug.deinitLog(self)
    }

	/// キャッシュを消去
	public func dispose() {
	}
}

extension DepthMapLayer {
    public func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard
            let depthData: AVDepthData = renderLayerCompositionInfo.depthData,
            var sourcePixelBuffer: CVPixelBuffer = source.pixelBuffer,
            var destinationPixelBuffer: CVPixelBuffer = destination.pixelBuffer
        else { throw CCImageProcess.ErrorType.process }

        var objects: [MCPrimitiveTypeProtocol] = []
        for metadataObject in renderLayerCompositionInfo.metadataObjects {
            guard let metadataObject: AVMetadataFaceObject = metadataObject as? AVMetadataFaceObject else { continue }
            let p: CGPoint = metadataObject.bounds.origin
            let size: CGSize = metadataObject.bounds.size
            let tl: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x), Float(p.y), 0.0), color: MCColor.init(hex: "#FF0000"), size: 10.0)
            objects.append(tl)
            let tr: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x + size.width), Float(p.y), 0.0), color: MCColor.init(hex: "#FF0000"), size: 10.0)
            objects.append(tr)
            let bl: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x), Float(p.y + size.height), 0.0), color: MCColor.init(hex: "#FF0000"), size: 10.0)
            objects.append(bl)
            let br: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x + size.width), Float(p.y + size.height), 0.0), color: MCColor.init(hex: "#FF0000"), size: 10.0)
            objects.append(br)

            let normalRect: CGRect = VNNormalizedRectForImageRect(metadataObject.bounds, 720, 1280)
            
            //let observation: VNDetectedObjectObservation = VNDetectedObjectObservation.init(boundingBox: metadataObject.bounds)
            
            

            let faceLandmarksRequest: VNDetectFaceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { [weak self] (request, error) in
                guard let self = self else { return }
                if error != nil {
                    print("FaceDetection error: \(String(describing: error)).")
                }
                
                
                guard let faceDetectionRequest = request as? VNDetectFaceLandmarksRequest,
                    let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                        return
                }
                
                print(results)
                
                for faceObservation: VNFaceObservation in results {
                    //self.observation = faceObservation
                    guard let landmarks: VNFaceLandmarks2D = faceObservation.landmarks else { continue }
                    print(landmarks)
                }
                
            })
            print(metadataObject.bounds)
            let faceObservation = VNFaceObservation(boundingBox: normalRect)
            faceLandmarksRequest.inputFaceObservations = [faceObservation]

            let imageRequestHandler: VNImageRequestHandler = VNImageRequestHandler(cvPixelBuffer: sourcePixelBuffer, options: [:])
            try imageRequestHandler.perform([faceLandmarksRequest])

            
            /*
            print("bouds1: ", metadataObject.bounds)
            //print("bouds1-1: ", metadataObject.bounds.standardized)
            print("bouds1-1: ", VNNormalizedRectForImageRect(metadataObject.bounds, 720, 1280))
            
            let faceDetectionRequest: VNDetectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: { [weak self] (request, error) in
                guard let self = self else { return }
                if error != nil {
                    print("FaceDetection error: \(String(describing: error)).")
                }
                
                guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                    let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                        return
                }
                
                print("results.count")
                print(results.count)
                if let o = results.first {
                    o.boundingBox
            print("bouds2: ", o.boundingBox)
                }
                //var isRequest: Bool = false
            })
            
            let imageRequestHandler: VNImageRequestHandler = VNImageRequestHandler(cvPixelBuffer: sourcePixelBuffer, options: [:])
            try imageRequestHandler.perform([faceDetectionRequest])
*/
        }

        let depthTecture: CCTexture = try CCTexture.init(pixelBuffer: depthData.depthDataMap, planeIndex: 0)
        let depthImg: MCPrimitive.Image = try MCPrimitive.Image.init(texture: depthTecture, position: SIMD3<Float>(0, 0, 0))
        let canvas: MCCanvas = try MCCanvas.init(pixelBuffer: &destinationPixelBuffer, orthoType: MCCanvas.OrthoType.topLeft, renderSize: renderLayerCompositionInfo.renderSize.toCGSize())
        objects.append(depthImg)
        try canvas.draw(commandBuffer: commandBuffer, objects: objects)
        
        

    }
}
