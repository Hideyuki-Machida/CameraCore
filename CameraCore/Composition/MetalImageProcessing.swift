//
//  MetalImageProcessing.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/03/07.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import CoreImage
import AVFoundation
import MetalPerformanceShaders
import MetalCanvas

class MetalImageProcessing {
	private static var textureCache: CVMetalTextureCache? = MCCore.createTextureCache()

	enum ErrorType: Error {
		case render
	}
	
	deinit {
		Debug.DeinitLog(self)
	}

	

	static func imageprocessing(commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, sourcePixelBuffer: inout CVPixelBuffer, newPixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol, complete: @escaping (()->Void)) throws {
		var compositionVideoAsset = compositionVideoAsset
		var compositionVideoTrack = compositionVideoTrack
		var commandBuffer = commandBuffer
		var sourcePixelBuffer = sourcePixelBuffer
		var newPixelBuffer = newPixelBuffer
		var renderLayerCompositionInfo = renderLayerCompositionInfo
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// まずcontentModeの設定を反映
		try self.addContentModeTransform(compositionVideoAsset: &compositionVideoAsset,
										 sourcePixelBuffer: &sourcePixelBuffer,
										 newPixelBuffer: &newPixelBuffer,
										 renderLayerCompositionInfo: &renderLayerCompositionInfo,
										 compositionVideoTrack: &compositionVideoTrack,
										 complete: {
											///////////////////////////////////////////////////////////////////////////////////////////////////
											
											///////////////////////////////////////////////////////////////////////////////////////////////////
											//
											for (index, _) in compositionVideoAsset.layers.enumerated() {
												if var renderLayer: MetalRenderLayerProtocol = compositionVideoAsset.layers[index] as? MetalRenderLayerProtocol {
													// MetalRenderLayerの場合の処理
													do {
														try self.processingMetalRenderLayer(renderLayer: &renderLayer,
																							 commandBuffer: &commandBuffer,
																							 compositionVideoAsset: &compositionVideoAsset,
																							 pixelBuffer: &newPixelBuffer,
																							 renderLayerCompositionInfo: &renderLayerCompositionInfo,
																							 compositionVideoTrack: &compositionVideoTrack
														)
													} catch {
														Debug.ErrorLog(error)
													}
												} else if var renderLayer: CVPixelBufferRenderLayerProtocol = compositionVideoAsset.layers[index] as? CVPixelBufferRenderLayerProtocol {
													// CVPixelBufferのRenderLayerの場合の処理
													do {
														try renderLayer.processing(commandBuffer: &commandBuffer,
																				   pixelBuffer: &newPixelBuffer,
																				   renderLayerCompositionInfo: &renderLayerCompositionInfo
														)
													} catch {
														Debug.ErrorLog(error)
													}
												}
											}
											///////////////////////////////////////////////////////////////////////////////////////////////////
											
											///////////////////////////////////////////////////////////////////////////////////////////////////
											//
											for (index, _) in compositionVideoTrack.layers.enumerated() {
												if var renderLayer: MetalRenderLayerProtocol = compositionVideoTrack.layers[index] as? MetalRenderLayerProtocol {
													// MetalRenderLayerの場合の処理
													do {
														try self.processingMetalRenderLayer(renderLayer: &renderLayer,
																							commandBuffer: &commandBuffer,
																							compositionVideoAsset: &compositionVideoAsset,
																							pixelBuffer: &newPixelBuffer,
																							renderLayerCompositionInfo: &renderLayerCompositionInfo,
																							compositionVideoTrack: &compositionVideoTrack
														)
													} catch {
														Debug.ErrorLog(error)
													}
												} else if var renderLayer: CVPixelBufferRenderLayerProtocol = compositionVideoTrack.layers[index] as? CVPixelBufferRenderLayerProtocol {
													// CVPixelBufferのRenderLayerの場合の処理
													do {
														try renderLayer.processing(commandBuffer: &commandBuffer,
																				   pixelBuffer: &newPixelBuffer,
																				   renderLayerCompositionInfo: &renderLayerCompositionInfo
														)
													} catch {
														Debug.ErrorLog(error)
													}
												}
											}
											///////////////////////////////////////////////////////////////////////////////////////////////////
											
											complete()
		})
	}
	
	
	/// contentModeの設定を反映
	private static func addContentModeTransform(compositionVideoAsset: inout CompositionVideoAssetProtocol, sourcePixelBuffer: inout CVPixelBuffer, newPixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol, complete: @escaping (()->Void)) throws {
		
		//let start: TimeInterval = Date().timeIntervalSince1970
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.render }
		guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { throw ErrorType.render }
		guard let videoAssetTrack: AVAssetTrack = compositionVideoAsset.videoAssetTrack else { throw ErrorType.render }
		
		let sourceImage: CIImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
		let colorSpace: CGColorSpace = sourceImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()

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

		guard var transformImage: CIImage = transformLayer001.processing(image: sourceImage,
																		 compositionTime: renderLayerCompositionInfo.compositionTime,
																		 timeRange: renderLayerCompositionInfo.timeRange,
																		 percentComplete: Float(renderLayerCompositionInfo.percentComplete),
																		 renderSize: renderLayerCompositionInfo.renderSize
		) else { throw ErrorType.render }

