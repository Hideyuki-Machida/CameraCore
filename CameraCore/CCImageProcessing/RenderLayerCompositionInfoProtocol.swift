//
//  RenderLayerCompotitionInfoProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/30.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public struct RenderLayerCompositionInfoProperty {
	internal var compositionTime: CMTime
	internal var timeRange: CMTimeRange
	internal var percentComplete: Double
	internal var renderSize: CGSize
	internal var queue: DispatchQueue
	internal var userInfo: RenderLayerUserInfoProtocol
}

public protocol RenderLayerCompositionInfoProtocol {
	var __property: RenderLayerCompositionInfoProperty { get set }
	var compositionTime: CMTime { get }
	var timeRange: CMTimeRange { get }
	var percentComplete: Double { get }
	var renderSize: CGSize { get }
	var queue: DispatchQueue { get }
	var userInfo: RenderLayerUserInfoProtocol { get set }
}
extension RenderLayerCompositionInfoProtocol {
	public var compositionTime: CMTime { get { return self.__property.compositionTime } }
	public var timeRange: CMTimeRange { get { return self.__property.timeRange } }
	public var percentComplete: Double { get { return self.__property.percentComplete } }
	public var renderSize: CGSize { get { return self.__property.renderSize } }
	public var queue: DispatchQueue { get { return self.__property.queue } }
	public var userInfo: RenderLayerUserInfoProtocol { get { return self.__property.userInfo } set { self.__property.userInfo = newValue } }
}
public class RenderLayerCompositionInfo: RenderLayerCompositionInfoProtocol {
	public var __property: RenderLayerCompositionInfoProperty
	public init(compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Double, renderSize: CGSize, queue: DispatchQueue) {
		self.__property = RenderLayerCompositionInfoProperty.init(
			compositionTime: compositionTime,
			timeRange: timeRange,
			percentComplete: percentComplete,
			renderSize: renderSize,
			//metadataObjects: metadataObjects,
			queue: queue,
			userInfo: RenderLayerUserInfo()
		)
	}

}
