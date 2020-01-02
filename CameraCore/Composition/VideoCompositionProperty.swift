//
//  VideoCompositionPropertys.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/08/21.
//  Copyright © 2018年 町田 秀行. All rights reserved.
//

import Foundation

public struct VideoCompositionProperty {
    public var frameRate: Int32
    public var presetiFrame: Settings.PresetiFrame
	public var renderSize: CGSize
    public var renderScale: Float
	public var renderType: Settings.RenderType
	public var userInfo: [String: Any] = [:]
	public init(frameRate: Int32, presetiFrame: Settings.PresetiFrame, renderSize: CGSize, renderScale: Float, renderType: Settings.RenderType, userInfo: [String: Any] = [:]) {
        self.frameRate = frameRate
        self.presetiFrame = presetiFrame
		self.renderSize = renderSize
        self.renderScale = renderScale
		self.renderType = renderType
		self.userInfo = userInfo
    }
}

extension VideoCompositionProperty {
    enum CodingKeys: String, CodingKey {
        case frameRate
        case presetiFrame
		case renderSize
        case renderScale
        case renderType
        //case userInfo
    }
}

extension VideoCompositionProperty: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.frameRate, forKey: .frameRate)
        try container.encode(self.presetiFrame.rawValue, forKey: .presetiFrame)
        try container.encode(self.renderSize, forKey: .renderSize)
        try container.encode(self.renderScale, forKey: .renderScale)
        try container.encode(self.renderType, forKey: .renderType)
       // try container.encode(self.userInfo, forKey: .userInfo)
    }
}

extension VideoCompositionProperty: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.frameRate = try values.decode(Int32.self, forKey: .frameRate)
        self.presetiFrame = try values.decode(Settings.PresetiFrame.self, forKey: .presetiFrame)
		self.renderSize = try values.decode(CGSize.self, forKey: .renderSize)
		self.renderScale = try values.decode(Float.self, forKey: .renderScale)
		self.renderType = try values.decode(Settings.RenderType.self, forKey: .renderType)
		//self.userInfo = try values.decode([String: Any].self, forKey: .userInfo)
    }
}
