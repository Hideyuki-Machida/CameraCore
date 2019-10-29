//
//  DepthMapLayer.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/09/22.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas
import CameraCore

final public class DepthMapLayer: RenderLayerProtocol {
	public let type: RenderLayerType = RenderLayerType.custom
	public let id: RenderLayerId
	public var customIndex: Int = 0
	public var depthMapRenderer: CCRenderer.ARRenderer.DepthMapRenderer
	
	public init() {
		self.id = RenderLayerId()
		self.depthMapRenderer = CCRenderer.ARRenderer.DepthMapRenderer.init()
	}
	
    deinit {
        Debug.DeinitLog(self)
    }

	/// キャッシュを消去
	public func dispose() {
	}
}

extension DepthMapLayer: MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard var depthData = renderLayerCompositionInfo.depthData else { return }
        print(depthData)
        try self.depthMapRenderer.update(commandBuffer: &commandBuffer, depthData: depthData, renderSize: renderLayerCompositionInfo.renderSize)
        destination = self.depthMapRenderer.texture!.texture
    }
}
