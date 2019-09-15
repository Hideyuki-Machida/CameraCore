//
//  LutLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class LutLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.lut
    public var id: RenderLayerId
    public let customIndex: Int = 0
    private let lutImageURL: URL
    private var cubeData: NSData?
    private let dimension: Int
    private var filter: CIFilter? = CIFilter(name: "CIColorCube")
	
    public init(lutImageURL: URL, dimension: Int) {
        self.id = RenderLayerId()
        self.dimension = dimension
        self.lutImageURL = lutImageURL
        self.generateLutCube()
    }

	fileprivate init(id: RenderLayerId, lutImageURL: URL, dimension: Int) {
		self.id = id
		self.dimension = dimension
		self.lutImageURL = lutImageURL
		self.generateLutCube()
	}

    public func setup(assetData: CompositionVideoAsset) {
        //self.preferredTransform = trackData.preferredTransform
    }
    
    /// キャッシュを消去
    public func dispose() {
        self.filter = nil
    }
}

extension LutLayer: CIImageRenderLayerProtocol {
	public func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
		guard let _ = self.cubeData else {
			if let img: CIImage = self.filter?.outputImage {
				return img
			} else {
				throw Renderer.ErrorType.rendering
			}
		}

		self.filter?.setValue(image, forKey: kCIInputImageKey)

		if let img: CIImage = self.filter?.outputImage {
			return img
		} else {
			throw Renderer.ErrorType.rendering
		}
	}
}

extension LutLayer: CameraCore.MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard var inputImage: CIImage = CIImage(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.renderingError }
		inputImage = try processing(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
		MCCore.ciContext.render(inputImage, to: destination, commandBuffer: commandBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
		commandBuffer.commit()
	}
}

extension LutLayer {
    public func toJsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    public static func decode(to: Data) throws -> RenderLayerProtocol {
        return try JSONDecoder().decode(LutLayer.self, from: to)
    }
}

extension LutLayer {
    private func generateLutCube() {
        let lutImage: UIImage = UIImage.init(contentsOfFile: lutImageURL.relativePath)!
        self.cubeData = LUTFilterUtils.generateLUTFilterCubeData(lutImage: lutImage, dimension: self.dimension)
        guard let cubeData: NSData = self.cubeData else { return }
        self.filter?.setValue(self.dimension, forKey: "inputCubeDimension")
        self.filter?.setValue(cubeData, forKey: "inputCubeData")
    }
}

extension LutLayer {
    enum CodingKeys: String, CodingKey {
        case id
        case dimension
        case lutImageURL
    }
}

extension LutLayer: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.dimension, forKey: .dimension)
        try container.encode(CodableURL.init(url: self.lutImageURL), forKey: .lutImageURL)
    }
}

extension LutLayer: Decodable {
	public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
		let id: RenderLayerId = try values.decode(RenderLayerId.self, forKey: .id)
		let dimension: Int = try values.decode(Int.self, forKey: .dimension)
		let lutImagePath: CodableURL = try values.decode(CodableURL.self, forKey: .lutImageURL)
		self.init(id: id, lutImageURL: lutImagePath.url, dimension: dimension)
    }
}
