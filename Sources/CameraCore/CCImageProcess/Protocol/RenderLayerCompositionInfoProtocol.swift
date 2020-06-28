//
//  RenderLayerCompotitionInfoProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/30.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas
import Foundation
import ARKit

public struct RenderLayerCompositionInfoProperty {
    internal var compositionTime: CMTime
    internal var presentationTimeStamp: CMTime
    internal var timeRange: CMTimeRange
    internal var percentComplete: Double
    internal var renderSize: MCSize
    internal var metadataObjects: [AVMetadataObject]
    internal var pixelFormat: MTLPixelFormat
    internal var userInfo: [ String : Any]
}

public protocol RenderLayerCompositionInfoProtocol {
    var __property: RenderLayerCompositionInfoProperty { get set }
    var compositionTime: CMTime { get }
    var presentationTimeStamp: CMTime { get }
    var timeRange: CMTimeRange { get }
    var percentComplete: Double { get }
    var renderSize: MCSize { get }
    var metadataObjects: [AVMetadataObject] { get }
    var pixelFormat: MTLPixelFormat { get }
    var userInfo: [ String : Any] { get set }
}

extension RenderLayerCompositionInfoProtocol {
    public var compositionTime: CMTime { return self.__property.compositionTime }
    public var presentationTimeStamp: CMTime { return self.__property.presentationTimeStamp }
    public var timeRange: CMTimeRange { return self.__property.timeRange }
    public var percentComplete: Double { return self.__property.percentComplete }
    public var renderSize: MCSize { return self.__property.renderSize }
    public var metadataObjects: [AVMetadataObject] { return self.__property.metadataObjects }
    public var pixelFormat: MTLPixelFormat { return self.__property.pixelFormat }
    public var userInfo: [ String : Any] { get { return self.__property.userInfo } set { self.__property.userInfo = newValue } }
}

public class RenderLayerCompositionInfo: RenderLayerCompositionInfoProtocol {
    public var __property: RenderLayerCompositionInfoProperty
    public init(
        compositionTime: CMTime,
        presentationTimeStamp: CMTime,
        timeRange: CMTimeRange,
        percentComplete: Double,
        renderSize: MCSize,
        metadataObjects: [AVMetadataObject],
        pixelFormat: MTLPixelFormat = .bgra8Unorm,
        userInfo: [ String : Any]
    ) {
        self.__property = RenderLayerCompositionInfoProperty(
            compositionTime: compositionTime,
            presentationTimeStamp: presentationTimeStamp,
            timeRange: timeRange,
            percentComplete: percentComplete,
            renderSize: renderSize,
            metadataObjects: metadataObjects,
            pixelFormat: pixelFormat,
            userInfo: userInfo
        )
    }
}
