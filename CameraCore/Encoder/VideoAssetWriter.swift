//
//  VideoAssetWriter.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/11/25.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

final public class VideoAssetWriter {

	public var status: AVAssetWriter.Status {
		get{
			if let writer: AVAssetWriter = self.writer {
				return writer.status
			}
			return AVAssetWriter.Status.unknown
		}
	}
	
	internal enum EncoderError: Error {
		case setupError
	}
	
	fileprivate(set) var videoInput: AVAssetWriterInput?
	fileprivate(set) var audioInput: AVAssetWriterInput?
    fileprivate(set) var writer: AVAssetWriter?
	fileprivate(set) var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

	func setup(_ property: VideoEncorderProperty) throws {
		
		///////////////////////////////////////////////////
		
		let w: AVAssetWriter = try AVAssetWriter(outputURL: property.exportPath, fileType: AVFileType.mov)
		let compressionProperties = NSMutableDictionary()
		compressionProperties[AVVideoExpectedSourceFrameRateKey] = property.frameRate
		compressionProperties[AVVideoMaxKeyFrameIntervalKey] = property.frameRate
		if let bitRateKey = property.bitRateKey {
			// 2400000
			compressionProperties[AVVideoAverageBitRateKey] = bitRateKey
		}
		
		let input: AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
			AVVideoCodecKey: property.codec.val,
			AVVideoWidthKey: property.renderSize.width,
			AVVideoHeightKey: property.renderSize.height,
			AVVideoCompressionPropertiesKey: compressionProperties,
			])
		input.expectsMediaDataInRealTime = true
		//input.expectsMediaDataInRealTime = false
		
		if w.canAdd(input) {
			w.add(input)
		} else {
			throw EncoderError.setupError
		}
		
		///////////////////////////////////////////////////
		
		let audioInput: AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
			AVFormatIDKey as String : NSNumber(value: kAudioFormatMPEG4AAC),
			AVSampleRateKey as String : NSNumber(value: 44100.0),
			AVNumberOfChannelsKey as String : NSNumber(value: 2),
			])
		audioInput.expectsMediaDataInRealTime = true
		//audioInput.expectsMediaDataInRealTime = false
		self.audioInput = audioInput
		
		if w.canAdd(audioInput) {
			w.add(audioInput)
			self.audioInput = audioInput
		}

		///////////////////////////////////////////////////
		
		// AVAssetWriterInputPixelBufferAdaptorを生成
		let sourcePixelBufferAttributes: [String : Any] = [
			kCVPixelBufferPixelFormatTypeKey as String : Configuration.sourcePixelBufferPixelFormatTypeKey,
			kCVPixelBufferWidthKey as String: property.renderSize.width,
			kCVPixelBufferHeightKey as String: property.renderSize.height,
			kCVPixelFormatOpenGLESCompatibility as String: true,
			]
		self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
		
		self.writer = w
		self.videoInput = input
	}
	
	
	func addVideoBuffer(videoBuffer: CMSampleBuffer, timestamp: CMTime) -> Bool {
		guard let pixelBuf: CVPixelBuffer = CMSampleBufferGetImageBuffer(videoBuffer) else { return false }		
		guard let pool: CVPixelBufferPool = self.pixelBufferAdaptor?.pixelBufferPool else {
			Debug.ErrorLog("pixelBufferPool nil")
			return false
		}
		
		var outputRenderBuffer: CVPixelBuffer? = nil
		let result: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &outputRenderBuffer)
		
		if result == kCVReturnError {
			Debug.ErrorLog("CVPixelBufferPoolCreatePixelBuffer error")
			return false
		}
		
		guard outputRenderBuffer != nil else { return false }
		let resultImage: CIImage = CIImage.init(cvPixelBuffer: pixelBuf)
		let colorSpace: CGColorSpace = resultImage.colorSpace ?? Configuration.colorSpace
		CVPixelBufferLockBaseAddress(outputRenderBuffer!, CVPixelBufferLockFlags.readOnly)
		SharedContext.ciContext.render(resultImage, to: outputRenderBuffer!, bounds: resultImage.extent, colorSpace: colorSpace)
		self.pixelBufferAdaptor?.append(outputRenderBuffer!, withPresentationTime: timestamp)
		CVPixelBufferUnlockBaseAddress(outputRenderBuffer!, CVPixelBufferLockFlags.readOnly)
		return true
	}
	
	func addAudioBuffer(audioBuffer: CMSampleBuffer) {
		self.audioInput?.append(audioBuffer)
	}
	
	func start() throws {
		guard self.writer != nil else { throw EncoderError.setupError }
		self.writer!.startWriting()
		self.writer!.startSession(atSourceTime: CMTime.zero)
	}
	
	func stop() throws {
		guard self.writer != nil else { throw EncoderError.setupError }
		self.writer!.cancelWriting()
		self.writer = nil
		self.videoInput = nil
		self.audioInput = nil
	}
	
	func finish(complete: @escaping ()->Void) throws {
		guard self.writer != nil else { throw EncoderError.setupError }
		self.videoInput?.markAsFinished()
		self.audioInput?.markAsFinished()
		self.writer?.finishWriting {
			complete()
			self.writer = nil
			self.videoInput = nil
			self.audioInput = nil
		}
	}

}
