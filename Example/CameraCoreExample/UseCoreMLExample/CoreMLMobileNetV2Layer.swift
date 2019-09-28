//
//  CoreMLMobileNetV2Layer.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/09/23.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import CameraCore
import Vision

final public class CoreMLMobileNetV2Layer: RenderLayerProtocol {
	public let type: RenderLayerType = RenderLayerType.custom
	public let id: RenderLayerId
	public let customIndex: Int = 0
	public var request: VNCoreMLRequest?
	public var onProcessClassifications: ((_ descriptions: [String])->Void)?
	
	public init() throws {
		self.id = RenderLayerId()
		let model = try VNCoreMLModel(for: MobileNetV2().model)
		self.request = VNCoreMLRequest(model: model, completionHandler: { [weak self](request, error) in
			self?.processClassifications(for: request, error: error)
		})
		self.request?.imageCropAndScaleOption = .centerCrop
	}
	
	/// キャッシュを消去
	public func dispose() {
		self.request = nil
	}
}

extension CoreMLMobileNetV2Layer: CVPixelBufferRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		let pixelBuffer = pixelBuffer
        DispatchQueue.global(qos: .userInitiated).async {
			let handler = VNImageRequestHandler.init(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([self.request!])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
		
	}
}

extension CoreMLMobileNetV2Layer {
    func processClassifications(for request: VNRequest, error: Error?) {
		guard let results = request.results else {
			self.onProcessClassifications?(["Unable to classify image."])
			return
		}
		let classifications = results as! [VNClassificationObservation]
		if classifications.isEmpty {
			self.onProcessClassifications?(["Nothing recognized."])
		} else {
			let topClassifications: ArraySlice<VNClassificationObservation> = classifications.prefix(2)
			let descriptions: [String] = topClassifications.map { (classification: VNClassificationObservation) in
				return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
			}
			self.onProcessClassifications?(descriptions)
		}
	}
}
