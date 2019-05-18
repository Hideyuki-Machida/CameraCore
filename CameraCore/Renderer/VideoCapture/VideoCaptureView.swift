//
//  VideoCaptureView.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/03/09.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import UIKit
import GLKit
import AVFoundation


public enum VideoCaptureStatus {
    case setup
    case update
    case ready
    case play
    case pause
    case seek
    case dispose
}

public class VideoCaptureView: ImageRenderView, VideoCaptureViewProtocol {
	
	private let queue: DispatchQueue = DispatchQueue(label: "com.cchannel.CameraCore.VideoCaptureView.queue")
	
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
    }
    
    fileprivate var counter: CMTimeValue = 0
    
    deinit {
        Debug.DeinitLog(self)
    }
    
	public func setup(frameRate: Int32, presetiFrame: Settings.PresetiFrame, position: AVCaptureDevice.Position) throws {
        Debug.ActionLog("CCamVideo.VideoRecordingPlayer.setup - frameRate: \(frameRate), presetiFrame: \(presetiFrame)")
        self.setup()
        
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
			autoreleasepool() {
				guard let `self` = self else { return }
				if Renderer.VideoCapture.CaptureWriter.isWritng == true {
					Renderer.VideoCapture.CaptureWriter.addCaptureSampleBuffer(sampleBuffer: sampleBuffer)
					let t: TimeInterval = Renderer.VideoCapture.CaptureWriter.recordedDuration
					//DispatchQueue.main.async {
					self.event?.onRecodingUpdate?(t)
					//}
				}
				
				if let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
					var image: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
					if let croppingRect: CGRect = self.croppingRect {
						image = self.crip(pixelBuffer: pixelBuffer, rect: croppingRect)
					}
					
					let renderSize: CGSize = self.renderSize ?? presetiFrame.size()
					
					for (index, _) in self.renderLayers.enumerated() {
						let compositionTime: CMTime = CMTime.init(value: self.counter, timescale: frameRate)
						if var layer: CIImageRenderLayerProtocol = self.renderLayers[index] as? CIImageRenderLayerProtocol {
							
							var renderLayerCompositionInfo: RenderLayerCompositionInfo = RenderLayerCompositionInfo.init(
								compositionTime: compositionTime,
								timeRange: CMTimeRange.init(),
								percentComplete: 0.0,
								renderSize: renderSize,
								queue: self.queue
							)
							
							do {
								image = try layer.processing(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
							} catch {
								
							}
						}
					}
					
					self.counter += 1
					self.updateImage(image: image)
					
					//DispatchQueue.main.async {
					self.event?.onPreviewUpdate?(sampleBuffer)
					//}
				}
				
			}
		}
		
   
    }
    
    public func play() {
        guard self.status != .play else { return }
        Debug.ActionLog("CCamVideo.VideoRecordingPlayer.play")
        self.capture?.play()
        self.isDrawable = true
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
        self.isDrawable = false
        self.status = .setup
        self.capture = nil
    }
}

extension VideoCaptureView {
    public func recordingStart(_ paramator: Renderer.VideoCapture.CaptureWriter.Paramator) throws {
		try self.capture?.addAudioDataOutput()
        let _ = Renderer.VideoCapture.CaptureWriter.setup(paramator)
        let _ = Renderer.VideoCapture.CaptureWriter.start()
    }
    
    public func recordingStop() {
        Renderer.VideoCapture.CaptureWriter.finish({ [weak self] (result: Bool, filePath: URL) in
            DispatchQueue.main.async { [weak self] in
                self?.event?.onRecodingComplete?(result, filePath)
            }
        })
    }
    
    public func recordingCancelled() {
        Renderer.VideoCapture.CaptureWriter.finish(nil)
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
