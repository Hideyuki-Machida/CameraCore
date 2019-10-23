//
//  MetalVideoCaptureView.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/12/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MetalCanvas

public enum VideoCaptureStatus {
	case setup
	case update
	case ready
	case play
	case pause
	case seek
	case dispose
}

public class VideoCaptureView: MCImageRenderView, VideoCaptureViewProtocol {
	
	private let queue: DispatchQueue = DispatchQueue(label: "CameraCore.MetalVideoCaptureView.queue")
	
	public var status: VideoCaptureStatus = .setup {
		willSet {
			self.event?.onStatusChange?(newValue)
		}
	}
	
	public var capture: CCRenderer.VideoCapture.VideoCapture?
	
	public var croppingRect: CGRect?
	public var renderSize: CGSize?
	public var isRecording: Bool {
		get{
			return CCRenderer.VideoCapture.CaptureWriter.isWritng
		}
	}
	
	public var event: VideoCaptureViewEvent?
	
	/// 描画時に適用されるフィルターを指定
	public var renderLayers: [RenderLayerProtocol] = []
	
	internal enum RecordingError: Error {
		case setupError
		case render
	}
	
	fileprivate var counter: CMTimeValue = 0
	fileprivate var depthMapRenderer: CCRenderer.ARRenderer.DepthMapRenderer = CCRenderer.ARRenderer.DepthMapRenderer.init()
	fileprivate var depthMapToHumanSegmentationTexture: MCVision.Depth.HumanSegmentationTexture = MCVision.Depth.HumanSegmentationTexture.init()
	fileprivate var textureCache: CVMetalTextureCache? = MCCore.createTextureCache()
	
	public override func awakeFromNib() {
		super.awakeFromNib()
	}

	deinit {
		Debug.DeinitLog(self)
		NotificationCenter.default.removeObserver(self)
	}
	
	public override func setup() throws {
		try super.setup()
		let propertys: CCRenderer.VideoCapture.Propertys = CCRenderer.VideoCapture.Propertys.init(
			devicePosition: AVCaptureDevice.Position.back,
			deviceType: AVCaptureDevice.DeviceType.builtInDualCamera,
			option: [
				.captureSize(Settings.PresetSize.p1280x720),
				.frameRate(Settings.PresetFrameRate.fr30)
			]
		)
		try self.setup(propertys)
	}

	public func setup(_ propertys: CCRenderer.VideoCapture.Propertys) throws {
		self.status = .setup

		do {
			self.capture = try CCRenderer.VideoCapture.VideoCapture(propertys: propertys)
		} catch {
			self.capture = nil
			throw RecordingError.setupError
		}

		self.capture?.onUpdate = { [weak self] (sampleBuffer: CMSampleBuffer, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?) in
			guard self?.status == .play else { return }

			self?.queue.async { [weak self] in
				autoreleasepool() { [weak self] in
					do {
						try self?.updateFrame(
							sampleBuffer: sampleBuffer,
							depthData: depthData,
							metadataObjects: metadataObjects,
							position: self?.capture?.propertys.info.devicePosition ?? .back
						)
					} catch {

					}
				}
			}
		}

	}

	public func play() {
		guard self.status != .play else { return }
		Debug.ActionLog("CCamVideo.VideoRecordingPlayer.play")
		self.capture?.play()
		self.status = .play
	}
	
	public func pause() {
		Debug.ActionLog("CCamVideo.VideoRecordingPlayer.pause")
		self.capture?.stop()
		self.status = .pause
	}
	
	public func dispose() {
		Debug.ActionLog("CCamVideo.VideoRecordingPlayer.dispose")
		self.capture?.stop()
		self.status = .setup
		self.capture = nil
	}
}

extension VideoCaptureView {
	public func update(propertys: CCRenderer.VideoCapture.Propertys) throws {
		self.capture?.stop()
		try self.capture?.update(propertys: propertys)
		guard self.status == .play else { return }
		self.capture?.play()
	}
}

extension VideoCaptureView {
	public func recordingStart(_ paramator: CCRenderer.VideoCapture.CaptureWriter.Paramator) throws {
		try self.capture?.addAudioDataOutput()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			let _ = CCRenderer.VideoCapture.CaptureWriter.setup(paramator)
			let _ = CCRenderer.VideoCapture.CaptureWriter.start()
		}
	}
	
	public func recordingStop() {
		CCRenderer.VideoCapture.CaptureWriter.finish({ [weak self] (result: Bool, filePath: URL) in
			DispatchQueue.main.async { [weak self] in
				do {
					try self?.capture?.removeAudioDataOutput()
					self?.event?.onRecodingComplete?(result, filePath)
				} catch {
					
				}
			}
		})
	}
	
	public func recordingCancelled() {
		CCRenderer.VideoCapture.CaptureWriter.finish(nil)
	}
}

extension VideoCaptureView {
	fileprivate func crip(pixelBuffer: CVPixelBuffer, rect: CGRect) -> CIImage {
		let tempImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
		let cropFilter = CIFilter(name: "CICrop")
		cropFilter?.setValue(tempImage, forKey: kCIInputImageKey)
		cropFilter?.setValue(rect, forKey: "inputRectangle")
		return (cropFilter?.outputImage)!.transformed(by: CGAffineTransform(translationX: 0, y: -rect.origin.y ))
	}
}

