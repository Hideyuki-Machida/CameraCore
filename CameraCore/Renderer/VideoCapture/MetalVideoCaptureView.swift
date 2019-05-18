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

public class MetalVideoCaptureView: MCImageRenderView, VideoCaptureViewProtocol {
	private let queue: DispatchQueue = DispatchQueue(label: "com.cchannel.CameraCore.MetalVideoCaptureView.queue")
	
	public var status: VideoCaptureStatus = .setup {
		willSet {
			self.event?.onStatusChange?(newValue)
		}
	}
	
	public var capture: Renderer.VideoCapture.VideoCapture?
	
	public var croppingRect: CGRect?
	public var renderSize: CGSize?
	public var isRecording: Bool {
		get{
			return Renderer.VideoCapture.CaptureWriter.isWritng
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
	fileprivate var currentOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
	fileprivate var textureCache: CVMetalTextureCache? = MCCore.createTextureCache()
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		//NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationDidChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
	}

	deinit {
		Debug.DeinitLog(self)
		NotificationCenter.default.removeObserver(self)
	}
	
	public func setup(frameRate: Int32, presetiFrame: Settings.PresetiFrame, position: AVCaptureDevice.Position) throws {
		Debug.ActionLog("CCamVideo.VideoRecordingPlayer.setup - frameRate: \(frameRate), presetiFrame: \(presetiFrame)")
		//self.setup()
		
		Configuration.captureSize = presetiFrame
		
		do {
			//
			self.capture = try Renderer.VideoCapture.VideoCapture(frameRate: frameRate, presetiFrame: presetiFrame, position: position)
			//
		} catch {
			self.capture = nil
			throw RecordingError.setupError
		}

		self.capture?.onUpdate = { [weak self] (sampleBuffer: CMSampleBuffer) in
			guard self?.status == .play else { return }
			self?.queue.async { [weak self] in
				autoreleasepool() { [weak self] in
					do {
						try self?.updateFrame(
							sampleBuffer: sampleBuffer,
							position: self?.capture?.position ?? .back,
							orientation: self?.currentOrientation ?? .portrait
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
		//self.isDrawable = true
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
		//self.isDrawable = false
		self.status = .setup
		self.capture = nil
	}
}

extension MetalVideoCaptureView {
	@objc
	func onOrientationDidChange(notification: NSNotification) {
		self.currentOrientation = AVCaptureVideoOrientation.init(ui: UIApplication.shared.statusBarOrientation)
	}
}

extension MetalVideoCaptureView {
	public func recordingStart(_ paramator: Renderer.VideoCapture.CaptureWriter.Paramator) throws {
		try self.capture?.addAudioDataOutput()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			let _ = Renderer.VideoCapture.CaptureWriter.setup(paramator)
			let _ = Renderer.VideoCapture.CaptureWriter.start()
		}
	}
	
	public func recordingStop() {
		Renderer.VideoCapture.CaptureWriter.finish({ [weak self] (result: Bool, filePath: URL) in
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
		Renderer.VideoCapture.CaptureWriter.finish(nil)
	}
}

extension MetalVideoCaptureView {
	fileprivate func crip(pixelBuffer: CVPixelBuffer, rect: CGRect) -> CIImage {
		let tempImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
		let cropFilter = CIFilter(name: "CICrop")
		cropFilter?.setValue(tempImage, forKey: kCIInputImageKey)
		cropFilter?.setValue(rect, forKey: "inputRectangle")
		return (cropFilter?.outputImage)!.transformed(by: CGAffineTransform(translationX: 0, y: -rect.origin.y ))
	}
}

extension MetalVideoCaptureView {
	// MARK: -
	public var frameRate: Int32 { return self.capture?.frameRate ?? 30 }
	public var presetiFrame: Settings.PresetiFrame { return self.capture?.presetiFrame ?? Settings.PresetiFrame.p1280x720 }
	//public var position: Settings.PresetiFrame { return self._videoCapture?.presetiFrame ?? Settings.PresetiFrame.p1920x1080 }
	
	/// フォーカスポイントを設定
	public func focus(atPoint: CGPoint) -> Bool {
		guard let videoCapture: Renderer.VideoCapture.VideoCapture = self.capture else { return false }
		return videoCapture.focus(atPoint: atPoint)
	}
}

extension MetalVideoCaptureView {
	fileprivate func updateFrame(sampleBuffer: CMSampleBuffer, position: AVCaptureDevice.Position, orientation: AVCaptureVideoOrientation) throws {

	//fileprivate func updateFrame(sampleBuffer: CMSampleBuffer, depthData: AVDepthData?, metadataObjects: [AVMetadataObject]?, position: AVCaptureDevice.Position, orientation: AVCaptureVideoOrientation) throws {
		//guard let `self` = self else { return }
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw RecordingError.render }
		
		//////////////////////////////////////////////////////////
		// renderSize
		if Renderer.VideoCapture.CaptureWriter.isWritng == true {
			Renderer.VideoCapture.CaptureWriter.addCaptureSampleBuffer(sampleBuffer: sampleBuffer)
			let t: TimeInterval = Renderer.VideoCapture.CaptureWriter.recordedDuration
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
		
		do {
			///////////////////////////////////////////////////////////////////////////////////////////////////
			// renderLayerCompositionInfo
			var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo.init(
				compositionTime: CMTime(value: self.counter, timescale: 24),
				timeRange: CMTimeRange.zero,
				percentComplete: 0.0,
				renderSize: renderSize,
				//metadataObjects: metadataObjects ?? [],
				//depthData: depthData,
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
						try self.processingMetalRenderLayer(renderLayer: &renderLayer, commandBuffer: &commandBuffer, pixelBuffer: &rgbPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
					} catch {
						Debug.ErrorLog(error)
					}
				} else if var renderLayer: CVPixelBufferRenderLayerProtocol = self.renderLayers[index] as? CVPixelBufferRenderLayerProtocol {
					do {
						try renderLayer.processing(commandBuffer: &commandBuffer, pixelBuffer: &rgbPixelBuffer, renderLayerCompositionInfo: &renderLayerCompositionInfo)
					} catch {
						Debug.ErrorLog(error)
					}
				}
			}
			commandBuffer.commit()
			///////////////////////////////////////////////////////////////////////////////////////////////////
			
			//////////////////////////////////////////////////////////
			// renderSize
			let rgbTexture: MCTexture = try MCTexture.init(pixelBuffer: &rgbPixelBuffer, planeIndex: 0)
			DispatchQueue.main.async {
				self.event?.onPreviewUpdate?(sampleBuffer)
			}
			//////////////////////////////////////////////////////////

			guard var commandBuffer002: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
			var texture: MTLTexture = rgbTexture.texture
			self.update(commandBuffer: &commandBuffer002, texture: &texture, renderSize: renderSize, queue: nil)
		} catch {
			return
		}
	}
	
	private func processingMetalRenderLayer(renderLayer: inout MetalRenderLayerProtocol, commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard var textureCache: CVMetalTextureCache = self.textureCache else { throw RecordingError.render }
		guard let sourceTexture: MTLTexture = MCCore.texture(pixelBuffer: &pixelBuffer, textureCache: &textureCache, colorPixelFormat: MTLPixelFormat.bgra8Unorm) else { throw RecordingError.render }
		guard var destinationTexture: MTLTexture = sourceTexture.makeTextureView(pixelFormat: sourceTexture.pixelFormat) else { throw RecordingError.render }
		try renderLayer.processing(commandBuffer: &commandBuffer, sourceTexture: sourceTexture, destinationTexture: &destinationTexture, renderLayerCompositionInfo: &renderLayerCompositionInfo)
	}
}
