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

    public enum Dimension: Int, Codable {
        case d1 = 16
        case d3 = 64
    }

    public let type: RenderLayerType = RenderLayerType.lut
    public var id: RenderLayerId
    public let customIndex: Int = 0
    private let lutImageURL: URL
    private var lutFilter: MCFilter.ColorProcessing.Lut3DFilter
    private var cubeData: NSData?
    private let dimension: Dimension
	
	public var intensity: Float = 1.0 {
		willSet {
			self.lutFilter.intensity = newValue
		}
	}
	
    public init(lutImageURL: URL, dimension: Dimension) throws {
        self.id = RenderLayerId()
        self.dimension = dimension
        self.lutImageURL = lutImageURL
		self.lutFilter = MCFilter.ColorProcessing.Lut3DFilter.init(lutImageTexture: try MCTexture.init(URL: lutImageURL))
		self.lutFilter.intensity = self.intensity
    }

	fileprivate init(id: RenderLayerId, lutImageURL: URL, dimension: Dimension) throws {
		self.id = id
		self.dimension = dimension
		self.lutImageURL = lutImageURL
		self.lutFilter = MCFilter.ColorProcessing.Lut3DFilter.init(lutImageTexture: try MCTexture.init(URL: lutImageURL))
		self.lutFilter.intensity = self.intensity
	}

	/*
    public func setup(assetData: CompositionVideoAsset) {
        //self.preferredTransform = trackData.preferredTransform
    }
    */
    /// キャッシュを消去
    public func dispose() {

    }
}

extension LutLayer: CameraCore.MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		let imageTexture: MCTexture = try MCTexture.init(texture: source)
		var destination: MCTexture = try MCTexture.init(texture: destination)
		try self.lutFilter.processing(commandBuffer: &commandBuffer, imageTexture: imageTexture, destinationTexture: &destination)
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
		let dimension: Dimension = try values.decode(Dimension.self, forKey: .dimension)
		let lutImagePath: CodableURL = try values.decode(CodableURL.self, forKey: .lutImageURL)
		try self.init(id: id, lutImageURL: lutImagePath.url, dimension: dimension)
    }
}
