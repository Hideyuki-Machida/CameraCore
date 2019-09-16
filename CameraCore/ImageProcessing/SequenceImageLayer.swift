//
//  SequenceImageLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class SequenceImageLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.sequenceImage
    public var id: RenderLayerId
    public let customIndex: Int = 0
    private let imagePaths: [URL]
	//private var overImages: [Int: MCTexture] = [:]
    private let blendMode: Blendmode
    private let alpha: CGFloat
    private let updateFrameRate: TimeInterval
    private let resize: Bool
	
	private var _filterCashImageList: [Int: CIImage] = [:] // エフェクトフィルターキャッシュ

	
    public init(imagePaths: [URL], blendMode: Blendmode, alpha: CGFloat = 1.0, updateFrameRate: Int32 = 30, resize: Bool = true) {
        self.id = RenderLayerId()
		self.imagePaths = imagePaths.sorted(by: {$0.lastPathComponent < $1.lastPathComponent})
        self.blendMode = blendMode
        self.alpha = alpha
        self.updateFrameRate = TimeInterval(updateFrameRate)
        self.resize = resize
    }

	fileprivate init(id: RenderLayerId, imagePaths: [URL], blendMode: Blendmode, alpha: CGFloat = 1.0, updateFrameRate: TimeInterval = 30, resize: Bool = true) {
        self.id = id
		self.imagePaths = imagePaths.sorted(by: {$0.lastPathComponent < $1.lastPathComponent})
		self.blendMode = blendMode
		self.alpha = alpha
		self.updateFrameRate = updateFrameRate
		self.resize = resize
	}
	
    //public func setup(assetData: CompositionVideoAsset) {}
    
	/// キャッシュを消去
	public func dispose() {
		self._filterCashImageList.removeAll()
	}

}

extension SequenceImageLayer: CIImageRenderLayerProtocol {
	public func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
		let imageCounter: Float = Float(renderLayerCompositionInfo.compositionTime.value) * Float(self.updateFrameRate) / Float(renderLayerCompositionInfo.compositionTime.timescale)

		// フィルターイメージ生成
		let counter: Int = Int(floorf(imageCounter)) % self.imagePaths.count
		guard var filterImage: CIImage = self._getFilterImage(count: counter, renderSize: renderLayerCompositionInfo.renderSize) else { return image }

		// 上下反転
		filterImage = filterImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1.0).translatedBy(x: 0, y: -CGFloat(filterImage.extent.height)))
		
		let colorMatrixfilter: CIFilter = CIFilter(name:"CIColorMatrix")!
		colorMatrixfilter.setValue(filterImage, forKey: kCIInputImageKey)
		colorMatrixfilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: self.alpha), forKey: "inputAVector")
		
		// フィルター合成
		let result: CIFilter = CIFilter(name: self.blendMode.CIFilterName())!
		
		result.setValue(image, forKey: kCIInputBackgroundImageKey)
		result.setValue(colorMatrixfilter.outputImage!, forKey: kCIInputImageKey)
		
		return result.outputImage ?? image
	}
	
	// MARK: - Private -
	private func _getFilterImage(count: Int, renderSize: CGSize) -> CIImage? {
		// フィルターイメージ作成
		if let filter: CIImage = self._filterCashImageList[ count ] {
			return filter
		} else {
			if let filetr: CIImage = self._loadFilterImage(count: count, renderSize: renderSize) {
				self._filterCashImageList[ count ] = filetr
				return filetr
			}
			return nil
		}
	}
	
	/// フィルタイメージ生成・取得
	private func _loadFilterImage(count: Int, renderSize: CGSize) -> CIImage? {
		// フィルターイメージ作成
		let imagePath: URL = self.imagePaths[count]
		guard var effect: CIImage = CIImage(contentsOf: imagePath) else { return nil }
		if self.resize {
			// フィルターイメージリサイズ
			let effectExtent: CGRect = effect.extent
			let ex: CGSize = renderSize
			let p: CGFloat = max(ex.width / effectExtent.width, ex.height / effectExtent.height)
			effect = effect.transformed(by: CGAffineTransform.init(scaleX: p, y: p))
			let y: CGFloat = effect.extent.size.height - renderSize.height
			effect = effect.transformed(by: CGAffineTransform.init(translationX: 0, y: -y))
			effect = effect.cropped(to: CGRect.init(origin: CGPoint.init(0.0, 0.0), size: renderSize) )
			return effect
		} else {
			return effect
		}
	}
}

/*
extension SequenceImageLayer: CameraCore.CVPixelBufferRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> Void {
		var inputImage: CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
		inputImage = try processing(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		MCCore.ciContext.render(inputImage, to: pixelBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
	}
}
*/
extension SequenceImageLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard var inputImage: CIImage = CIImage(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.renderingError }
		inputImage = try processing(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		//guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
		MCCore.ciContext.render(inputImage, to: destination, commandBuffer: commandBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
		//commandBuffer.commit()
	}
}

