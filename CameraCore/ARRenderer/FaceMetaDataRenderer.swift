//
//  FaceMetaDataRender.swift
//  iOS_AVModule
//
//  Created by hideyuki machida on 2019/01/11.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation
import ARKit
import MetalCanvas
import Vision

extension Renderer.ARRenderer {
	public class FaceMetaDataRenderer {

		let queue: DispatchQueue = DispatchQueue(label: "com.cchannel.iOS_AVModule.ARVideoCaptureView.FaceMetaDataRendererQueue")

		fileprivate var canvas: MCCanvas?
		public fileprivate(set) var texture: MCTexture?
		fileprivate(set) var faces: [MCVision.Detection.Face.Item] = []
		
		public init() {}
		
		public func update(commandBuffer: inout MTLCommandBuffer, metadataFaceObjects: [AVMetadataFaceObject], pixelBuffer: inout CVPixelBuffer, renderSize: CGSize) throws {
			//////////////////////////////////////////////////////////
			// outTexture canvas 生成
			var outTexture: MCTexture
			if self.texture == nil {
				guard var newImageBuffer: CVPixelBuffer = CVPixelBuffer.create(size: renderSize) else { return }
				outTexture = try MCTexture.init(pixelBuffer: &newImageBuffer, colorPixelFormat: MTLPixelFormat.bgra8Unorm, planeIndex: 0)
				//self.canvas = try MCCanvas.init(destination: &outTexture, orthoType: .topLeft, loadAction: MTLLoadAction.clear)
				self.canvas = try MCCanvas.init(destination: &outTexture, orthoType: .perspective, loadAction: MTLLoadAction.clear)
			} else {
				outTexture = self.texture!
				try self.canvas?.update(destination: &outTexture)
			}
			//////////////////////////////////////////////////////////

			//////////////////////////////////////////////////////////
			// outTexture canvas 生成
			var faceBoundPoints: [MCGeom.Vec3D] = []
			var tempFaces: [MCVision.Detection.Face.Item] = []
			for metadataFaceObject: AVMetadataFaceObject in metadataFaceObjects {
				print("faceID: \(metadataFaceObject.faceID)")
				var faceItemFlg: Bool = false
				let bounds: CGRect = metadataFaceObject.bounds
				/*
				faceBoundPoints.append(MCGeom.Vec3D.init(Float(boundes.origin.x), Float(boundes.origin.y), 0.0))
				faceBoundPoints.append(MCGeom.Vec3D.init(Float(boundes.origin.x), Float(boundes.origin.y + boundes.size.height), 0.0))
				faceBoundPoints.append(MCGeom.Vec3D.init(Float(boundes.origin.x + boundes.size.width), Float(boundes.origin.y + boundes.size.height), 0.0))
				faceBoundPoints.append(MCGeom.Vec3D.init(Float(boundes.origin.x + boundes.size.width), Float(boundes.origin.y), 0.0))
				*/
				let normalBoundes: CGRect = (bounds + CGRect.init(x: -20, y: -20, width: 40, height: 40)).normalized(size: renderSize)
				let landmarkDetectionBoundes: CGRect = normalBoundes * 2.0
				let trackingBoundes: CGRect = normalBoundes * 2.0 * CGRect.init(x: 1.0, y: -1.0, width: 1.0, height: -1.0) - CGRect.init(origin: CGPoint.init(1.0, -1.0), size: CGSize.init(0.0, 0.0))
				print("---@1")
				print(trackingBoundes)
				
				faceBoundPoints.append(MCGeom.Vec3D.init(Float(trackingBoundes.origin.x), Float(trackingBoundes.origin.y), 0.0))
				faceBoundPoints.append(MCGeom.Vec3D.init(Float(trackingBoundes.origin.x), Float(trackingBoundes.origin.y + trackingBoundes.size.height), 0.0))
				faceBoundPoints.append(MCGeom.Vec3D.init(Float(trackingBoundes.origin.x + trackingBoundes.size.width), Float(trackingBoundes.origin.y + trackingBoundes.size.height), 0.0))
				faceBoundPoints.append(MCGeom.Vec3D.init(Float(trackingBoundes.origin.x + trackingBoundes.size.width), Float(trackingBoundes.origin.y), 0.0))
				print("---@2")
				print(faceBoundPoints)
				
				for face: MCVision.Detection.Face.Item in self.faces {
					if face.id == metadataFaceObject.faceID {
						print("ある Face: \(face.id)")
						//print(metadataFaceObject.bounds)
						//face.landmarkDetection(pixelBuffer: &imageBuffer, observation: VNDetectedObjectObservation.init(boundingBox: boundes))
						//face.tracking(pixelBuffer: &pixelBuffer)
						face.landmarkDetection(pixelBuffer: &pixelBuffer, observation: VNDetectedObjectObservation.init(boundingBox: landmarkDetectionBoundes))
						tempFaces.append(face)
						faceItemFlg = true
						continue
					}
				}

				if faceItemFlg == true { continue }
				let newFaceItem: MCVision.Detection.Face.Item = MCVision.Detection.Face.Item.init(id: metadataFaceObject.faceID, observation: VNFaceObservation.init(boundingBox: trackingBoundes), landmarks: nil, renderSize: renderSize)
				print("new Face: \(metadataFaceObject.faceID)")
				//newFaceItem.landmarkDetection(pixelBuffer: &pixelBuffer, observation: VNDetectedObjectObservation.init(boundingBox: boundes))
				newFaceItem.tracking(pixelBuffer: &pixelBuffer)
				tempFaces.append(newFaceItem)
			}
			self.faces = tempFaces
			print("faces: \(faces)")
			
			var faceLandmarkPoints: [MCGeom.Vec3D] = []
			/*
			for face: MCVision.FaceDetection.FaceItem in self.faces {
				if let faceContour: VNFaceLandmarkRegion2D = face.landmarks?.faceContour {
					let points: [MCGeom.Vec3D] = faceContour.normalizedPoints.map {
						let a: CGPoint = CGPoint.init(face.boundingBox.origin.x + $0.x, face.boundingBox.origin.y + $0.y)
						//let a: CGPoint = CGPoint.init($0.x - 1.0, $0.y)
						return MCGeom.Vec3D.init(x: Float(a.x), y: Float(a.y), z: 0.0)
					}
					faceLandmarkPoints += points
				}

				if let leftEye: VNFaceLandmarkRegion2D = face.landmarks?.leftEye {
					let points: [MCGeom.Vec3D] = leftEye.normalizedPoints.map {
						let a: CGPoint = CGPoint.init(face.boundingBox.origin.x + $0.x, face.boundingBox.origin.y + $0.y)
						//return MCGeom.Vec3D.init(x: Float(a.x), y: Float(a.y), z: 0.0)
						return MCGeom.Vec3D.init(x: Float($0.x), y: Float($0.y), z: 0.0)
					}
					faceLandmarkPoints += points
				}
				if let rightEye: VNFaceLandmarkRegion2D = face.landmarks?.rightEye {
					let points: [MCGeom.Vec3D] = rightEye.normalizedPoints.map {
						let a: CGPoint = CGPoint.init(face.boundingBox.origin.x + $0.x, face.boundingBox.origin.y + $0.y)
						//return MCGeom.Vec3D.init(x: Float(a.x), y: Float(a.y), z: 0.0)
						return MCGeom.Vec3D.init(x: Float($0.x), y: Float($0.y), z: 0.0)
					}
					faceLandmarkPoints += points
				}

				
				/*
				faceLandmarkPoints += face.allPoints.map {
					let a: CGPoint = $0.normalized(size: renderSize) * 2.0
					let b: CGPoint = a * CGPoint(x: 1.0, y: -1.0) - CGPoint(x: 1.0, y: -1.0)
					return MCGeom.Vec3D.init(x: Float(b.x), y: Float(b.y), z: 0.0)
				}
*/
			}
			*/
			//print(faceLandmarkPoints.count)
			//////////////////////////////////////////////////////////
			let pointColor: MCColor = MCColor.init(hex: "0x00FF00")
			let pointColor002: MCColor = MCColor.init(hex: "0x0000FF")
			var objects: [MCPrimitiveTypeProtocol] = []
			/*
			if faceLandmarkPoints.count >= 1 {
				objects.append(try MCPrimitive.Points.init(positions: faceLandmarkPoints, color: pointColor002, size: 4.0))
			}
			*/
			objects.append(try MCPrimitive.Points.init(positions: faceBoundPoints + faceLandmarkPoints, color: pointColor, size: 10.0))
			print(objects.count)
			try self.canvas?.draw(commandBuffer: &commandBuffer, objects: objects)
			
			self.texture = outTexture
		}
	}
}
