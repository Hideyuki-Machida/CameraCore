//
//  CaptureDeviceFormat.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/01/10.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

extension CCRenderer.VideoCapture {
	final class DeviceFormat {
		var onUpdate: ((_ deviceFormat: AVCaptureDevice.Format?)->Void)?
		
		func get(videoDevice: AVCaptureDevice, paramator: CCRenderer.VideoCapture.VideoCaputureParamator) -> (deviceFormat: AVCaptureDevice.Format?, depthDataFormat: AVCaptureDevice.Format?, filterColorSpace: AVCaptureColorSpace?, minFrameRate: Int32, maxFrameRate: Int32) {
			let width: CGFloat = paramator.presetiFrame.size().height
			let height: CGFloat = paramator.presetiFrame.size().width

			var deviceFormat: AVCaptureDevice.Format?
			var minFrameRate: Int32 = 0
			var maxFrameRate: Int32 = 0
			// フレームレート
			for format: AVCaptureDevice.Format in videoDevice.formats {
				guard format.mediaType == .video else { continue }
				let maxWidth: Int32 = CMVideoFormatDescriptionGetDimensions(format.formatDescription).width
				let maxHeight: Int32 = CMVideoFormatDescriptionGetDimensions(format.formatDescription).height
				guard 640 <= CGFloat(maxWidth) else { continue }
				//guard format.isVideoHDRSupported == true else { continue }

				//let rateRanges: [AVFrameRateRange] = format.videoSupportedFrameRateRanges
				let colorSpaces: [AVCaptureColorSpace] = format.supportedColorSpaces
				//let frameRateRanges: [AVFrameRateRange] = rateRanges.filter { $0.minFrameRate <= Float64(frameRate) && Float64(frameRate) <= $0.maxFrameRate }
				let filterColorSpaces: [AVCaptureColorSpace] = colorSpaces.filter { $0 == AVCaptureColorSpace.P3_D65 }
				if #available(iOS 11.0, *) {
					let depthFormats: [AVCaptureDevice.Format] = format.supportedDepthDataFormats
					let depth32formats: [AVCaptureDevice.Format] = depthFormats.filter { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat32 }
					
					for videoSupportedFrameRateRange: Any in format.videoSupportedFrameRateRanges {
						guard let range: AVFrameRateRange = videoSupportedFrameRateRange as? AVFrameRateRange else { continue }
						if range.minFrameRate <= Float64(paramator.frameRate) &&
							Float64(paramator.frameRate) <= range.maxFrameRate &&
							depth32formats.count >= 1 &&
							filterColorSpaces.count >= 1 &&
							width == CGFloat(maxWidth) &&
							height == CGFloat(maxHeight)
						{
							guard Float64(paramator.frameRate) <= range.maxFrameRate else { continue }
							deviceFormat = format
							minFrameRate = Int32(range.minFrameRate)
							maxFrameRate = Int32(range.maxFrameRate)
							
							// 解像度が最大のものを選ぶ
							let selectedDepthFormat: AVCaptureDevice.Format? = depth32formats.max(by: { first, second in
								CMVideoFormatDescriptionGetDimensions(first.formatDescription).width
									< CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
							})!
							
							return (deviceFormat: deviceFormat, depthDataFormat: selectedDepthFormat, filterColorSpace: filterColorSpaces.first, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
						} else if range.minFrameRate <= Float64(paramator.frameRate) &&
							Float64(paramator.frameRate) >= range.maxFrameRate &&
							depth32formats.count >= 1 &&
							//filterColorSpaces.count >= 1 &&
							width == CGFloat(maxWidth) &&
							height == CGFloat(maxHeight)
						{
							guard Float64(paramator.frameRate) <= range.maxFrameRate else { continue }
							
							//print(item.supportedDepthDataFormats)
							
							deviceFormat = format
							minFrameRate = Int32(range.minFrameRate)
							maxFrameRate = Int32(range.maxFrameRate)
							
							// 解像度が最大のものを選ぶ
							let selectedDepthFormat: AVCaptureDevice.Format? = depth32formats.max(by: { first, second in
								CMVideoFormatDescriptionGetDimensions(first.formatDescription).width
									< CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
							})!
							
							return (deviceFormat: deviceFormat, depthDataFormat: selectedDepthFormat, filterColorSpace: filterColorSpaces.first, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
						}
						else if range.minFrameRate <= Float64(paramator.frameRate) && Float64(paramator.frameRate) <= range.maxFrameRate {
							guard Float64(paramator.frameRate) <= range.maxFrameRate else { continue }
							guard width >= CGFloat(maxWidth) else { continue }
							guard height >= CGFloat(maxHeight) else { continue }
							
							deviceFormat = format
							minFrameRate = Int32(range.minFrameRate)
							maxFrameRate = Int32(range.maxFrameRate)
						}
					}
				} else {
					// Fallback on earlier versions
					
					for videoSupportedFrameRateRange: Any in format.videoSupportedFrameRateRanges {
						guard let range: AVFrameRateRange = videoSupportedFrameRateRange as? AVFrameRateRange else { continue }
						if range.minFrameRate <= Float64(paramator.frameRate) &&
							Float64(paramator.frameRate) >= range.maxFrameRate &&
							filterColorSpaces.count >= 1 &&
							width == CGFloat(maxWidth) &&
							height == CGFloat(maxHeight)
						{
							guard Float64(paramator.frameRate) <= range.maxFrameRate else { continue }
							deviceFormat = format
							minFrameRate = Int32(range.minFrameRate)
							maxFrameRate = Int32(range.maxFrameRate)
							
							return (deviceFormat: deviceFormat, depthDataFormat: nil, filterColorSpace: filterColorSpaces.first, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
						} else if range.minFrameRate <= Float64(paramator.frameRate) &&
							Float64(paramator.frameRate) >= range.maxFrameRate &&
							//filterColorSpaces.count >= 1 &&
							width == CGFloat(maxWidth) &&
							height == CGFloat(maxHeight)
						{
							guard Float64(paramator.frameRate) <= range.maxFrameRate else { continue }
							
							//print(item.supportedDepthDataFormats)
							
							deviceFormat = format
							minFrameRate = Int32(range.minFrameRate)
							maxFrameRate = Int32(range.maxFrameRate)
							
							return (deviceFormat: deviceFormat, depthDataFormat: nil, filterColorSpace: filterColorSpaces.first, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
						}
						else if range.minFrameRate <= Float64(paramator.frameRate) && Float64(paramator.frameRate) >= range.maxFrameRate {
							guard Float64(paramator.frameRate) <= range.maxFrameRate else { continue }
							guard width >= CGFloat(maxWidth) else { continue }
							guard height >= CGFloat(maxHeight) else { continue }
							
							deviceFormat = format
							minFrameRate = Int32(range.minFrameRate)
							maxFrameRate = Int32(range.maxFrameRate)
						}
					}

				}
				/*
				let disparity16formats: [AVCaptureDevice.Format] = depthFormats.filter { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DisparityFloat16 }
				let disparity32formats: [AVCaptureDevice.Format] = depthFormats.filter { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DisparityFloat32 }
				let depth16formats: [AVCaptureDevice.Format] = depthFormats.filter { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat16 }
				*/
				
			}
			
			self.onUpdate?(deviceFormat)
			return (deviceFormat: deviceFormat, depthDataFormat: nil, filterColorSpace: nil, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
		}
	}
}
