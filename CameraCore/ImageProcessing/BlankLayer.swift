//
//  BlankLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation

final public class BlankLayer: RenderLayerProtocol {
    
    public let type: RenderLayerType = RenderLayerType.blank
    public let id: RenderLayerId
    public let customIndex: Int = 0
    public init() {
        self.id = RenderLayerId()
    }
    fileprivate init(id: RenderLayerId) {
        self.id = id
    }

    public func dispose() {
    }
}

extension BlankLayer: MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {}
}
