//
//  TransformLayer.swift
//  MystaVideoModule
//
//  Created by 町田 秀行 on 2018/01/21.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import UIKit
import AVFoundation
import MetalCanvas

final public class TransformLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.transformLayer
    public let id: RenderLayerId
    public let customIndex: Int = 0
    public var isAfter: Bool = false
    public var preferredTransform: CGAffineTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
    public var transform: CGAffineTransform
    public var finalTransform: CGAffineTransform?
    public var backgroundColor: UIColor
	
    public init(transform: CGAffineTransform, backgroundColor: UIColor) {
        self.id = RenderLayerId()
        self.transform = transform
        self.backgroundColor = backgroundColor
    }
	
	fileprivate init(id: RenderLayerId, transform: CGAffineTransform, backgroundColor: UIColor) {
		self.id = id
		self.transform = transform
		self.backgroundColor = backgroundColor
	}

    public func setup(assetData: CompositionVideoAsset) {
        //self.preferredTransform = trackData.preferredTransform
    }
    
    /// キャッシュを消去
    public func dispose() {
    }
    
}

extension TransformLayer: CIImageRenderLayerProtocol {
	public func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
		let transformImage: CIImage = image.transformed(by: self.transform)
		let croppingImage: CIImage = transformImage.cropped(to: CGRect(origin: CGPoint.zero, size: renderLayerCompositionInfo.renderSize))
		let result: CIFilter = CIFilter(name: Blendmode.alpha.CIFilterName())!
		result.setValue(CIImage(color: CIColor(cgColor: self.backgroundColor.cgColor)), forKey: kCIInputBackgroundImageKey)
		result.setValue(croppingImage, forKey: kCIInputImageKey)
		let croppingImage002: CIImage = result.outputImage!.cropped(to: CGRect(origin: CGPoint.zero, size: renderLayerCompositionInfo.renderSize))
		return croppingImage002
	}

	public func processing(image: CIImage, compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Float, renderSize: CGSize) -> CIImage? {
		let transformImage: CIImage = image.transformed(by: self.transform)
		let croppingImage: CIImage = transformImage.cropped(to: CGRect(origin: CGPoint.zero, size: renderSize))
		let result: CIFilter = CIFilter(name: Blendmode.alpha.CIFilterName())!
		result.setValue(CIImage(color: CIColor(cgColor: self.backgroundColor.cgColor)), forKey: kCIInputBackgroundImageKey)
		result.setValue(croppingImage, forKey: kCIInputImageKey)
		let croppingImage002: CIImage = result.outputImage!.cropped(to: CGRect(origin: CGPoint.zero, size: renderSize))
		return croppingImage002
	}
}
extension TransformLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard let image: CIImage = CIImage.init(mtlTexture: sourceTexture, options: nil) else { throw RenderLayerErrorType.setupError }
		let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		guard let outImage = self.processing(image: image, compositionTime: renderLayerCompositionInfo.compositionTime, timeRange: renderLayerCompositionInfo.timeRange, percentComplete: Float(renderLayerCompositionInfo.percentComplete), renderSize: renderLayerCompositionInfo.renderSize) else { throw RenderLayerErrorType.setupError }
		MCCore.ciContext.render(outImage, to: destinationTexture, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
	}
}

extension TransformLayer {
    public func toJsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    public static func decode(to: Data) throws -> RenderLayerProtocol {
        return try JSONDecoder().decode(TransformLayer.self, from: to)
    }
}

extension TransformLayer {
    enum CodingKeys: String, CodingKey {
        case id
        case transform
        case backgroundColor
    }
}

extension TransformLayer: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.transform, forKey: .transform)
        //try container.encode(self.backgroundColor, forKey: .backgroundColor)
    }
}

extension TransformLayer: Decodable {
	public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
		let id: RenderLayerId = try values.decode(RenderLayerId.self, forKey: .id)
		let transform: CGAffineTransform = try values.decode(CGAffineTransform.self, forKey: .transform)
		let backgroundColor: UIColor = UIColor.black
		self.init(id: id, transform: transform, backgroundColor: backgroundColor)
    }
}
