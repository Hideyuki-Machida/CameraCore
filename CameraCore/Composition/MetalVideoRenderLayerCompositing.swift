//
//  MetalVideoRenderLayerCompositing.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/10/21.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import CoreImage
import AVFoundation
import MetalPerformanceShaders
import MetalCanvas

class MetalVideoRenderLayerCompositing: NSObject, AVVideoCompositing {
	private let queue: DispatchQueue = DispatchQueue(label: "CameraCore.MetalVideoRenderLayerCompositing.queue", attributes: .concurrent)
	private var isCancelAllRequests: Bool = false
	private var context: AVVideoCompositionRenderContext?
	private var textureCache: CVMetalTextureCache? = MCCore.createTextureCache()

	
	enum ErrorType: Error {
		case render
	}
	
	deinit {
		Debug.DeinitLog(self)
	}
	
	var sourcePixelBufferAttributes: [String : Any]? {
		return [
			kCVPixelBufferPixelFormatTypeKey as String : Configuration.sourcePixelBufferPixelFormatTypeKey,
			kCVPixelFormatOpenGLESCompatibility as String : true,
		]
	}
	
	var requiredPixelBufferAttributesForRenderContext: [String : Any] {
		return [
			kCVPixelBufferPixelFormatTypeKey as String : Configuration.sourcePixelBufferPixelFormatTypeKey,
			kCVPixelFormatOpenGLESCompatibility as String : true,
		]
	}
	
	func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
		self.queue.async { [weak self] in
			self?.context = newRenderContext
		}
	}
	
	func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
		self.queue.async { [weak self] in
			guard let self = self else { return }
			if self.isCancelAllRequests == true {
				asyncVideoCompositionRequest.finishCancelledRequest()
				return
			}
			
			if let filterInstruction: CustomVideoCompositionInstruction = asyncVideoCompositionRequest.videoCompositionInstruction as? CustomVideoCompositionInstruction {
				do {
					try self.set(filterInstruction: filterInstruction, asyncVideoCompositionRequest: asyncVideoCompositionRequest, queue: self.queue)
				} catch {
					asyncVideoCompositionRequest.finishCancelledRequest()
				}
			} else {
				asyncVideoCompositionRequest.finishCancelledRequest()
			}
		}
	}
	
	func cancelAllPendingVideoCompositionRequests() {
		self.isCancelAllRequests = true
		self.queue.async { [weak self] in
			self?.isCancelAllRequests = false
		}
	}
	
	private func set(filterInstruction: CustomVideoCompositionInstruction, asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest, queue: DispatchQueue) throws {

		///////////////////////////////////////////////////////////////////////////////////////////////////
		// setting
		guard let sourceTrackId: CMPersistentTrackID = filterInstruction.overrideRequiredSourceTrackIDs?.first as? Int32,
			var sourcePixelBuffer: CVPixelBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: sourceTrackId),
			var newPixelBuffer: CVPixelBuffer = asyncVideoCompositionRequest.renderContext.newPixelBuffer()
			else { throw ErrorType.render }
		
		guard let _ = filterInstruction.compositionVideoAsset else { throw ErrorType.render }
		let renderSize: CGSize = asyncVideoCompositionRequest.renderContext.size
		let compositionTime: CMTime = asyncVideoCompositionRequest.compositionTime
		
		let startSeconds: Double = filterInstruction.overrideTimeRange.start.seconds
		let durationSeconds: Double = filterInstruction.overrideTimeRange.duration.seconds
		let compositionSeconds: Double = compositionTime.seconds
		let percentComplete: Double = (compositionSeconds - startSeconds) / durationSeconds
		let timeRange: CMTimeRange = filterInstruction.overrideTimeRange
		guard var commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { throw ErrorType.render }
		///////////////////////////////////////////////////////////////////////////////////////////////////

		///////////////////////////////////////////////////////////////////////////////////////////////////
		// renderLayerCompositionInfo
		var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo.init(
			compositionTime: compositionTime,
			timeRange: timeRange,
			percentComplete: percentComplete,
			renderSize: renderSize,
			//metadataObjects: [],
			//depthData: nil,
			queue: queue
		)
		///////////////////////////////////////////////////////////////////////////////////////////////////
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// Metal addCompletedHandler
		commandBuffer.addCompletedHandler { (cb) in
			//print("@ render complete")
			asyncVideoCompositionRequest.finish(withComposedVideoFrame: newPixelBuffer)
			/*
			DispatchQueue.main.async {
			print("@ render complete2")
				for (index, _) in filterInstruction.compositionVideoAsset!.layers.enumerated() {
					if var renderLayer: OpenGLRenderLayerProtocol = filterInstruction.compositionVideoAsset!.layers[index] as? OpenGLRenderLayerProtocol {
						do {
							try renderLayer.processing(pixelBuffer: &newPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
						} catch {
							Debug.ErrorLog(error)
						}
					}
				}
				
				for (index, _) in filterInstruction.compositionVideoTrack!.layers.enumerated() {
					if var renderLayer: OpenGLRenderLayerProtocol = filterInstruction.compositionVideoAsset!.layers[index] as? OpenGLRenderLayerProtocol {
						do {
							try renderLayer.processing(pixelBuffer: &newPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
						} catch {
							Debug.ErrorLog(error)
						}
					}
				}
				asyncVideoCompositionRequest.finish(withComposedVideoFrame: newPixelBuffer)
			}
			*/
		}
		//commandBuffer.waitUntilCompleted()
		///////////////////////////////////////////////////////////////////////////////////////////////////

		///////////////////////////////////////////////////////////////////////////////////////////////////
		// Metal で ImageProcessing
		try MetalImageProcessing.imageprocessing(
			commandBuffer: &commandBuffer,
			compositionVideoAsset: &filterInstruction.compositionVideoAsset!,
			sourcePixelBuffer: &sourcePixelBuffer,
			newPixelBuffer: &newPixelBuffer,
			renderLayerCompositionInfo: &renderLayerCompositionInfo,
			compositionVideoTrack: &filterInstruction.compositionVideoTrack!,
			complete: {
				commandBuffer.commit()
		})
		///////////////////////////////////////////////////////////////////////////////////////////////////
	}
}


