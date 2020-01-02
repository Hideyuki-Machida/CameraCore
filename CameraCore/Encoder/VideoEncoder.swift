//
//  VideoEncoder.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/08.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import AVFoundation

public class VideoEncoder {
	
	internal enum EncoderError: Error {
		case setupError
	}
	
	static var assetExportSession: AVAssetExportSession?
	
	fileprivate static var displayLink: CADisplayLink?
	fileprivate static var exportPath: URL?
	fileprivate static var progress: ((_ progress: Float)->Void)?
	public fileprivate(set) static var isEncoding = false
	
	public static func setup(property: VideoEncorderProperty) throws {
		guard self.isEncoding != true else { throw EncoderError.setupError }
		self.exportPath = property.exportPath
		
		if property.codec == .hevc {
			self.assetExportSession = AVAssetExportSession(asset: property.compositionData.composition, presetName: property.presetiFrame.aVAssetExportSessionHEVCPreset())
		} else {
			self.assetExportSession = AVAssetExportSession(asset: property.compositionData.composition, presetName: property.presetiFrame.aVAssetExportSessionPreset())
		}
        self.assetExportSession?.videoComposition = property.compositionData.videoComposition
        self.assetExportSession?.audioMix = property.compositionData.audioMix
        
        self.assetExportSession?.outputFileType = AVFileType.mp4
        self.assetExportSession?.outputURL = exportPath
        self.assetExportSession?.shouldOptimizeForNetworkUse = true
	}
	
	public static func start(completion: @escaping (_ status: Bool, _ exportPath: URL?)->Void, progress: ((_ progress: Float)->Void)? = nil) {
		guard self.isEncoding != true else { completion(false, self.exportPath); return }
		self.isEncoding = true
		self.progress = progress
		self.startLink()
		guard let assetExportSession: AVAssetExportSession = VideoEncoder.assetExportSession else { completion(false, self.exportPath); return }
		self.assetExportSession?.exportAsynchronously(completionHandler: {
			self.isEncoding = false
			self.closeLink()
			let status: Bool
			switch (assetExportSession.status) {
			case .completed: status = true; Debug.SuccessLog("VideoEncoder: 生成完了")
			case .waiting: status = true; Debug.ErrorLog("VideoEncoder: waiting")
			case .unknown: status = true; Debug.ErrorLog("VideoEncoder: unknown")
			case .exporting: status = true; Debug.SuccessLog("VideoEncoder: exporting")
			case .cancelled: status = false; Debug.ErrorLog("VideoEncoder: 生成キャンセル")
			case .failed: status = false; Debug.ErrorLog("VideoEncoder: 生成失敗")
			@unknown default: status = false; Debug.ErrorLog("VideoEncoder: 生成失敗")
			}
			
			DispatchQueue.main.async {
				completion(status, VideoEncoder.exportPath)
			}
		})
	}
	
	public static func removeCache(exportPath: URL) -> Bool {
		do {
			try	FileManager.default.removeItem(at: exportPath)
			return true
		} catch {
			return false
		}
	}
}

extension VideoEncoder {
	
	fileprivate static func startLink() {
		self.displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkDidRefresh))
		self.displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
	}
	
	fileprivate static func closeLink() {
		self.displayLink?.invalidate()
		self.displayLink = nil
	}
	
	@objc fileprivate static func displayLinkDidRefresh() {
		guard let assetExportSession: AVAssetExportSession = self.assetExportSession else { return }
		let progress: Float = assetExportSession.progress
		DispatchQueue.main.async {
			self.progress?(progress)
		}
	}
}
