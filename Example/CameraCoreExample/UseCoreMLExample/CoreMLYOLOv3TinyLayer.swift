//
//  CoreMLMobileNetV2Layer_.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/09/23.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import CameraCore
import Vision

@available(iOS 12.0, *)
final public class CoreMLYOLOv3TinyLayer: RenderLayerProtocol {
	public let type: RenderLayerType = RenderLayerType.custom
	public let id: RenderLayerId
	public let customIndex: Int = 0
	public var request: VNCoreMLRequest?
	public var items: [ VNRecognizedObjectObservation ] = []
    public var onUpdate: ((_ items: [ VNRecognizedObjectObservation ])->Void)?

	public init() throws {
		self.id = RenderLayerId()
		let model = try VNCoreMLModel(for: YOLOv3Tiny().model)
		self.request = VNCoreMLRequest(model: model, completionHandler: { [weak self] (request, error) in
			self?.processClassifications(for: request, error: error)
		})
		self.request?.imageCropAndScaleOption = .centerCrop
	}
	
	/// キャッシュを消去
	public func dispose() {
		self.request = nil
	}
}

@available(iOS 12.0, *)
extension CoreMLYOLOv3TinyLayer: CVPixelBufferRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		let pixelBuffer = pixelBuffer
        DispatchQueue.global(qos: .userInitiated).async {
			let handler = VNImageRequestHandler.init(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([self.request!])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
		
	}
}

@available(iOS 12.0, *)
extension CoreMLYOLOv3TinyLayer {
    func processClassifications(for request: VNRequest, error: Error?) {
		guard let results = request.results else {
			return
		}
		self.items = []
		for observation in results where observation is VNRecognizedObjectObservation {
			guard let objectObservation = observation as? VNRecognizedObjectObservation else {
				continue
			}
            self.items.append(objectObservation)
		}
        self.onUpdate?(self.items)
	}
}
