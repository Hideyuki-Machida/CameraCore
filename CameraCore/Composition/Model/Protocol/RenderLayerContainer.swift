//
//  RenderLayerContainer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
/*
public struct RenderLayerContainer {
	public var type: RenderLayerType
	public var customIndex: Int
	public var renderLayer: RenderLayerProtocol
	public init(type: RenderLayerType, customIndex: Int, renderLayer: RenderLayerProtocol) {
		self.type = type
		self.customIndex = customIndex
		self.renderLayer = renderLayer
	}
}

extension RenderLayerContainer {
	enum CodingKeys: String, CodingKey {
		case type
		case customIndex
		case renderLayer
	}
}

//var renderLayerList: [RenderLayerProtocol.Type] = [BlankLayer.self, TransformLayer.self, LutLayer.self, ImageLayer.self, SequenceImageLayer.self]
extension RenderLayerContainer: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.type.rawValue, forKey: .type)
		try container.encode(self.customIndex, forKey: .customIndex)
		try container.encode(self.renderLayer.toJsonData(), forKey: .renderLayer)
	}
}

extension RenderLayerContainer: Decodable {
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.type = try values.decode(RenderLayerType.self, forKey: .type)
		self.customIndex = try values.decode(Int.self, forKey: .customIndex)
		let renderLayerData = try values.decode(Data.self, forKey: .renderLayer)
		if self.type.type() != nil {
			self.renderLayer = try self.type.type()!.decode(to: renderLayerData)
		} else {
			self.renderLayer = try self.type.type()!.decode(to: renderLayerData)
		}
	}
}
*/
