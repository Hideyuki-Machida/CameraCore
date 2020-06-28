//
//  CoreMLDeeplabV3Layer.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/10/06.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//
/*
import UIKit
import CoreMLHelpers
import MetalCanvas
import CameraCore
import Vision

@available(iOS 12.0, *)
final public class CoreMLDeeplabV3Layer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.custom
    public let id: RenderLayerId
    public let customIndex: Int = 0
    public var request: VNCoreMLRequest?
    public var items: [ VNRecognizedObjectObservation ] = []
    public var renderLayerCompositionInfo: RenderLayerCompositionInfo?
    public var depthImage: CIImage?
    
    fileprivate var isDetecting: Bool = false
    
    public init() throws {
        self.id = RenderLayerId()
        let model = try VNCoreMLModel(for: DeepLabV3().model)
        self.request = VNCoreMLRequest(model: model, completionHandler: { [weak self] (request, error) in
            self?.processClassifications(for: request, error: error)
        })
        self.request?.preferBackgroundProcessing = true
        self.request?.imageCropAndScaleOption = .centerCrop
    }
    
    /// キャッシュを消去
    public func dispose() {
        self.request = nil
    }
}

@available(iOS 12.0, *)
extension CoreMLDeeplabV3Layer: CVPixelBufferRenderLayerProtocol {
    public func processing(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {

        self.drawDepthImage(pixelBuffer: pixelBuffer)

        guard !self.isDetecting else { return }
        self.isDetecting = true
        let pixelBuffer: CVPixelBuffer = pixelBuffer
        self.renderLayerCompositionInfo = renderLayerCompositionInfo
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard
                let self = self,
                let request = self.request
            else { return }
            
            let handler = VNImageRequestHandler.init(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
     
    }
}

@available(iOS 12.0, *)
extension CoreMLDeeplabV3Layer {
    func processClassifications(for request: VNRequest, error: Error?) {
        self.isDetecting = false
        guard let result: VNCoreMLFeatureValueObservation = request.results?.first as? VNCoreMLFeatureValueObservation else { return }
        guard result.featureValue.type == .multiArray else { return }
        guard let multiArray: MLMultiArray = result.featureValue.multiArrayValue else { return }
        let cgImage: CGImage = multiArray.cgImage(min: 0.83, max: 2.5, channel: 4, axes: nil)!
        let depthImage: CIImage = CIImage.init(cgImage: cgImage).transformed(by: CGAffineTransform.init(scaleX: 1.0, y: 1.0))
        self.depthImage = depthImage
    }
}

@available(iOS 12.0, *)
extension CoreMLDeeplabV3Layer {
    func drawDepthImage(pixelBuffer: CVPixelBuffer) {
        guard let depthImage: CIImage = self.depthImage else { return }
        MCCore.ciContext.render(depthImage, to: pixelBuffer, bounds: depthImage.extent, colorSpace: depthImage.colorSpace)
    }
}
*/
