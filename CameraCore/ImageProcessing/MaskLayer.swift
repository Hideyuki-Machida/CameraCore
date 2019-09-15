//
//  MaskLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class MaskLayer: RenderLayerProtocol {
	public let type: RenderLayerType = RenderLayerType.mask
	public var id: RenderLayerId
	public let mask: CIImage
	public var customIndex: Int = 0
	public var maskShader: CIColorKernel
	
	public init(mask: CIImage) {
		self.id = RenderLayerId()
		
		let maskShaderPath: URL = AssetManager.Shader.mask.url()
		let maskShaderString: String = try! String(contentsOf: maskShaderPath, encoding: .utf8)
		self.maskShader = CIColorKernel(source: maskShaderString)!
		self.mask = mask
	}

	fileprivate init(id: RenderLayerId, mask: CIImage) {
		self.id = id
		
		let maskShaderPath: URL = AssetManager.Shader.mask.url()
		let maskShaderString: String = try! String(contentsOf: maskShaderPath, encoding: .utf8)
		self.maskShader = CIColorKernel(source: maskShaderString)!
		self.mask = mask
	}
	
	public func setup(assetData: CompositionVideoAsset) { }
	
	/// キャッシュを消去
	public func dispose() {
	}
}

extension MaskLayer: CIImageRenderLayerProtocol {
	public func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
		let image: CIImage = self.maskShader.apply(extent: image.extent, arguments: [
			image,
			self.mask,
			CIVector(x: image.extent.width, y: image.extent.height),
			])!
		
		return image
	}

	/*
	public func processing(image: CIImage, compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Float, renderSize: CGSize) -> CIImage? {
		let image: CIImage = self.maskShader.apply(extent: image.extent, arguments: [
			image,
			self.mask,
			CIVector(x: image.extent.width, y: image.extent.height),
			])!
		return image
	}
	*/
}

extension MaskLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard let image: CIImage = CIImage.init(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.setupError }
		
		let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		let outImage = try self.processing(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		MCCore.ciContext.render(outImage, to: destination, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
	}
}

extension MaskLayer {
	public func toJsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	public static func decode(to: Data) throws -> RenderLayerProtocol {
		return try JSONDecoder().decode(LutLayer.self, from: to)
	}
}

extension MaskLayer {
	enum CodingKeys: String, CodingKey {
		case id
		case mask
	}
}

extension MaskLayer: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		let maskImage: UIImage = UIImage.init(ciImage: self.mask)
		try container.encode(maskImage.pngData()!, forKey: .mask)
	}
}

extension MaskLayer: Decodable {
	public convenience init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let id = try values.decode(RenderLayerId.self, forKey: .id)
		let maskData = try values.decode(Data.self, forKey: .mask)
		let mask: CIImage = CIImage.init(data: maskData)!
		
		self.init(id: id, mask: mask)
	}
}
