//
//  VideoRenderLayerCompositing.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/15.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import CoreImage
import AVFoundation

/*
class VideoRenderLayerCompositing: NSObject, AVVideoCompositing {
	private let queue: DispatchQueue = DispatchQueue(label: "com.cchannel.CameraCore.VideoRenderLayerCompositing.queue")
	private var isCancelAllRequests: Bool = false
	private var context: AVVideoCompositionRenderContext?
	private let ciContext: CIContext = SharedContext.ciContext
	//private let rect: CGRect = CGRect(origin: CGPoint.zero, size: CGSize.init(width: 1080, height: 1920))
	private let rect: CGRect = CGRect(origin: CGPoint.zero, size: CGSize.init(width: 720, height: 1280))
	
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
			if self?.isCancelAllRequests == true {
				asyncVideoCompositionRequest.finishCancelledRequest()
				return
			}
			
			if let filterInstruction: CustomVideoCompositionInstruction = asyncVideoCompositionRequest.videoCompositionInstruction as? CustomVideoCompositionInstruction {
				self?.set(filterInstruction: filterInstruction, asyncVideoCompositionRequest: asyncVideoCompositionRequest)
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
	
	private func set(filterInstruction: CustomVideoCompositionInstruction, asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
		guard let sourceTrackId: CMPersistentTrackID = filterInstruction.overrideRequiredSourceTrackIDs?.first as? Int32,
			var pixelBuffer: CVPixelBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: sourceTrackId),
			let newPixelBuffer: CVPixelBuffer = asyncVideoCompositionRequest.renderContext.newPixelBuffer()
			else {
				asyncVideoCompositionRequest.finishCancelledRequest()
				return
		}
		
		autoreleasepool() { [weak self] in
			guard let `self` = self else { return }
            if let _ = filterInstruction.compositionVideoAsset {
				let size: CGSize = asyncVideoCompositionRequest.renderContext.size
				let compositionTime: CMTime = asyncVideoCompositionRequest.compositionTime
				
				let startSeconds: Double = filterInstruction.overrideTimeRange.start.seconds
				let durationSeconds: Double = filterInstruction.overrideTimeRange.duration.seconds
				let compositionSeconds: Double = compositionTime.seconds
				let percentComplete: Double = (compositionSeconds - startSeconds) / durationSeconds
				
				let image: CIImage = self.imageprocessing(compositionVideoAsset: &filterInstruction.compositionVideoAsset!, pixelBuffer: &pixelBuffer, renderSize: size, compositionTime: compositionTime, timeRange: filterInstruction.overrideTimeRange, percentComplete: percentComplete, compositionVideoTrack: &filterInstruction.compositionVideoTrack!)
				self.ciContext.render(image, to: newPixelBuffer, bounds: CGRect(origin: CGPoint.zero, size: size), colorSpace: image.colorSpace)
                asyncVideoCompositionRequest.finish(withComposedVideoFrame: newPixelBuffer)
            } else {
                asyncVideoCompositionRequest.finish(withComposedVideoFrame: pixelBuffer)
            }
		}
	}
	
	private func imageprocessing(compositionVideoAsset: inout CompositionVideoAssetProtocol, pixelBuffer: inout CVPixelBuffer, renderSize: CGSize, compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Double, compositionVideoTrack: inout CompositionVideoTrackProtocol) -> CIImage {
		var image: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
		
		///////////////////////////////////////////////////////////////////////////////////////////////////
		// まずcontentModeの設定を反映
		let userTransform: CGAffineTransform = TransformUtils.convertTransformSKToCI(
			userTransform: compositionVideoAsset.transform,
			videoSize: compositionVideoAsset.videoAssetTrack!.naturalSize,
			renderSize: renderSize,
			preferredTransform: compositionVideoAsset.videoAssetTrack!.preferredTransform
		)
		let transform: CGAffineTransform = compositionVideoAsset.contentModeTransform.concatenating(userTransform)
		
		let transformLayer001: TransformLayer = TransformLayer.init(transform: transform, backgroundColor: compositionVideoAsset.backgroundColor)
		image = transformLayer001.processing(image: image, compositionTime: compositionTime, timeRange: timeRange, percentComplete: Float(percentComplete), renderSize: renderSize)!
		///////////////////////////////////////////////////////////////////////////////////////////////////

		/*
		for (index, _) in compositionVideoAsset.layers.enumerated() {
			if var layer: CIImageRenderLayerProtocol = compositionVideoAsset.layers[index] as? CIImageRenderLayerProtocol {
				//layer.processing(image: <#T##CIImage#>, renderLayerCompositionInfo: &<#T##RenderLayerCompositionInfo#>)
				//image = layer.processing(image: image, compositionTime: compositionTime, timeRange: timeRange, percentComplete: Float(percentComplete), renderSize: renderSize)!
			}
		}
		
		for (index, _) in compositionVideoTrack.layers.enumerated() {
			if var layer: CIImageRenderLayerProtocol = compositionVideoTrack.layers[index] as? CIImageRenderLayerProtocol {
				//image = layer.processing(image: image, compositionTime: compositionTime, timeRange: timeRange, percentComplete: Float(percentComplete), renderSize: renderSize)!
			}
		}
		*/
		return image
	}
	
}
*/
