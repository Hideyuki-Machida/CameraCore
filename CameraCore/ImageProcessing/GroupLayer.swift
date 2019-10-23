//
//  GroupLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/11/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class GroupLayer: RenderLayerProtocol {
	public var id: RenderLayerId
	
	public var type: RenderLayerType = RenderLayerType.group
	
	public var customIndex: Int = 0

	public var layers: [RenderLayerProtocol]
	public var alpha: Float
	public var blendMode: Blendmode

	public init(layers: [RenderLayerProtocol], alpha: Float, blendMode: Blendmode) {
		self.id = RenderLayerId()
		self.layers = layers
		self.alpha = alpha
		self.blendMode = blendMode
	}

	//public func setup(assetData: CompositionVideoAsset) { }
	
	public func dispose() {

	}
}

extension GroupLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard let image: CIImage = CIImage.init(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.setupError }
		let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		let outImage: CIImage = try self.processing(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		MCCore.ciContext.render(outImage, to: destination, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
	}

	fileprivate func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
		//public func processing(image: CIImage, compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Float, renderSize: CGSize) -> CIImage? {
		var effectImage: CIImage = image
		
		if self.alpha < 1.0 {
			// アルファ
			let filter: CIFilter? = CIFilter(name: "CIColorClamp")
			filter?.setValue(effectImage, forKey: kCIInputImageKey)
			filter?.setValue(CIVector(x: 1, y: 1, z: 1, w: CGFloat(self.alpha)), forKey: "inputMaxComponents")
			filter?.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputMinComponents")
			effectImage = filter?.outputImage ?? effectImage
		}
		
		let result: CIFilter? = CIFilter(name: self.blendMode.CIFilterName())
		result?.setValue(image, forKey: kCIInputBackgroundImageKey)
		result?.setValue(effectImage, forKey: kCIInputImageKey)
		effectImage = result?.outputImage ?? effectImage
		
		return effectImage
	}

}
