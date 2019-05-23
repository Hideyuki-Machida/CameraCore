//
//  RGBCameraRendere.swift
//  iOS_AVModule
//
//  Created by hideyuki machida on 2019/01/09.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation
import ARKit
import MetalCanvas

extension Renderer.ARRenderer {
	class RGBCameraRenderer {
		fileprivate(set) var texture: MCTexture?
		
		fileprivate var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
		fileprivate var rgbOutTexture: MCTexture?
		fileprivate let colorSpaceYCbCrToRGB: MCFilter.ColorSpace.YCbCrToRGB = MCFilter.ColorSpace.YCbCrToRGB()
		fileprivate var image: MCPrimitive.Image?
		fileprivate var canvas: MCCanvas?
		
		init() {
			self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
			self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
		}
		
		func update(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderSize: CGSize) throws {
			guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else { return }
			//////////////////////////////////////////////////////////
			// YCbCr → RGB 変換
			var capturedImageTextureY: MCTexture = try MCTexture.init(pixelBuffer: &pixelBuffer, colorPixelFormat: .r8Unorm, planeIndex: 0)
			var capturedImageTextureCbCr: MCTexture = try MCTexture.init(pixelBuffer: &pixelBuffer, colorPixelFormat: .rg8Unorm, planeIndex: 1)
			
			var rgbOutTexture: MCTexture
			if self.rgbOutTexture == nil {
				guard var rgbOutImageBuffer: CVImageBuffer = CVImageBuffer.create(size: CGSize.init(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))) else { return }
				rgbOutTexture = try MCTexture.init(pixelBuffer: &rgbOutImageBuffer, colorPixelFormat: MTLPixelFormat.bgra8Unorm, planeIndex: 0)
				self.renderPassDescriptor.colorAttachments[0].texture = rgbOutTexture.texture
				self.rgbOutTexture = rgbOutTexture
			} else {
				rgbOutTexture = self.rgbOutTexture!
				//try self.canvas?.update(destination: &destinationTexture)
			}
			
			var outTexture: MCTexture
			if self.texture == nil {
				guard var outImageBuffer: CVImageBuffer = CVImageBuffer.create(size: renderSize) else { return }
				outTexture = try MCTexture.init(pixelBuffer: &outImageBuffer, colorPixelFormat: MTLPixelFormat.bgra8Unorm, planeIndex: 0)
				self.canvas = try MCCanvas.init(destination: &outTexture, orthoType: .topLeft)
			} else {
				outTexture = self.texture!
				try self.canvas?.update(destination: &outTexture)
			}

			try self.colorSpaceYCbCrToRGB.processing(
				commandBuffer: &commandBuffer,
				capturedImageTextureY: &capturedImageTextureY,
				capturedImageTextureCbCr: &capturedImageTextureCbCr,
				renderPassDescriptor: self.renderPassDescriptor,
				renderSize: renderSize
			)
			//////////////////////////////////////////////////////////
			
			//////////////////////////////////////////////////////////
			// Orientation変換
			var image: MCPrimitive.Image
			if self.image == nil {
				var mat: MCGeom.Matrix4x4 = MCGeom.Matrix4x4.init()
				let angle: CGFloat = 90 * CGFloat.pi / 180
				mat.rotateAroundX(xAngleRad: 0, yAngleRad: 0.0, zAngleRad: Float(angle))
				image = try MCPrimitive.Image.init(texture: rgbOutTexture, ppsition: MCGeom.Vec3D.init(Float(renderSize.width), 0.0, 0.0), transform: mat, anchorPoint: MCPrimitive.anchor.topLeft)
				self.image = image
			} else {
				image = self.image!
			}
			image.texture = rgbOutTexture
			try self.canvas?.draw(commandBuffer: &commandBuffer, objects: [
				image,
				])
			//////////////////////////////////////////////////////////
			
			self.texture = outTexture
		}
	}
}
