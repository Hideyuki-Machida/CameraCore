
//
//  DepthMapRenderer.swift
//  iOS_AVModule
//
//  Created by hideyuki machida on 2019/01/09.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation
import ARKit
import MetalCanvas

/*
extension CCRenderer.ARRenderer {

	public class DepthMapRenderer {
		let queue: DispatchQueue = DispatchQueue(label: "CameraCore.ARVideoCaptureView.depthDataMapUpdateQueue")
		
		public fileprivate(set) var texture: CCTexture?
		
		fileprivate var canvas: MCCanvas?
		fileprivate var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
		fileprivate var image: MCPrimitive.Image?
		
		public init() {
			self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
			self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
		}
		
		public func update(commandBuffer: inout MTLCommandBuffer, depthData: AVDepthData, renderSize: CGSize) throws {
			var depthDataMap: CVPixelBuffer = depthData.depthDataMap
			print(depthDataMap)
			let width: Int = CVPixelBufferGetWidth(depthDataMap)
			let height: Int = CVPixelBufferGetHeight(depthDataMap)
			
			print(width)
			print(height)
			print("kCVPixelFormatType_DisparityFloat16: \(depthData.depthDataType == kCVPixelFormatType_DisparityFloat16)")
			print("kCVPixelFormatType_DisparityFloat32: \(depthData.depthDataType == kCVPixelFormatType_DisparityFloat32)")
			print("kCVPixelFormatType_DepthFloat16: \(depthData.depthDataType == kCVPixelFormatType_DepthFloat16)")
			print("kCVPixelFormatType_DepthFloat32: \(depthData.depthDataType == kCVPixelFormatType_DepthFloat32)")

			let depthDataMapTexture: CCTexture = try CCTexture.init(pixelBuffer: &depthDataMap, colorPixelFormat: .bgra8Unorm, planeIndex: 0)
			
			//////////////////////////////////////////////////////////
			// outTexture canvas 生成
			var outTexture: CCTexture
			if self.texture == nil {
				guard var newImageBuffer: CVImageBuffer = CVImageBuffer.create(size: renderSize) else { return }
				outTexture = try CCTexture.init(pixelBuffer: &newImageBuffer, colorPixelFormat: MTLPixelFormat.bgra8Unorm, planeIndex: 0)
				self.canvas = try MCCanvas.init(destination: &outTexture, orthoType: .topLeft)
			} else {
				outTexture = self.texture!
				try self.canvas?.update(destination: &outTexture)
			}
			//////////////////////////////////////////////////////////

			//////////////////////////////////////////////////////////
			// Orientation変換
			var image: MCPrimitive.Image
			if self.image == nil {
				var mat: MCGeom.Matrix4x4 = MCGeom.Matrix4x4.init()
				mat.scale(x: Float(renderSize.width) / Float(depthDataMapTexture.width), y: Float(renderSize.height) / Float(depthDataMapTexture.height), z: 1.0)
				image = try MCPrimitive.Image.init(texture: depthDataMapTexture, ppsition: SIMD3 .init(0.0, 0.0, 0.0), transform: mat, anchorPoint: MCPrimitive.anchor.topLeft)

				/*
				let angle: CGFloat = 90 * CGFloat.pi / 180
				mat.rotateAroundX(xAngleRad: 0, yAngleRad: 0.0, zAngleRad: Float(angle))
				mat.scale(x: Float(renderSize.width) / Float(depthDataMapTexture.height), y: Float(renderSize.height) / Float(depthDataMapTexture.width), z: 1.0)
				image = try MCPrimitive.Image.init(texture: depthDataMapTexture, ppsition: MCGeom.Vec3D.init(Float(renderSize.width), 0.0, 0.0), transform: mat, anchorPoint: MCPrimitive.anchor.topLeft)
				*/
				self.image = image
			} else {
				image = self.image!
			}
			image.texture = depthDataMapTexture
			try self.canvas?.draw(commandBuffer: &commandBuffer, objects: [
				image,
			])
			//////////////////////////////////////////////////////////
			
			//////////////////////////////////////////////////////////
			// set
			self.texture = outTexture
			//////////////////////////////////////////////////////////

		}
	}

}
*/
