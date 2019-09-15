//
//  ImageLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

/// ImageLayer 画像オーバーレイエフェクト
final public class ImageLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.image
    public let id: RenderLayerId
    public let customIndex: Int = 0
	public var transform: CGAffineTransform
	private let imagePath: URL
    private let blendMode: Blendmode
    private let alpha: CGFloat
    private let renderSize: CGSize
	private let contentMode: CompositionImageLayerContentMode
	private var contentModeTransform: CGAffineTransform?
	private var _image: CIImage?
	private var overTexture: MCTexture?
	
    public init(imagePath: URL, blendMode: Blendmode, alpha: CGFloat = 1.0, renderSize: CGSize, contentMode: CompositionImageLayerContentMode = .none, transform: CGAffineTransform? = nil) {
        self.id = RenderLayerId()
        self.imagePath = imagePath
        self.blendMode = blendMode
        self.alpha = alpha
        self.renderSize = renderSize
		self.contentMode = contentMode
        self.transform = transform ?? CGAffineTransform.identity
		
		/*
		if let image: CIImage = CIImage(contentsOf: self.imagePath) {
			let imageSize: CGSize = image.extent.size
			self.contentModeTransform = self.contentMode.transform(imageSize: imageSize, renderSize: renderSize)
		} else {
			self.contentModeTransform = CGAffineTransform.identity
		}
		*/
    }

	fileprivate init(id: RenderLayerId, imagePath: URL, blendMode: Blendmode, alpha: CGFloat = 1.0, renderSize: CGSize, contentMode: CompositionImageLayerContentMode = .none, transform: CGAffineTransform? = nil) {
		self.id = id
		self.imagePath = imagePath
		self.blendMode = blendMode
		self.alpha = alpha
		self.renderSize = renderSize
		self.contentMode = contentMode
		self.transform = transform ?? CGAffineTransform.identity
		
		/*
		if let image: CIImage = CIImage(contentsOf: self.imagePath) {
			let imageSize: CGSize = image.extent.size
			self.contentModeTransform = self.contentMode.transform(imageSize: imageSize, renderSize: renderSize)
		} else {
			self.contentModeTransform = CGAffineTransform.identity
		}
		*/
	}

	
    public func setup(assetData: CompositionVideoAsset) { }
    
    /// キャッシュを消去
	public func dispose() {
		self._image = nil
    }	
}

extension ImageLayer: CameraCore.CIImageRenderLayerProtocol {
	public func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
	//public func processing(image: CIImage, compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Float, renderSize: CGSize) -> CIImage? {
		
		// フィルターイメージ生成
		if self._image != nil {
			
			// フィルター合成
			let result: CIFilter = CIFilter(name: self.blendMode.CIFilterName())!
			result.setValue(image, forKey: kCIInputBackgroundImageKey)
			result.setValue(self._image!, forKey: kCIInputImageKey)
			
			return result.outputImage ?? image
		} else {
			// フィルターイメージ作成
			guard var effect: CIImage = CIImage(contentsOf: self.imagePath) else { throw RenderLayerErrorType.renderingError }
			
			// 上下反転
			effect = effect.transformed(by: CGAffineTransform(scaleX: 1, y: -1.0).translatedBy(x: 0, y: -CGFloat(effect.extent.height)))

			if self.contentModeTransform == nil {
				let imageSize: CGSize = effect.extent.size
				self.contentModeTransform = self.contentMode.transform(imageSize: imageSize, renderSize: self.renderSize)
			}
			
			let colorMatrixfilter: CIFilter = CIFilter(name:"CIColorMatrix")!
			colorMatrixfilter.setValue(effect, forKey: kCIInputImageKey)
			colorMatrixfilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: self.alpha), forKey: "inputAVector")
			
			///////////////////////////////////////////////////////////////////////////////////////////////////
			// まずcontentModeの設定を反映
			guard let alphaImage: CIImage = colorMatrixfilter.outputImage else { throw RenderLayerErrorType.renderingError }
			guard let contentModeTransformFilter: CIFilter = CIFilter(name: "CIAffineTransform") else { throw RenderLayerErrorType.renderingError }
			contentModeTransformFilter.setValue(alphaImage, forKey: kCIInputImageKey)
			contentModeTransformFilter.setValue(NSValue(cgAffineTransform: self.contentModeTransform!), forKey: "inputTransform")
			let contentModeTransformImage: CIImage = contentModeTransformFilter.outputImage!
			//contentModeTransformImage = contentModeTransformImage.cropped(to: CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: self.renderSize))
			//let contentModeCropImage: CIImage = contentModeTransformImage.cropped(to: CGRect(origin: CGPoint.zero, size: renderSize))
			///////////////////////////////////////////////////////////////////////////////////////////////////

			///////////////////////////////////////////////////////////////////////////////////////////////////
			// まずcontentModeの設定を反映
			let transform: CGAffineTransform = TransformUtils.convertTransformSKToCI(
				userTransform: self.transform,
				videoSize: image.extent.size,
				renderSize: renderSize,
				preferredTransform: CGAffineTransform.identity
			)
			
			guard let transformFilter: CIFilter = CIFilter(name: "CIAffineTransform") else { throw RenderLayerErrorType.renderingError }
			transformFilter.setValue(contentModeTransformImage, forKey: kCIInputImageKey)
			transformFilter.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
			var transformImage: CIImage = transformFilter.outputImage!
			transformImage = transformImage.cropped(to: CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: self.renderSize))
			//let cropImage: CIImage = transformImage.cropped(to: CGRect(origin: CGPoint.zero, size: renderSize))
			///////////////////////////////////////////////////////////////////////////////////////////////////
			
			self._image = transformImage
			
			// フィルター合成
			let result: CIFilter = CIFilter(name: self.blendMode.CIFilterName())!
			
			result.setValue(image, forKey: kCIInputBackgroundImageKey)
			result.setValue(transformImage, forKey: kCIInputImageKey)
			return result.outputImage ?? image
		}
	}
}

