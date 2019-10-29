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
        self.lutFilter = try MCFilter.ColorProcessing.Lut3DFilter.init(lutImageTexture: try MCTexture.init(URL: lutImageURL, SRGB: false))
        self.lutFilter.intensity = self.intensity
    }

    fileprivate init(id: RenderLayerId, lutImageURL: URL, dimension: Dimension) throws {
        self.id = id
        self.dimension = dimension
        self.lutImageURL = lutImageURL
        self.lutFilter = try MCFilter.ColorProcessing.Lut3DFilter.init(lutImageTexture: try MCTexture.init(URL: lutImageURL, SRGB: false))
        self.lutFilter.intensity = self.intensity
    }

    public func dispose() { }
}

extension LutLayer: CameraCore.MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        let imageTexture: MCTexture = try MCTexture.init(texture: source)
        var destination: MCTexture = try MCTexture.init(texture: destination)
        try self.lutFilter.process(commandBuffer: &commandBuffer, imageTexture: imageTexture, destinationTexture: &destination)
    }
}
