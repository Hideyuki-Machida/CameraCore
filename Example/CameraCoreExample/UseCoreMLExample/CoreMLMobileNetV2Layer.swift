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

    fileprivate var isDetecting: Bool = false
    
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
        guard !self.isDetecting else { return }
        self.isDetecting = true
        let pixelBuffer = pixelBuffer
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard
                let self = self,
                let request = self.request
            else { return }

            let handler = VNImageRequestHandler.init(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                
            }

        }
		
	}
}

extension CoreMLMobileNetV2Layer {
    func processClassifications(for request: VNRequest, error: Error?) {
        self.isDetecting = false
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