extension VideoCaptureView {
	/// フォーカスポイントを設定
	public func focus(atPoint: CGPoint) -> Bool {
		guard let videoCapture: CCRenderer.VideoCapture.VideoCapture = self.capture else { return false }
		return videoCapture.focus(atPoint: atPoint)
	}
}

extension VideoCaptureView {
	fileprivate func updateFrame(sampleBuffer: CMSampleBuffer, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?, position: AVCaptureDevice.Position) throws {
		//guard let `self` = self else { return }
		//guard var textureCache: CVMetalTextureCache = self.textureCache else { throw RecordingError.render }
		
		guard let frameRate: Int32 = self.capture?.propertys.info.frameRate else { return }
		//////////////////////////////////////////////////////////
		// renderSize
		if CCRenderer.VideoCapture.CaptureWriter.isWritng == true {
			CCRenderer.VideoCapture.CaptureWriter.addCaptureSampleBuffer(sampleBuffer: sampleBuffer)
			let t: TimeInterval = CCRenderer.VideoCapture.CaptureWriter.recordedDuration
			DispatchQueue.main.async {
				self.event?.onRecodingUpdate?(t)
			}
		}
		//////////////////////////////////////////////////////////
		
		//////////////////////////////////////////////////////////
		// renderSize
		guard var originalPixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
		let width: Int = CVPixelBufferGetWidth(originalPixelBuffer)
		let height: Int = CVPixelBufferGetHeight(originalPixelBuffer)
		let renderSize: CGSize = CGSize.init(width: width, height: height)
		//////////////////////////////////////////////////////////
		/*
		//////////////////////////////////////////////////////////
		// rgbPixelBuffer
		guard var rgbPixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: renderSize) else { return }
		guard let originalMTLTexture: MTLTexture
			= MCCore.texture(pixelBuffer: &originalPixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { return }
		guard let rgbMTLTexture: MTLTexture
			= MCCore.texture(pixelBuffer: &rgbPixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { return }
		guard let commandBuffer0: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
		let blitEncoder: MTLBlitCommandEncoder? = commandBuffer0.makeBlitCommandEncoder()
		blitEncoder?.copy(from: originalMTLTexture,
						  sourceSlice: 0,
						  sourceLevel: 0,
						  sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
						  sourceSize: MTLSizeMake(rgbMTLTexture.width, rgbMTLTexture.height, rgbMTLTexture.depth),
						  to: rgbMTLTexture,
						  destinationSlice: 0,
						  destinationLevel: 0,
						  destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
		blitEncoder?.endEncoding()
		commandBuffer0.commit()
		//////////////////////////////////////////////////////////
		*/

		do {
			///////////////////////////////////////////////////////////////////////////////////////////////////
			// renderLayerCompositionInfo
			var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo.init(
				compositionTime: CMTime(value: self.counter, timescale: frameRate),
				timeRange: CMTimeRange.zero,
				percentComplete: 0.0,
				renderSize: renderSize,
				metadataObjects: metadataObjects ?? [],
				depthData: depthData,
				queue: self.queue
			)
			self.counter += 1
			///////////////////////////////////////////////////////////////////////////////////////////////////

			///////////////////////////////////////////////////////////////////////////////////////////////////
			// renderLayerCompositionInfo
			guard var commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
			for (index, _) in self.renderLayers.enumerated() {
				if var renderLayer: MetalRenderLayerProtocol = self.renderLayers[index] as? MetalRenderLayerProtocol {
					do {
						try self.processingMetalRenderLayer(renderLayer: &renderLayer, commandBuffer: &commandBuffer, pixelBuffer: &originalPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
					} catch {
						Debug.ErrorLog(error)
					}
				} else if var renderLayer: CVPixelBufferRenderLayerProtocol = self.renderLayers[index] as? CVPixelBufferRenderLayerProtocol {
					do {
						try renderLayer.processing(commandBuffer: &commandBuffer, pixelBuffer: &originalPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
					} catch {
						Debug.ErrorLog(error)
					}
				}
			}
			//commandBuffer.commit()
			///////////////////////////////////////////////////////////////////////////////////////////////////
			
			//////////////////////////////////////////////////////////
			// renderSize
			guard let rgbTexture: MTLTexture = MCCore.texture(pixelBuffer: &originalPixelBuffer, colorPixelFormat: self.colorPixelFormat) else { return }
			//let rgbTexture: MCTexture = try MCTexture.init(pixelBuffer: &originalPixelBuffer, planeIndex: 0)
			//////////////////////////////////////////////////////////

			//guard var commandBuffer002: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
			//var texture: MTLTexture = rgbTexture.texture
			commandBuffer.addCompletedHandler { [weak self] cb in
				self?.event?.onPreviewUpdate?(sampleBuffer)
				self?.event?.onPixelUpdate?(originalPixelBuffer)
			}

			self.update(commandBuffer: &commandBuffer, texture: rgbTexture, renderSize: renderSize, queue: nil)
		} catch {
			return
		}
	}
	
	private func processingMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw RecordingError.render }
		guard let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw RecordingError.render }
		guard var destinationTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat) else { throw RecordingError.render }
		try renderLayer.processing(commandBuffer: &commandBuffer, source: sourceTexture, destination: &destinationTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
	}
}