extension MetalVideoRenderLayerCompositing {
	/// contentModeの設定を反映
	private func addContentModeTransform(compositionVideoAsset: inout CompositionVideoAssetProtocol, sourcePixelBuffer: inout CVPixelBuffer, newPixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol, complete: @escaping (()->Void)) throws {

		//let start: TimeInterval = Date().timeIntervalSince1970
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.render }
		guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { throw ErrorType.render }
		guard let videoAssetTrack: AVAssetTrack = compositionVideoAsset.videoAssetTrack else { throw ErrorType.render }
		
		let image: CIImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
		let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		
		let userTransform: CGAffineTransform = TransformUtils.convertTransformSKToCI(
			userTransform: compositionVideoAsset.transform,
			videoSize: videoAssetTrack.naturalSize,
			renderSize: renderLayerCompositionInfo.renderSize,
			preferredTransform: videoAssetTrack.preferredTransform
		)
		
		let transform: CGAffineTransform = compositionVideoAsset.contentModeTransform.concatenating(userTransform)
		let transformLayer001: TransformLayer = TransformLayer.init(transform: transform,
																	backgroundColor: compositionVideoAsset.backgroundColor
		)
		guard var transformImage: CIImage = transformLayer001.processing(image: image,
																		 compositionTime: renderLayerCompositionInfo.compositionTime,
																		 timeRange: renderLayerCompositionInfo.timeRange,
																		 percentComplete: Float(renderLayerCompositionInfo.percentComplete),
																		 renderSize: renderLayerCompositionInfo.renderSize
		) else { throw ErrorType.render }
		
		let transformTexture: MTLTexture = MCCore.texture(pixelBuffer: &newPixelBuffer,
														  textureCache: &textureCache,
														  colorPixelFormat: MTLPixelFormat.bgra8Unorm
		)!

