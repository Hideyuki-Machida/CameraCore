//
//  VideoEncorderProperty.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/11/12.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

public struct VideoEncorderProperty {
	public let exportPath: URL
	public let compositionData: CompositionDataProtocol
	public let frameRate: Int32
	public let presetiFrame: Settings.PresetiFrame
	public let renderSize: CGSize
	public let codec: Settings.VideoCodec
	public let bitRateKey: Int?
	
	public init(exportPath: URL, compositionData: CompositionDataProtocol, frameRate: Int32, presetiFrame: Settings.PresetiFrame, renderSize: CGSize, codec: Settings.VideoCodec, bitRateKey: Int? = nil) {
		self.exportPath = exportPath
		self.compositionData = compositionData
		self.frameRate = frameRate
		self.presetiFrame = presetiFrame
		self.renderSize = renderSize
		self.codec = codec
		self.bitRateKey = bitRateKey
	}
}