/*
extension ImageLayer: CameraCore.CVPixelBufferRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> Void {
		var inputImage: CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
		inputImage = try processing(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		MCCore.ciContext.render(inputImage, to: pixelBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
	}
}
*/

extension ImageLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard var inputImage: CIImage = CIImage(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.renderingError }
		inputImage = try self.processing(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
		MCCore.ciContext.render(inputImage, to: destination, commandBuffer: commandBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
		commandBuffer.commit()
	}

	/*
	public func processing(commandBuffer: inout MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard var inputImage: CIImage = CIImage(mtlTexture: sourceTexture, options: nil) else { throw RenderLayerErrorType.renderingError }
		inputImage = try processing(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		//guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
		MCCore.ciContext.render(inputImage, to: destinationTexture, commandBuffer: commandBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
		//commandBuffer.commit()
	}
	*/
}

/*
extension ImageLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		
		let sourceMCTexture: MCTexture = try MCTexture.init(texture: sourceTexture)
		var destinationMCTexture: MCTexture = try MCTexture.init(texture: destinationTexture)
		let canvas: MCCanvas = try MCCanvas.init(destination: &destinationMCTexture, orthoType: .topLeft)
		let renderSize: CGSize = renderLayerCompositionInfo.renderSize
		//let compositionTime: CMTime = renderLayerCompositionInfo.compositionTime

		let sourceImage: MCPrimitive.Image = try MCPrimitive.Image.init(texture: sourceMCTexture,
																		ppsition: MCGeom.Vec3D.init(x: Float(renderSize.width / 2.0), y: Float(renderSize.height / 2.0), z: 0),
																		transform: MCGeom.Matrix4x4.init(scaleX: 1.0, scaleY: 1.0, scaleZ: 1.0),
																		anchorPoint: .center
		)
		
		var overTexture: MCTexture? = self.overTexture
		if overTexture == nil {
			print(self.imagePath)
			overTexture = try MCTexture.init(URL: self.imagePath)
			self.overTexture = overTexture
		}
		
		print(overTexture)
		let overImage: MCPrimitive.Image = try MCPrimitive.Image.init(texture: overTexture!,
																	  ppsition: MCGeom.Vec3D.init(x: Float(renderSize.width / 2.0), y: Float(renderSize.height / 2.0), z: 0),
																	  transform: MCGeom.Matrix4x4.init(scaleX: Float(renderSize.width) / Float(overTexture!.width), scaleY: Float(renderSize.height) / Float(overTexture!.height), scaleZ: 1.0),
																	  anchorPoint: .center
		)

		print(MCCore.device.currentAllocatedSize)
		try canvas.draw(commandBuffer: &commandBuffer, objects: [sourceImage, overImage])

		/*
		guard let image: CIImage = CIImage.init(mtlTexture: sourceTexture, options: nil) else { throw RenderLayerErrorType.setupError }
		let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		
		var outImage = try self.processing(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		outImage = outImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: CGFloat(outImage.extent.height)))
		MCCore.ciContext.render(outImage, to: destinationTexture, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
		*/
	}
}
*/