/*
extension SequenceImageLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard var inputImage: CIImage = CIImage(mtlTexture: sourceTexture, options: nil) else { throw RenderLayerErrorType.renderingError }
		inputImage = try processing(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		
		guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
		MCCore.ciContext.render(inputImage, to: destinationTexture, commandBuffer: commandBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
		commandBuffer.commit()
	}

}
*/
/*
extension SequenceImageLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {

		let sourceMCTexture: MCTexture = try MCTexture.init(texture: sourceTexture)
		var destinationMCTexture: MCTexture = try MCTexture.init(texture: destinationTexture)
		let canvas: MCCanvas = try MCCanvas.init(destination: &destinationMCTexture, orthoType: .topLeft)
		let renderSize: CGSize = renderLayerCompositionInfo.renderSize
		let compositionTime: CMTime = renderLayerCompositionInfo.compositionTime

		let imageCounter: Float = Float(compositionTime.value) * Float(self.updateFrameRate) / Float(compositionTime.timescale)
		
		// フィルターイメージ生成
		let counter: Int = Int(floorf(imageCounter)) % self.imagePaths.count
		let overFilterMCTexture: MCTexture = try self._getOverMCTexture(commandBuffer: commandBuffer, count: counter, renderSize: renderSize)
		

		let sourceImage: MCPrimitive.Image = try MCPrimitive.Image.init(texture: sourceMCTexture,
																		ppsition: MCGeom.Vec3D.init(x: Float(renderSize.width / 2.0), y: Float(renderSize.height / 2.0), z: 0),
																		transform: MCGeom.Matrix4x4.init(scaleX: 1.0, scaleY: 1.0, scaleZ: 1.0),
																		anchorPoint: .center
		)

		let overImage: MCPrimitive.Image = try MCPrimitive.Image.init(texture: overFilterMCTexture,
																	  ppsition: MCGeom.Vec3D.init(x: Float(renderSize.width / 2.0), y: Float(renderSize.height / 2.0), z: 0),
																	  transform: MCGeom.Matrix4x4.init(scaleX: Float(renderSize.width) / Float(overFilterMCTexture.width), scaleY: Float(renderSize.height) / Float(overFilterMCTexture.height), scaleZ: 1.0),
																	  anchorPoint: .center
		)

		print(MCCore.device.currentAllocatedSize)
		try canvas.draw(commandBuffer: &commandBuffer, objects: [sourceImage, overImage])
		//try canvas.draw(commandBuffer: &commandBuffer, objects: [sourceImage])
		
		/*
		guard let image: CIImage = CIImage.init(mtlTexture: sourceTexture, options: nil) else { throw RenderLayerErrorType.setupError }
		let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		let outImage: CIImage = try self.processing(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		MCCore.ciContext.render(outImage, to: destinationTexture, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
*/
	}
	
	// MARK: - Private -
	private func _getOverMCTexture(commandBuffer: MTLCommandBuffer, count: Int, renderSize: CGSize) throws -> MCTexture {
		// フィルターイメージ作成
		let imagePath: URL = self.imagePaths[count]
		
		if let overImage: MCTexture = self.overImages[count] {
			return overImage
		} else {
			//let overImage: MCTexture = try MCTexture.init(renderSize: CGSize.init(100, 100) )
			//let overImage: MCTexture = try MCTexture.init(URL: imagePath)
			let overImage: MCTexture = try MCTexture.init(URL: imagePath, commandBuffer: commandBuffer)
			self.overImages[count] = overImage
			return overImage
		}
	}

}
*/
extension SequenceImageLayer {
    public func toJsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    public static func decode(to: Data) throws -> RenderLayerProtocol {
        return try JSONDecoder().decode(SequenceImageLayer.self, from: to)
    }
}

extension SequenceImageLayer {
    enum CodingKeys: String, CodingKey {
        case id
        case imagePaths
        case blendMode
        case alpha
        case updateFrameRate
        case resize
    }
}

extension SequenceImageLayer: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.imagePaths.map {CodableURL.init(url: $0)}, forKey: .imagePaths)
        try container.encode(self.blendMode.rawValue, forKey: .blendMode)
        try container.encode(self.alpha, forKey: .alpha)
        try container.encode(self.updateFrameRate, forKey: .updateFrameRate)
        try container.encode(self.resize, forKey: .resize)
    }
}

extension SequenceImageLayer: Decodable {
	public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
		let id: RenderLayerId = try values.decode(RenderLayerId.self, forKey: .id)
		let imagePaths: [URL] = (try values.decode([CodableURL].self, forKey: .imagePaths)).map { $0.url }
		let blendMode: Blendmode = Blendmode.init(rawValue: try values.decode(String.self, forKey: .blendMode))!
		let alpha: CGFloat = try values.decode(CGFloat.self, forKey: .alpha)
		let updateFrameRate: TimeInterval = try values.decode(TimeInterval.self, forKey: .updateFrameRate)
		let resize: Bool = try values.decode(Bool.self, forKey: .resize)
		self.init(id: id, imagePaths: imagePaths, blendMode: blendMode, alpha: alpha, updateFrameRate: updateFrameRate, resize: resize)
    }
}
