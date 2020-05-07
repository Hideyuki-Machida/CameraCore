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

public struct RenderLayerCompositionInfoProperty {
    internal var compositionTime: CMTime
    internal var presentationTimeStamp: CMTime
    internal var captureInfo: CCCapture.VideoCapture.CaptureInfo
    internal var timeRange: CMTimeRange
    internal var percentComplete: Double
    internal var renderSize: MCSize
    internal var metadataObjects: [AVMetadataObject]
    internal var depthData: AVDepthData?
    internal var queue: DispatchQueue
    internal var pixelFormat: MTLPixelFormat
    internal var inferenceUserInfo: [ String : Any]
    internal var userInfo: RenderLayerUserInfoProtocol
}

public protocol RenderLayerCompositionInfoProtocol {
    var __property: RenderLayerCompositionInfoProperty { get set }
    var compositionTime: CMTime { get }
    var presentationTimeStamp: CMTime { get }
    var captureInfo: CCCapture.VideoCapture.CaptureInfo { get }
    var timeRange: CMTimeRange { get }
    var percentComplete: Double { get }
    var renderSize: MCSize { get }
    var metadataObjects: [AVMetadataObject] { get }
    var depthData: AVDepthData? { get }
    var queue: DispatchQueue { get }
    var pixelFormat: MTLPixelFormat { get }
    var inferenceUserInfo: [ String : Any] { get }
    var userInfo: RenderLayerUserInfoProtocol { get set }
}

extension RenderLayerCompositionInfoProtocol {
    public var compositionTime: CMTime { return self.__property.compositionTime }
    public var presentationTimeStamp: CMTime { return self.__property.presentationTimeStamp }
    public var captureInfo: CCCapture.VideoCapture.CaptureInfo { return self.__property.captureInfo }
    public var timeRange: CMTimeRange { return self.__property.timeRange }
    public var percentComplete: Double { return self.__property.percentComplete }
    public var renderSize: MCSize { return self.__property.renderSize }
    public var metadataObjects: [AVMetadataObject] { return self.__property.metadataObjects }
    public var depthData: AVDepthData? { return self.__property.depthData }
    public var queue: DispatchQueue { return self.__property.queue }
    public var pixelFormat: MTLPixelFormat { return self.__property.pixelFormat }
    public var inferenceUserInfo: [ String : Any]  { return self.__property.inferenceUserInfo }
    public var userInfo: RenderLayerUserInfoProtocol { get { return self.__property.userInfo } set { self.__property.userInfo = newValue } }
}

public class RenderLayerCompositionInfo: RenderLayerCompositionInfoProtocol {
    public var __property: RenderLayerCompositionInfoProperty
    public init(compositionTime: CMTime, presentationTimeStamp: CMTime, captureInfo: CCCapture.VideoCapture.CaptureInfo, timeRange: CMTimeRange, percentComplete: Double, renderSize: MCSize, metadataObjects: [AVMetadataObject], depthData: AVDepthData?, queue: DispatchQueue, pixelFormat: MTLPixelFormat = .bgra8Unorm, inferenceUserInfo: [ String : Any]) {
        self.__property = RenderLayerCompositionInfoProperty(
            compositionTime: compositionTime,
            presentationTimeStamp: presentationTimeStamp,
            captureInfo: captureInfo,
            timeRange: timeRange,
            percentComplete: percentComplete,
            renderSize: renderSize,
            metadataObjects: metadataObjects,
            depthData: depthData,
            queue: queue,
            pixelFormat: pixelFormat,
            inferenceUserInfo: inferenceUserInfo,
            userInfo: RenderLayerUserInfo()
            
        )
    }
}
