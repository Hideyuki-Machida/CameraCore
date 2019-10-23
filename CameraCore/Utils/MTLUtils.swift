//
//  MTLUtils.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/10/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import Metal

public class MTLUtils {
	static var device: MTLDevice = MTLCreateSystemDefaultDevice()!
	static var commandQueue: MTLCommandQueue = MTLUtils.device.makeCommandQueue()!
	static var currentCompositionItemId: String?
	static var ciContext = CIContext(mtlDevice: MTLUtils.device, options: SharedContext.options)
	
	static let threadsPerThreadgroup: MTLSize = MTLSize(width: 16, height: 16, depth: 1)
	
	static func createTextureCache() -> CVMetalTextureCache? {
		var textureCache: CVMetalTextureCache?
		CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MTLUtils.device, nil, &textureCache)
		return textureCache
	}
	
	static func CMSampleBufferGetMTLTexture(sampleBuffer: CMSampleBuffer, textureCache: inout CVMetalTextureCache, colorPixelFormat: MTLPixelFormat) -> MTLTexture? {
		guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
		return CVPixelBufferGetMTLTexture(pixelBuffer: pixelBuffer, textureCache: &textureCache, colorPixelFormat: colorPixelFormat)
	}
	
	static func CVPixelBufferGetMTLTexture(pixelBuffer: CVPixelBuffer, textureCache: inout CVMetalTextureCache, colorPixelFormat: MTLPixelFormat) -> MTLTexture? {
		
		let width: Int = CVPixelBufferGetWidth(pixelBuffer)
		let height: Int = CVPixelBufferGetHeight(pixelBuffer)
		var imageTexture: CVMetalTexture?
		let result: CVReturn = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, colorPixelFormat, width, height, 0, &imageTexture)
		guard result == kCVReturnSuccess else { return nil }
		guard let imgTexture: CVMetalTexture = imageTexture else { return nil }
		if let texture: MTLTexture = CVMetalTextureGetTexture(imgTexture) {
			return texture
		} else {
			return nil
		}
	}
}
