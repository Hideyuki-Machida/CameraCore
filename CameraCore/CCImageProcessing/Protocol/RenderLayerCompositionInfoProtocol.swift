//
//  RenderLayerCompotitionInfoProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/30.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas

public struct RenderLayerCompositionInfoProperty {
	internal var compositionTime: CMTime
	internal var timeRange: CMTimeRange
	internal var percentComplete: Double
	internal var renderSize: MCSize
	internal var metadataObjects: [AVMetadataObject]?
	internal var depthData: AVDepthData?
	internal var queue: DispatchQueue
	internal var pixelFormat: MTLPixelFormat
	internal var userInfo: RenderLayerUserInfoProtocol
}

public protocol RenderLayerCompositionInfoProtocol {
	var __property: RenderLayerCompositionInfoProperty { get set }
	var compositionTime: CMTime { get }
	var timeRange: CMTimeRange { get }
	var percentComplete: Double { get }
	var renderSize: MCSize { get }
	var metadataObjects: [AVMetadataObject]? { get }
	var depthData: AVDepthData? { get }
	var queue: DispatchQueue { get }
	var pixelFormat: MTLPixelFormat { get }
	var userInfo: RenderLayerUserInfoProtocol { get set }
}
extension RenderLayerCompositionInfoProtocol {
	public var compositionTime: CMTime { get { return self.__property.compositionTime } }
	public var timeRange: CMTimeRange { get { return self.__property.timeRange } }
	public var percentComplete: Double { get { return self.__property.percentComplete } }
	public var renderSize: MCSize { get { return self.__property.renderSize } }
	public var metadataObjects: [AVMetadataObject]? { get { return self.__property.metadataObjects } }
	public var depthData: AVDepthData? { get { return self.__property.depthData } }
	public var queue: DispatchQueue { get { return self.__property.queue } }
	public var pixelFormat: MTLPixelFormat { get { return self.__property.pixelFormat } }
	public var userInfo: RenderLayerUserInfoProtocol { get { return self.__property.userInfo } set { self.__property.userInfo = newValue } }
}
public class RenderLayerCompositionInfo: RenderLayerCompositionInfoProtocol {
	public var __property: RenderLayerCompositionInfoProperty
	public init(compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Double, renderSize: MCSize, metadataObjects: [AVMetadataObject]?, depthData: AVDepthData?, queue: DispatchQueue, pixelFormat: MTLPixelFormat = .bgra8Unorm) {
		self.__property = RenderLayerCompositionInfoProperty.init(
			compositionTime: compositionTime,
			timeRange: timeRange,
			percentComplete: percentComplete,
			renderSize: renderSize,
			metadataObjects: metadataObjects,
			depthData: depthData,
			queue: queue,
			pixelFormat: pixelFormat,
			userInfo: RenderLayerUserInfo()
		)
	}

}