		let transformTexture: MTLTexture = MCCore.texture(pixelBuffer: &newPixelBuffer,
														  textureCache: &textureCache,
														  colorPixelFormat: MTLPixelFormat.bgra8Unorm
		)!
		
		
		transformImage = transformImage
			.transformed(by: CGAffineTransform(scaleX: 1, y: -1)
			.translatedBy(x: 0, y: CGFloat(transformTexture.height)))
			//.cropped(to: CGRect.init(origin: CGPoint.init(), size: renderLayerCompositionInfo.renderSize))
		
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
	
	///
	private static func processingMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol) throws {
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.render }
		guard let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
		
		guard let newSourceTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat) else { throw ErrorType.render }
		
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
	}
	
	private static func processingCIImageRenderLayer(renderLayer: inout CIImageRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, compositionVideoTrack: inout CompositionVideoTrackProtocol, complete: @escaping (()->Void)) throws {
		
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

extension MetalImageProcessing {
	static func imageprocessing(commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, sourcePixelBuffer: inout CVPixelBuffer, newPixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, complete: @escaping (()->Void)) throws {
		var compositionVideoAsset = compositionVideoAsset
		var commandBuffer = commandBuffer
		var sourcePixelBuffer = sourcePixelBuffer
		var newPixelBuffer = newPixelBuffer
		var renderLayerCompositionInfo = renderLayerCompositionInfo
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// まずcontentModeの設定を反映
		try self.addContentModeTransform(compositionVideoAsset: &compositionVideoAsset,
										 sourcePixelBuffer: &sourcePixelBuffer,
										 newPixelBuffer: &newPixelBuffer,
										 renderLayerCompositionInfo: &renderLayerCompositionInfo,
										 complete: {
											///////////////////////////////////////////////////////////////////////////////////////////////////
											
											for (index, _) in compositionVideoAsset.layers.enumerated() {
												if var renderLayer: MetalRenderLayerProtocol = compositionVideoAsset.layers[index] as? MetalRenderLayerProtocol {
													// MetalRenderLayerの場合の処理
													do {
														try self.processingMetalRenderLayer(renderLayer: &renderLayer,
																							commandBuffer: &commandBuffer,
																							compositionVideoAsset: &compositionVideoAsset,
																							pixelBuffer: &newPixelBuffer,
																							renderLayerCompositionInfo: &renderLayerCompositionInfo
														)
													} catch {
														Debug.ErrorLog(error)
													}
												} else if var renderLayer: CVPixelBufferRenderLayerProtocol = compositionVideoAsset.layers[index] as? CVPixelBufferRenderLayerProtocol {
													// CVPixelBufferのRenderLayerの場合の処理
													do {
														try renderLayer.processing(commandBuffer: &commandBuffer,
																				   pixelBuffer: &newPixelBuffer,
																				   renderLayerCompositionInfo: &renderLayerCompositionInfo
														)
													} catch {
														Debug.ErrorLog(error)
													}
												} else if var renderLayer: CIImageRenderLayerProtocol = compositionVideoAsset.layers[index] as? CIImageRenderLayerProtocol {
													// CIImageのRenderLayerの場合の処理
													do {
														try self.processingCIImageRenderLayer(renderLayer: &renderLayer,
																							  commandBuffer: &commandBuffer,
																							  compositionVideoAsset: &compositionVideoAsset,
																							  pixelBuffer: &newPixelBuffer,
																							  renderLayerCompositionInfo: &renderLayerCompositionInfo,
																							  complete: complete
														)
													} catch {
														Debug.ErrorLog(error)
													}
												}
											}
											
											/*
											for (index, _) in compositionVideoTrack.layers.enumerated() {
											if var renderLayer: MetalRenderLayerProtocol = compositionVideoTrack.layers[index] as? MetalRenderLayerProtocol {
											do {
											try self?.processingMetalRenderLayer(renderLayer: &renderLayer, commandBuffer: &commandBuffer, compositionVideoAsset: &compositionVideoAsset, pixelBuffer: &newPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo, compositionVideoTrack: &compositionVideoTrack)
											} catch {
											Debug.ErrorLog(error)
											}
											} else if var renderLayer: CVPixelBufferRenderLayerProtocol = compositionVideoTrack.layers[index] as? CVPixelBufferRenderLayerProtocol {
											do {
											try renderLayer.processing(commandBuffer: &commandBuffer, pixelBuffer: &newPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
											} catch {
											Debug.ErrorLog(error)
											}
											}
											}
											*/
											
											complete()
		})
	}
	
	/// contentModeの設定を反映
	private static func addContentModeTransform(compositionVideoAsset: inout CompositionVideoAssetProtocol, sourcePixelBuffer: inout CVPixelBuffer, newPixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, complete: @escaping (()->Void)) throws {
		
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
	
	private static func processingMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.render }
		guard let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw ErrorType.render }
		
		guard let newSourceTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat) else { throw ErrorType.render }
		
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
	}
	
	private static func processingCIImageRenderLayer(renderLayer: inout CIImageRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo, complete: @escaping (()->Void)) throws {
	}
}
