//
//  ImageCapture.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/09.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas

public class ImageCapture {

	fileprivate static let queue: DispatchQueue = DispatchQueue(label: "CameraCore.ImageCapture")
	fileprivate static let textureCache: CVMetalTextureCache? = MCCore.createTextureCache()
	
	public enum ErrorType: Error {
		case processingError
	}

	
    public static func capture(url: URL, size: CGSize, at: CMTime) throws -> CGImage {
        let asset: AVURLAsset = AVURLAsset(url: url, options: nil)
        let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let capturedImage: CGImage = try generator.copyCGImage(at: at, actualTime: nil)
            return capturedImage
        } catch {
        }
		throw ErrorType.processingError
    }

	public static func capture(url: URL, size: CGSize, compositionAsset: CompositionVideoAssetProtocol, at: CMTime, complete: @escaping ((_ image: CGImage?)->Void)) throws {
		let cap: CGImage = try ImageCapture.capture(url: url, size: size, at: at)
		try ImageCapture.compositionImage(cap: cap, size: size, compositionAsset: compositionAsset, complete: complete)
        //return cgImage
    }

	public static func capture(size: CGSize, compositionData: CompositionDataProtocol, at: CMTime) throws -> CGImage {
		guard compositionData.isEmpty != true else { throw ErrorType.processingError }
        let generator: AVAssetImageGenerator = AVAssetImageGenerator.init(asset: compositionData.composition)
		generator.videoComposition = compositionData.videoComposition
		let capturedImage: CGImage = try generator.copyCGImage(at: at, actualTime: nil)
		return capturedImage
	}

	
    deinit {
        Debug.DeinitLog(self)
    }

	public static func compositionImage(cap: CGImage, size: CGSize, compositionAsset: CompositionVideoAssetProtocol, complete: @escaping ((_ image: CGImage?)->Void)) throws {
		guard var commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { throw ErrorType.processingError }
		//guard var textureCache: CVMetalTextureCache = self.textureCache else { throw ErrorType.processingError }
		guard var sourcePixelBuffer: CVPixelBuffer = CVPixelBuffer.create(image: cap) else { throw ErrorType.processingError }
		guard var newPixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: size) else { throw ErrorType.processingError }

		var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo.init(
			compositionTime: CMTime.zero,
			timeRange: CMTimeRange.init(),
			percentComplete: 0,
			renderSize: size,
			//metadataObjects: [],
			//depthData: nil,
			queue: ImageCapture.queue
		)

		var compositionAsset = compositionAsset
		try MetalImageProcessing.imageprocessing(
			commandBuffer: &commandBuffer,
			compositionVideoAsset: &compositionAsset,
			sourcePixelBuffer: &sourcePixelBuffer,
			newPixelBuffer: &newPixelBuffer,
			renderLayerCompositionInfo: &renderLayerCompositionInfo,
			complete: {
				
				commandBuffer.addCompletedHandler { (cb) in
					let ciImage: CIImage = CIImage.init(cvImageBuffer: newPixelBuffer)
					let result: CIFilter = CIFilter(name: Blendmode.alpha.CIFilterName())!
					let backgroundColor: UIColor = compositionAsset.backgroundColor
					result.setValue(CIImage(color: CIColor(cgColor: backgroundColor.cgColor)), forKey: kCIInputBackgroundImageKey)
					result.setValue(ciImage, forKey: kCIInputImageKey)
        			let cgImage: CGImage? = SharedContext.ciContext.createCGImage(result.outputImage!, from: ciImage.extent)
					complete(cgImage)
				}
				commandBuffer.commit()
				//commandBuffer.waitUntilCompleted()
		})
    }
}