		transformImage = transformImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: CGFloat(transformTexture.height)))

		MCCore.ciContext.render(transformImage,
								to: transformTexture,
								commandBuffer: commandBuffer,
								bounds: transformImage.extent,
								colorSpace: colorSpace
		)
		commandBuffer.addCompletedHandler { (cb) in
			/*
			let end: TimeInterval = Date().timeIntervalSince1970 - start
			print("@ render time: \(end)")
			*/
			complete()
		}
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
	}
	
	/*
	///
	private func processingMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol) throws {
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.render }
		guard var sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
		
		guard var destinationTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat) else { throw ErrorType.render }
		try renderLayer.processing(commandBuffer: &commandBuffer, sourceTexture: sourceTexture, destinationTexture: &destinationTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
	}
*/
/*
	///
	private func processingMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol) throws {
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.render }
		guard var sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
		
		guard var newBuffer: CVPixelBuffer = CVPixelBuffer.create(size: renderLayerCompositionInfo.renderSize) else { throw ErrorType.render }
		guard var destinationTexture: MTLTexture = MCCore.texture(pixelBuffer: &newBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }

		//guard var destinationTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat) else { throw ErrorType.render }
		try renderLayer.processing(commandBuffer: &commandBuffer, sourceTexture: sourceTexture, destinationTexture: &destinationTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
		
		let blitEncoder02: MTLBlitCommandEncoder? = commandBuffer.makeBlitCommandEncoder()
		blitEncoder02?.copy(from: destinationTexture,
							sourceSlice: 0,
							sourceLevel: 0,
							sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
							sourceSize: MTLSizeMake(sourceTexture.width, sourceTexture.height, sourceTexture.depth),
							to: sourceTexture,
							destinationSlice: 0,
							destinationLevel: 0,
							destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
		blitEncoder02?.endEncoding()
	}
*/
	
	///
	private func processingMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol) throws {
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.render }
		guard let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
		
		/*
		guard var newBuffer: CVPixelBuffer = CVPixelBuffer.create(size: renderLayerCompositionInfo.renderSize) else { throw ErrorType.render }
		guard var destinationTexture: MTLTexture = MCCore.texture(pixelBuffer: &newBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
*/
		guard var newSourceBuffer: CVPixelBuffer = CVPixelBuffer.create(size: renderLayerCompositionInfo.renderSize) else { throw ErrorType.render }
		guard let newSourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &newSourceBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }

		guard let commandBuffer0: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { throw ErrorType.render }
		let blitEncoder0: MTLBlitCommandEncoder? = commandBuffer0.makeBlitCommandEncoder()
		blitEncoder0?.copy(from: sourceTexture,
						  sourceSlice: 0,
						  sourceLevel: 0,
						  sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
						  sourceSize: MTLSizeMake(newSourceTexture.width, newSourceTexture.height, newSourceTexture.depth),
						  to: newSourceTexture,
						  destinationSlice: 0,
						  destinationLevel: 0,
						  destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
		blitEncoder0?.endEncoding()
		commandBuffer0.commit()
		
		guard var destinationTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat) else { throw ErrorType.render }
		try renderLayer.processing(commandBuffer: &commandBuffer,
								   sourceTexture: newSourceTexture,
								   destinationTexture: &destinationTexture,
								   renderLayerCompositionInfo: &renderLayerCompositionInfo
		)
		
		/*
		let blitEncoder: MTLBlitCommandEncoder? = commandBuffer.makeBlitCommandEncoder()
		blitEncoder?.copy(from: destinationTexture,
							sourceSlice: 0,
							sourceLevel: 0,
							sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
							sourceSize: MTLSizeMake(sourceTexture.width, sourceTexture.height, sourceTexture.depth),
							to: sourceTexture,
							destinationSlice: 0,
							destinationLevel: 0,
							destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
		blitEncoder?.endEncoding()
		*/
	}
	
	private func processingCIImageRenderLayer(renderLayer: inout CIImageRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol, complete: @escaping (()->Void)) throws {
		
		/*
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.render }
		guard let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
		
		/*
		guard var newBuffer: CVPixelBuffer = CVPixelBuffer.create(size: renderLayerCompositionInfo.renderSize) else { throw ErrorType.render }
		guard var destinationTexture: MTLTexture = MCCore.texture(pixelBuffer: &newBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
		*/
		guard var newSourceBuffer: CVPixelBuffer = CVPixelBuffer.create(size: renderLayerCompositionInfo.renderSize) else { throw ErrorType.render }
		guard let newSourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &newSourceBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
		
		guard let commandBuffer0: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { throw ErrorType.render }
		let blitEncoder0: MTLBlitCommandEncoder? = commandBuffer0.makeBlitCommandEncoder()
		blitEncoder0?.copy(from: sourceTexture,
						   sourceSlice: 0,
						   sourceLevel: 0,
						   sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
						   sourceSize: MTLSizeMake(newSourceTexture.width, newSourceTexture.height, newSourceTexture.depth),
						   to: newSourceTexture,
						   destinationSlice: 0,
						   destinationLevel: 0,
						   destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
		blitEncoder0?.endEncoding()
		commandBuffer0.commit()

		let image: CIImage = CIImage(cvPixelBuffer: newSourceBuffer)
		let resultImage: CIImage = try renderLayer.processing(image: image,
															  renderLayerCompositionInfo: &renderLayerCompositionInfo
		)
		
		let destinationTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer,
															textureCache: &textureCache,
															colorPixelFormat: MTLPixelFormat.bgra8Unorm
		)!
		/*
		let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
		MCCore.ciContext.render(resultImage,
								to: destinationTexture,
								commandBuffer: commandBuffer,
								bounds: resultImage.extent,
								colorSpace: colorSpace
		)
		*/
		commandBuffer.addCompletedHandler { (cb) in
			complete()
		}
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
		*/
	}

}
