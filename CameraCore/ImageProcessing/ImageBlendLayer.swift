//
//  MetalImageBlendLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/29.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class ImageBlendLayer: RenderLayerProtocol {
    public var id: RenderLayerId
    
    public var type: RenderLayerType = RenderLayerType.ImageBlend
    
    public var customIndex: Int = 0
    private var pipeline: MTLComputePipelineState!
    
    public init() {
        self.id = RenderLayerId()

        do {
            let function = MCCore.library.makeFunction(name: "kernel_imageAlphaBlending")!
            self.pipeline = try MCCore.device.makeComputePipelineState(function: function)
        } catch {
            
        }

    }

    public func dispose() { }
}

extension ImageBlendLayer: MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {}
    public func process(commandBuffer: inout MTLCommandBuffer, originalTexture: inout MTLTexture, overTexture: inout MTLTexture, destinationTexture: inout MTLTexture, renderSize: CGSize) throws {
        let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(self.pipeline)
        encoder.setTexture(originalTexture, index: Int(OriginalTextureIndex.rawValue))
        encoder.setTexture(overTexture, index: Int(OverTextureIndex.rawValue))
        encoder.setTexture(destinationTexture, index: Int(DestinationTextureIndex.rawValue))
        encoder.endEncoding()
    }
}
