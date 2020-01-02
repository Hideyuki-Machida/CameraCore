//
//  BlankLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas

public extension CCImageProcessing {
    final class BlankLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.blank
        public let id: RenderLayerId
        public let customIndex: Int = 0

        public convenience init() {
            self.init(id: RenderLayerId())
        }

        public init(id: RenderLayerId) {
            self.id = id
        }

        public func dispose() {}
    }
}

public extension CCImageProcessing.BlankLayer {
    func process(commandBuffer: MTLCommandBuffer, source: MCTexture, destination: inout MCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {}
}