extension ImageLayer {
    public func toJsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    public static func decode(to: Data) throws -> RenderLayerProtocol {
        return try JSONDecoder().decode(ImageLayer.self, from: to)
    }
}

extension ImageLayer {
    enum CodingKeys: String, CodingKey {
        case id
        case imagePath
        case blendMode
        case alpha
        case renderSize
		case contentMode
        case transform
    }
}

extension ImageLayer: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(CodableURL.init(url: self.imagePath), forKey: .imagePath)
        try container.encode(self.blendMode.rawValue, forKey: .blendMode)
        try container.encode(self.alpha, forKey: .alpha)
        try container.encode(self.renderSize, forKey: .renderSize)
        try container.encode(self.contentMode, forKey: .contentMode)
        try container.encode(self.transform, forKey: .transform)
    }
}

extension ImageLayer: Decodable {
	public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(RenderLayerId.self, forKey: .id)
        let imagePath = (try values.decode(CodableURL.self, forKey: .imagePath)).url
        let blendMode = Blendmode.init(rawValue: try values.decode(String.self, forKey: .blendMode))!
        let alpha = try values.decode(CGFloat.self, forKey: .alpha)
        let renderSize = try values.decode(CGSize.self, forKey: .renderSize)
        let contentMode = try values.decode(CompositionImageLayerContentMode.self, forKey: .contentMode)
        let transform = try values.decode(CGAffineTransform.self, forKey: .transform)
		
		self.init(id: id, imagePath: imagePath, blendMode: blendMode, alpha: alpha, renderSize: renderSize, contentMode: contentMode, transform: transform)
    }
}


public enum CompositionImageLayerContentMode: Int, Codable {
	case scaleToFill = 0
	case scaleAspectFit
	case scaleAspectFill
	case redraw
	case center
	case top
	case bottom
	case left
	case right
	case topLeft
	case topRight
	case bottomLeft
	case bottomRight
	case none
	
	public func transform(imageSize: CGSize, renderSize: CGSize) -> CGAffineTransform {
		switch self {
		case .scaleToFill: return CGAffineTransform.identity
		case .scaleAspectFit: return CGAffineTransform.identity
		case .scaleAspectFill: return CompositionImageLayerContentModeTransform.scaleAspectFill(imageSize: imageSize, renderSize: renderSize)
		//case .scaleAspectFill: return CGAffineTransform.identity
		case .redraw: return CGAffineTransform.identity
		case .center: return CGAffineTransform.identity
		case .top: return CGAffineTransform.identity
		case .bottom: return CGAffineTransform.identity
		case .left: return CGAffineTransform.identity
		case .right: return CGAffineTransform.identity
		case .topLeft: return CGAffineTransform.identity
		case .topRight: return CGAffineTransform.identity
		case .bottomLeft: return CGAffineTransform.identity
		case .bottomRight: return CGAffineTransform.identity
		case .none: return CGAffineTransform.identity
		}
	}
}

class CompositionImageLayerContentModeTransform {
	public static func scaleAspectFill(imageSize: CGSize, renderSize: CGSize) -> CGAffineTransform {
		guard renderSize != imageSize else { return CGAffineTransform(scaleX: 1.0, y: 1.0)  }
		
		let originalSize: CGSize = CGSize(width: imageSize.width, height: imageSize.height)
		
		// スケールを設定
		let scaleW: CGFloat = renderSize.width / originalSize.width
		let scaleH: CGFloat = renderSize.height / originalSize.height
		
		let scale: CGFloat = scaleW > scaleH ? scaleW : scaleH
		let resizeSize: CGSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
		
		let resultTransform: CGAffineTransform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: ((renderSize.width / 2) - (resizeSize.width / 2)) * (1 / scale), y: ((renderSize.height / 2) - (resizeSize.height / 2)) * (1 / scale) )
		return resultTransform
	}
}

