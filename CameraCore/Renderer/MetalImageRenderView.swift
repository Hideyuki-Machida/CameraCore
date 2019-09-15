//
//  MetalImageRenderView.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/10/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Metal
import MetalKit
import MetalPerformanceShaders
import AVFoundation
import MetalCanvas

public class MetalImageRenderView: MTKView, MTKViewDelegate {

    fileprivate let queue: DispatchQueue = DispatchQueue(label: "CameraCore.MetalImageRenderView.queue")
	private let rect: CGRect = CGRect(origin: CGPoint(x: 0, y: 0), size: UIScreen.main.nativeBounds.size)
	public var drawRect: CGRect?
	public var trimRect: CGRect?
	public var pipeline: MTLComputePipelineState?
	public var pipeline0: MTLRenderPipelineState?
	public var textureCache: CVMetalTextureCache? = MCCore.createTextureCache()
	private let glTextureConvert: GLTextureConvert = GLTextureConvert.init(context: CameraCore.SharedContext.glContext.egleContext)
	
	private var _mathScale: CGSize = CGSize(width: 0, height: 0)
	
	private var filter: MPSImageLanczosScale!
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		self.delegate = self
		self.device = MCCore.device
		self.filter = MPSImageLanczosScale(device: self.device!)
		//self.ciContext = CIContext(mtlDevice: self.device!)
		//self.ciContext = CIContext(mtlDevice: RuntimeVars.device, options: SharedContext.options)
		//self.ciContext = CIContext(mtlDevice: self.device!, options: SharedContext.options)
		
