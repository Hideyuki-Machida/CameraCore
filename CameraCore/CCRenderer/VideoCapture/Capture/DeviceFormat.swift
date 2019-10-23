//
//  CaptureDeviceFormat.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/01/10.
//  Copyright © 2019 町田 秀行. All rights reserved.
//
/*
import Foundation
import AVFoundation

extension CCRenderer.VideoCapture {
	final class DeviceFormat {
		var onUpdate: ((_ deviceFormat: AVCaptureDevice.Format?)->Void)?
		
		func get(videoDevice: AVCaptureDevice, paramator: inout Paramator) throws -> (deviceFormat: AVCaptureDevice.Format?, depthDataFormat: AVCaptureDevice.Format?, filterColorSpace: AVCaptureColorSpace?, minFrameRate: Int32, maxFrameRate: Int32) {
			let width: CGFloat = paramator.presetSize.size().height
			let height: CGFloat = paramator.presetSize.size().width

			var deviceFormat: AVCaptureDevice.Format?
			var minFrameRate: Int32 = 0
			var maxFrameRate: Int32 = 0
            
            let options: Paramator.Options? = paramator.options
            let isDepthDataOutput: Paramator.Value = options?.isDepthDataOutput ?? .off
            let isVideoHDRSupported: Paramator.Value = options?.isVideoHDRSupported ?? .off

            var depthDataSupportedFormats: [AVCaptureDevice.Format] = []
            var videoHDRSupportedFormats: [AVCaptureDevice.Format] = []
            
			// フレームレート
			for format: AVCaptureDevice.Format in videoDevice.formats {
				guard format.mediaType == .video else { continue }
				let maxWidth: Int32 = CMVideoFormatDescriptionGetDimensions(format.formatDescription).width
				let maxHeight: Int32 = CMVideoFormatDescriptionGetDimensions(format.formatDescription).height
                
				guard 640 <= CGFloat(maxWidth) else { continue }

                let frameRateRanges: [AVFrameRateRange] = format.videoSupportedFrameRateRanges.filter { $0.minFrameRate <= Float64(paramator.frameRate) && Float64(paramator.frameRate) <= $0.maxFrameRate }
                let colorSpaces: [AVCaptureColorSpace] = format.supportedColorSpaces.filter { $0 == paramator.colorSpace }
                let depth32formats: [AVCaptureDevice.Format] = format.supportedDepthDataFormats.filter { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat32 }

                for videoSupportedFrameRateRange: Any in format.videoSupportedFrameRateRanges {
                    guard let range: AVFrameRateRange = videoSupportedFrameRateRange as? AVFrameRateRange else { continue }
                    if range.minFrameRate <= Float64(paramator.frameRate) && Float64(paramator.frameRate) <= range.maxFrameRate &&
                        width <= CGFloat(maxWidth) && height <= CGFloat(maxHeight)
                    {
                        guard colorSpaces.count >= 1 else { continue }
                     
                        ///////////////////////////////////////////////////////////////////////
                        deviceFormat = format
                        minFrameRate = Int32(range.minFrameRate)
                        maxFrameRate = Int32(range.maxFrameRate)
                        ///////////////////////////////////////////////////////////////////////

                        let selectedDepthFormat: AVCaptureDevice.Format?
                        if isDepthDataOutput == .required || isDepthDataOutput == .on, depth32formats.count >= 1 {
                            // 解像度が最大のものを選ぶ
                            selectedDepthFormat = depth32formats.max(by: { first, second in
                                CMVideoFormatDescriptionGetDimensions(first.formatDescription).width
                                    < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
                            })!
                            depthDataSupportedFormats.append(format)
                        } else {
                            selectedDepthFormat = nil
                        }

                        if isVideoHDRSupported == .required || isVideoHDRSupported == .on, format.isVideoHDRSupported == true {
                            videoHDRSupportedFormats.append(format)
                        }
                        
                        //paramator.traceInfo.deviceFormat = deviceFormat

                        //return (deviceFormat: deviceFormat, depthDataFormat: selectedDepthFormat, filterColorSpace: colorSpaces.first, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
                    }
                }
                /*
                for videoSupportedFrameRateRange: Any in format.videoSupportedFrameRateRanges {
                    guard let range: AVFrameRateRange = videoSupportedFrameRateRange as? AVFrameRateRange else { continue }
                    if range.minFrameRate <= Float64(paramator.frameRate) && Float64(paramator.frameRate) <= range.maxFrameRate &&
                        width == CGFloat(maxWidth) && height == CGFloat(maxHeight)
                    {
                        deviceFormat = format
                        minFrameRate = Int32(range.minFrameRate)
                        maxFrameRate = Int32(range.maxFrameRate)
                        
                        /*
                        // 解像度が最大のものを選ぶ
                        let selectedDepthFormat: AVCaptureDevice.Format? = depth32formats.max(by: { first, second in
                            CMVideoFormatDescriptionGetDimensions(first.formatDescription).width
                                < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
                        })!
                        */
                        paramator.traceInfo.deviceFormat = format

                        return (deviceFormat: deviceFormat, depthDataFormat: nil, filterColorSpace: colorSpaces.first, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
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
                        
                        return (deviceFormat: deviceFormat, depthDataFormat: selectedDepthFormat, filterColorSpace: colorSpaces.first, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
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
*/
			}
			
            if isDepthDataOutput == .required {
                if depthDataSupportedFormats.count == 0 {
                    throw CCRenderer.ErrorType.deviceFormat
                }
            } else if isDepthDataOutput == .on {
            }
            
            if isVideoHDRSupported == .required {
                if videoHDRSupportedFormats.count == 0 {
                    throw CCRenderer.ErrorType.deviceFormat
                }
            } else if isVideoHDRSupported == .on {
            }

            
            paramator.traceInfo.deviceFormat = deviceFormat

			self.onUpdate?(deviceFormat)
			return (deviceFormat: deviceFormat, depthDataFormat: nil, filterColorSpace: nil, minFrameRate: minFrameRate, maxFrameRate: maxFrameRate)
		}
        
        deinit {
            Debug.DeinitLog(self)
        }

	}
}
*/
