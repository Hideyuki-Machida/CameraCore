//
//  MetalImageBlendLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/29.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class MetalImageBlendLayer: RenderLayerProtocol {
	public var id: RenderLayerId
	
	public var type: RenderLayerType = RenderLayerType.metalImageBlend
	
	public var customIndex: Int = 0
	private var pipeline: MTLComputePipelineState!
	private var threadExecutionWidth: Int!
	private var maxTotalThreadsPerThreadgroup: Int!
	private var threadsPerThreadgroup: MTLSize!
	public init() {
		self.id = RenderLayerId()

		do {
			let function = MCCore.library.makeFunction(name: "kernel_imageAlphaBlending")!
			self.pipeline = try MCCore.device.makeComputePipelineState(function: function)
			self.threadExecutionWidth = self.pipeline.threadExecutionWidth
			self.maxTotalThreadsPerThreadgroup = self.pipeline.maxTotalThreadsPerThreadgroup / self.threadExecutionWidth
			//self.threadsPerThreadgroup = MTLSizeMake(self.threadExecutionWidth, self.maxTotalThreadsPerThreadgroup, 1)
			self.threadsPerThreadgroup = MTLSize(width: 16, height: 1, depth: 1)
		} catch {
			
		}

	}
	
	//public func setup(assetData: CompositionVideoAsset) { }
	
	public func dispose() {
		
	}
}

extension MetalImageBlendLayer: MetalRenderLayerProtocol {
	public func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {}
	public func processing(commandBuffer: inout MTLCommandBuffer, originalTexture: inout MTLTexture, overTexture: inout MTLTexture, destinationTexture: inout MTLTexture, renderSize: CGSize) throws {
		let threadsPerGrid: MTLSize = MTLSize(width: destinationTexture.width, height: destinationTexture.height, depth: 1)

		let encoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
		encoder.setComputePipelineState(self.pipeline)
		encoder.setTexture(originalTexture, index: Int(OriginalTextureIndex.rawValue))
		encoder.setTexture(overTexture, index: Int(OverTextureIndex.rawValue))
		encoder.setTexture(destinationTexture, index: Int(DestinationTextureIndex.rawValue))
		encoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: self.threadsPerThreadgroup)
		encoder.endEncoding()
	}
}
