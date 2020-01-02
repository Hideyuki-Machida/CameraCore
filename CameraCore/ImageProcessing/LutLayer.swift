//
//  LutLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas
import Vision

public extension CCImageProcessing {
    final class LutLayer: RenderLayerProtocol {
        public enum Dimension: Int, Codable {
            case dim3 = 64
        }

        public let type: RenderLayerType = RenderLayerType.lut
        public let id: RenderLayerId
        public let customIndex: Int = 0
        private let lutImageURL: URL
        private var lutFilter: MCFilter.ColorProcessing.Lut3DFilter
        private let dimension: Dimension

        public var intensity: Float = 1.0 {
            willSet {
                self.lutFilter.intensity = newValue
            }
        }

        public convenience init(lutImageURL: URL, dimension: Dimension) throws {
            try self.init(id: RenderLayerId(), lutImageURL: lutImageURL, dimension: dimension)
        }

        public init(id: RenderLayerId, lutImageURL: URL, dimension: Dimension) throws {
            self.id = id
            self.dimension = dimension
            self.lutImageURL = lutImageURL
            self.lutFilter = try MCFilter.ColorProcessing.Lut3DFilter(lutImageTexture: try MCTexture(URL: lutImageURL, isSRGB: false))
            self.lutFilter.intensity = self.intensity
        }

        public func dispose() {}
    }
}

public extension CCImageProcessing.LutLayer {
    func process(commandBuffer: MTLCommandBuffer, source: MCTexture, destination: inout MCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        try self.lutFilter.process(commandBuffer: commandBuffer, imageTexture: source, destinationTexture: &destination)
    }
}
