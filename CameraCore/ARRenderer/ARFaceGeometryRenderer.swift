//
//  ARFaceGeometryRenderer.swift
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
	class ARFaceGeometryRenderer {
		let queue: DispatchQueue = DispatchQueue(label: "CameraCore.Renderer.ARRendererARFaceGeometryRenderer")
		fileprivate(set) var texture: MCTexture?

		fileprivate var renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
		fileprivate var faceGeometry: ARSCNFaceGeometry!
		fileprivate var faceNode: SCNNode!

		init() {
			self.renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
			self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

			self.faceGeometry = ARSCNFaceGeometry(device: MCCore.device, fillMesh: false)
			self.faceGeometry.firstMaterial?.fillMode = .lines
			if let material = faceGeometry.firstMaterial {
				material.diffuse.contents = UIColor.lightGray
				material.lightingModel = .physicallyBased
			}
			self.faceNode = SCNNode(geometry: self.faceGeometry)
		}
		
		
		func add(faceAnchor: ARFaceAnchor, scnRenderer: SCNRenderer) {
			// faceGeometry(顔のジオメトリ)を更新
			self.faceGeometry.update(from: faceAnchor.geometry)
			// faceNode(顔のジオメトリを持つノード)を子ノードとして追加
			scnRenderer.scene?.rootNode.addChildNode(self.faceNode)
		}
		
		func update(commandBuffer: inout MTLCommandBuffer, faceAnchor: inout ARFaceAnchor, scnRenderer: SCNRenderer, renderSize: CGSize) throws {
			
			let geometry: ARFaceGeometry = faceAnchor.geometry
			self.faceGeometry.update(from: geometry)
			self.faceNode.transform = SCNMatrix4.init(faceAnchor.transform)

			var outTexture: MCTexture
			if self.texture == nil {
				guard var newImageBuffer: CVImageBuffer = CVImageBuffer.create(size: renderSize) else { return }
				outTexture = try MCTexture.init(pixelBuffer: &newImageBuffer, colorPixelFormat: MTLPixelFormat.bgra8Unorm, planeIndex: 0)
				self.renderPassDescriptor.colorAttachments[0].texture = outTexture.texture
				self.texture = outTexture
			} else {
				outTexture = self.texture!
			}
			
			scnRenderer.render(atTime: CFTimeInterval.init(), viewport: CGRect.init(origin: CGPoint.init(), size: renderSize), commandBuffer: commandBuffer, passDescriptor: self.renderPassDescriptor)
			self.texture = outTexture
			//destinationTexture = outTexture
		}
	}
}
*/
