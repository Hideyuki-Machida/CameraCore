//
//  BlankLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation

final public class BlankLayer: RenderLayerProtocol {
	
    public let type: RenderLayerType = RenderLayerType.blank
    public let id: RenderLayerId
    public let customIndex: Int = 0
    public init() {
        self.id = RenderLayerId()
    }
	fileprivate init(id: RenderLayerId) {
		self.id = id
	}

    //public func setup(assetData: CompositionVideoAsset) { }
	
    /// キャッシュを消去
    public func dispose() {
    }
}

extension BlankLayer: CIImageRenderLayerProtocol {
	public func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
		return image
	}
}
extension BlankLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {}
}

extension BlankLayer {
    public func toJsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    public static func decode(to: Data) throws -> RenderLayerProtocol {
        return try JSONDecoder().decode(BlankLayer.self, from: to)
    }
}

extension BlankLayer {
    enum CodingKeys: String, CodingKey {
        case id
    }
}

extension BlankLayer: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
    }
}

extension BlankLayer: Decodable {
	public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(RenderLayerId.self, forKey: .id)
		self.init(id: id)
    }
}
