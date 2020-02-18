//
//  ImageBlendLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/29.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas

public extension CCImageProcessing {
    final class ImageBlendLayer: RenderLayerProtocol {
        public let id: RenderLayerId
        public let type: RenderLayerType = RenderLayerType.imageBlend
        public let customIndex: Int = 0
        private var pipeline: MTLComputePipelineState

        public convenience init() throws {
            try self.init(id: RenderLayerId())
        }

        public init(id: RenderLayerId) throws {
            self.id = id
            guard let function = MCCore.library.makeFunction(name: "kernel_imageAlphaBlending") else { throw RenderLayerErrorType.setupError }
            self.pipeline = try MCCore.device.makeComputePipelineState(function: function)
        }

        public func dispose() {}
    }
}

public extension CCImageProcessing.ImageBlendLayer {
    func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {}
}

public extension CCImageProcessing.ImageBlendLayer {
    func process(commandBuffer: MTLCommandBuffer, originalTexture: inout MTLTexture, overTexture: inout MTLTexture, destinationTexture: inout MTLTexture, renderSize: CGSize) throws {
        guard let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else { throw RenderLayerErrorType.setupError }
        encoder.setComputePipelineState(self.pipeline)
        encoder.setTexture(originalTexture, index: Int(OriginalTextureIndex.rawValue))
        encoder.setTexture(overTexture, index: Int(OverTextureIndex.rawValue))
        encoder.setTexture(destinationTexture, index: Int(DestinationTextureIndex.rawValue))
        encoder.endEncoding()
    }
}
