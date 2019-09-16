//
//  ColorOverlay.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class ColorOverlayLayer: RenderLayerProtocol {
	public let type: RenderLayerType = RenderLayerType.colorOverlay
	public let id: RenderLayerId
	public var customIndex: Int = 0
	private var color: CIVector = CIVector(x: 1.0, y: 1.0, z: 1.0)
	private var offset: Float = 0
	private var _transitionThreshold: Float = 0
	private let _fragmentShader: CIColorKernel?
	
	public init(color: UIColor, offset: Float) {
		self.id = RenderLayerId()
		let color: CIColor = CIColor(cgColor: color.cgColor)
		self.color = CIVector(x: color.red, y: color.green, z: color.blue)

		let fragmentShaderPath: URL = AssetManager.Shader.colorOverlay.url()
		let fragmentShaderString: String = try! String(contentsOf: fragmentShaderPath, encoding: .utf8)
		self._fragmentShader = CIColorKernel(source: fragmentShaderString)!
		
		self.offset = offset
	}

	fileprivate init(id: RenderLayerId, color: UIColor, offset: Float) {
		self.id = id
		let color: CIColor = CIColor(cgColor: color.cgColor)
		self.color = CIVector(x: color.red, y: color.green, z: color.blue)
		
		let fragmentShaderPath: URL = AssetManager.Shader.colorOverlay.url()
		let fragmentShaderString: String = try! String(contentsOf: fragmentShaderPath, encoding: .utf8)
		self._fragmentShader = CIColorKernel(source: fragmentShaderString)!
		
		self.offset = offset
	}
	
	//public func setup(assetData: CompositionVideoAsset) { }
	
	public func update(offset: Float) {
		self.offset = offset
	}
	
	/// キャッシュを消去
	public func dispose() {
	}
}

extension ColorOverlayLayer: CIImageRenderLayerProtocol {
	public func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
		let img: CIImage? = self._fragmentShader!.apply(extent: image.extent, arguments: [
			image,
			CIVector(x: image.extent.width, y: image.extent.height),
			self.color,
			NSNumber(value: self.offset)
			])

		if let img: CIImage = img {
			return img
		} else {
			throw CCRenderer.ErrorType.rendering
		}
	}
	/*
	public func processing(image: CIImage, compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Float, renderSize: CGSize) -> CIImage? {
		let img: CIImage? = self._fragmentShader!.apply(extent: image.extent, arguments: [
			image,
			CIVector(x: image.extent.width, y: image.extent.height),
			self.color,
			NSNumber(value: self.offset)
			])
		
		return img
	}
	*/
}

extension ColorOverlayLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard let image: CIImage = CIImage.init(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.setupError }
		let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()		
		let outImage: CIImage = try self.processing(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		MCCore.ciContext.render(outImage, to: destination, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
	}
}

extension ColorOverlayLayer {
	public func toJsonData() throws -> Data {
		return try JSONEncoder().encode(self)
	}
	public static func decode(to: Data) throws -> RenderLayerProtocol {
		return try JSONDecoder().decode(LutLayer.self, from: to)
	}
}

extension ColorOverlayLayer {
	enum CodingKeys: String, CodingKey {
		case id
	}
}

extension ColorOverlayLayer: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		//try container.encode(self.dimension, forKey: .dimension)
		//try container.encode(CodableURL.init(url: self.lutImageURL), forKey: .lutImageURL)
	}
}

extension ColorOverlayLayer: Decodable {
	public convenience init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let id: RenderLayerId = try values.decode(RenderLayerId.self, forKey: .id)
		self.init(id: id, color: UIColor.black, offset: 1.0)
	}
}