		self.isPaused = true
		self.framebufferOnly = false
		self.enableSetNeedsDisplay = false
	}
	
	public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
	}
	
	public func draw(in view: MTKView) {
		//print(view.preferredFramesPerSecond)
		/*
		guard let image: CIImage = self.image else { return }
		guard let commandQueue: MTLCommandQueue = self.commandQueue else { return }
		let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()
		let bounds = CGRect( x: 0, y: 0, width: (self.bounds.size.width), height: (self.bounds.size.height) )
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		self.ciContext?.render(image, to: self.currentDrawable!.texture, commandBuffer: commandBuffer, bounds: image.extent, colorSpace: colorSpace)
		commandBuffer.present(self.currentDrawable!)
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
		*/
		
	}
	
	func setup() {
	}
	
	deinit {
		//Debug.VideoActionLog("deinit: ImageRenderView")
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
	}
	
    fileprivate var counter: CMTimeValue = 0
	public func updatePixelBuffer(pixelBuffer: CVPixelBuffer, renderLayers: [RenderLayerProtocol]?, renderSize: CGSize) {
		self.queue.async { [weak self] in
			autoreleasepool() { [weak self] in
				guard let self = self else { return }
				
				////////////////////////////////////////////////////////////
				//
				self.drawableSize = renderSize
				guard let drawable: CAMetalDrawable = self.currentDrawable else { return }
				guard var textureCache: CVMetalTextureCache = self.textureCache else { return }
				guard var commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
				var sourcePixelBuffer: CVPixelBuffer = pixelBuffer
				////////////////////////////////////////////////////////////
				
				guard var renderLayers: [RenderLayerProtocol] = renderLayers else { return }
				do {
					try self.prosessing(commandBuffer: &commandBuffer, sourcePixelBuffer: &sourcePixelBuffer, renderLayers: &renderLayers, renderSize: renderSize)
				} catch {
					
				}
				
				let texture: MTLTexture = MCCore.texture(pixelBuffer: &sourcePixelBuffer, textureCache: &textureCache, colorPixelFormat: self.colorPixelFormat)!
				////////////////////////////////////////////////////////////
				
				
				let blitEncoder: MTLBlitCommandEncoder? = commandBuffer.makeBlitCommandEncoder()
				blitEncoder?.copy(from: texture,
								  sourceSlice: 0,
								  sourceLevel: 0,
								  sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
								  sourceSize: MTLSizeMake(drawable.texture.width, drawable.texture.height, drawable.texture.depth),
								  to: drawable.texture,
								  destinationSlice: 0,
								  destinationLevel: 0,
								  destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
				blitEncoder?.endEncoding()
/*
				////////////////////////////////////////////////////////////
				// previewScale encode
				let scale: Double = Double(drawable.texture.width) / Double(texture.width)
				//let scale: Double = 1.5
				var transform: MPSScaleTransform = MPSScaleTransform(scaleX: scale, scaleY: scale, translateX: 0, translateY: 0)
				withUnsafePointer(to: &transform) { [weak self] (transformPtr: UnsafePointer<MPSScaleTransform>) -> () in
					self?.filter.scaleTransform = transformPtr
					self?.filter.encode(commandBuffer: commandBuffer, sourceTexture: texture, destinationTexture: drawable.texture)
				}
				////////////////////////////////////////////////////////////
*/
				////////////////////////////////////////////////////////////
				// commit
				/*
				commandBuffer.addCompletedHandler { [weak self] (cb) in
					/*
					///////////////////////////////////////////////////////////////////////////////////////////////////
					// Metal の ImageProcessing が完了したらGLの ImageProcessing 開始
					DispatchQueue.main.async { [weak self] in
						guard let self = self else { return }
						for (index, _) in renderLayers.enumerated() {
							if var renderLayer: OpenGLRenderLayerProtocol = renderLayers[index] as? OpenGLRenderLayerProtocol {
								do {
									try renderLayer.processing(pixelBuffer: &newPixelBuffer, compositionTime: compositionTime, timeRange: timeRange, percentComplete: percentComplete, renderSize: renderSize)
								} catch {
									Debug.ErrorLog(error)
								}
							}
						}
						
						for (index, _) in renderLayers.enumerated() {
							if var renderLayer: OpenGLRenderLayerProtocol = renderLayers[index] as? OpenGLRenderLayerProtocol {
								do {
									try renderLayer.processing(pixelBuffer: &newPixelBuffer, compositionTime: compositionTime, timeRange: timeRange, percentComplete: percentComplete, renderSize: renderSize)
								} catch {
									Debug.ErrorLog(error)
								}
							}
						}
						
						self.draw()
					}
					///////////////////////////////////////////////////////////////////////////////////////////////////
					*/
					//self?.draw()
				}
				*/
				commandBuffer.present(drawable)
				commandBuffer.commit()
				//commandBuffer.waitUntilCompleted()
				self.draw()
				////////////////////////////////////////////////////////////
			}
		}
	}
	
	private func prosessing(commandBuffer: inout MTLCommandBuffer, sourcePixelBuffer: inout CVPixelBuffer, renderLayers: inout [RenderLayerProtocol], renderSize: CGSize) throws {
		guard var textureCache: CVMetalTextureCache = self.textureCache else { return }
		guard var destinationPixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: renderSize) else { return }

		////////////////////////////////////////////////////////////
		// renderLayers encode
		let frameRate: Int32 = 30
		let compositionTime: CMTime = CMTime.init(value: self.counter, timescale: frameRate)
		let timeRange: CMTimeRange = CMTimeRange.init()
		let percentComplete: Double = 0
		var renderLayerCompositionInfo = RenderLayerCompositionInfo.init(
			compositionTime: compositionTime,
			timeRange: timeRange,
			percentComplete: percentComplete,
			renderSize: renderSize,
			//metadataObjects: [],
			//depthData: nil,
			queue: DispatchQueue.main
		)

		for renderLayer in renderLayers {
			//CVPixelBufferLockBaseAddress(sourcePixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
			//CVPixelBufferLockBaseAddress(destinationPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
			if var _: OpenGLRenderLayerProtocol = renderLayer as? OpenGLRenderLayerProtocol {
				//try renderLayer.processing(pixelBuffer: &sourcePixelBuffer, compositionTime: compositionTime, timeRange: timeRange, percentComplete: percentComplete, renderSize: renderSize)
			} else if var renderLayer: MetalRenderLayerProtocol = renderLayer as? MetalRenderLayerProtocol {
				let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &sourcePixelBuffer, textureCache: &textureCache, colorPixelFormat: self.colorPixelFormat)!
				var destinationTexture: MTLTexture = MCCore.texture(pixelBuffer: &destinationPixelBuffer, textureCache: &textureCache, colorPixelFormat: self.colorPixelFormat)!
				try renderLayer.processing(commandBuffer: &commandBuffer, source: sourceTexture, destination: &destinationTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
				
				let blitEncoder: MTLBlitCommandEncoder? = commandBuffer.makeBlitCommandEncoder()
				blitEncoder?.copy(from: destinationTexture,
								  sourceSlice: 0,
								  sourceLevel: 0,
								  sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
								  sourceSize: MTLSizeMake(destinationTexture.width, destinationTexture.height, destinationTexture.depth),
								  to: sourceTexture,
								  destinationSlice: 0,
								  destinationLevel: 0,
								  destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
				blitEncoder?.endEncoding()
			}
			//sourcePixelBuffer = destinationPixelBuffer.copy()
			//CVPixelBufferUnlockBaseAddress(destinationPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
			//CVPixelBufferUnlockBaseAddress(sourcePixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
		}
		self.counter += 1
	}
}
