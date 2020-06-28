//
//  CameraRollItem.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/27.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AssetsLibrary
import Photos
import UIKit

extension CCCameraRoll {
    public class Item {
        fileprivate let queue: DispatchQueue = DispatchQueue(label: "AVModule.VideoFileManager.Item.queue", attributes: .concurrent)
        
        public enum ErrorType: Error {
            case exportSession
        }
        
        public let asset: PHAsset
        public var thumbnail: UIImage? = nil
        public let mediaType: PHAssetMediaType
        public let creationDate: Date
        public var onThumbnailLoadCompletion: ((_ image: UIImage?)->Void)?
        init(asset: PHAsset, mediaType: PHAssetMediaType, creationDate: Date) {
            self.asset = asset
            self.mediaType = mediaType
            self.creationDate = creationDate
        }
        
        public func requestThumbnail() {
            let options: PHImageRequestOptions = PHImageRequestOptions()
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            let _ = PHImageManager.default().requestImage(
                for: asset,
                targetSize: CCCameraRoll.Manager.imageSize,
                contentMode: PHImageContentMode.aspectFill,
                options: options,
                resultHandler: { [weak self](image: UIImage?, info) in
                    self?.onThumbnailLoadCompletion?(image)
                }
            )
        }

        /*
        public func url(exportPreset: Settings.PresetiFrame, progressUpdate: ((_ progress: Double)->Void)?, complete: ((Result<AVURLAsset, Error>)->Void)?) {
            switch self.mediaType {
            case .video:
                self.queue.async { [weak self] in
                    self?.videoURL(exportPreset: exportPreset, progressUpdate: progressUpdate, complete: complete)
                }
            case .image:
                self.queue.async { [weak self] in
                    self?.imageURL(exportPreset: exportPreset, progressUpdate: progressUpdate, complete: complete)
                }
            case .audio: break
            case .unknown: break
            @unknown default: break
            }
        }
    */
        /*
        public func url(exportPreset: Settings.PresetiFrame, progressUpdate: ((_ progress: Double)->Void)?, complete: ((Result<AVURLAsset, Error>)->Void)?) {
            switch self.mediaType {
            case .video:
                self.queue.async { [weak self] in
                    self?.videoURL(exportPreset: exportPreset, progressUpdate: progressUpdate, complete: complete)
                }
            case .image:
                self.queue.async { [weak self] in
                    self?.imageURL(exportPreset: exportPreset, progressUpdate: progressUpdate, complete: complete)
                }
            case .audio: break
            case .unknown: break
            @unknown default: break
            }
        }
    */
        
        fileprivate static let encodeCount: Int = 500000
        fileprivate static var count: Int = 0
        fileprivate static var stopFlg: Bool = false
        
        public func url(importURL: URL, exportPreset: Settings.PresetSize, progressUpdate: ((_ progress: Double)->Void)?, complete: ((Result<AVURLAsset, Error>)->Void)?) {
            CCCameraRoll.Item.stopFlg = false
            switch self.mediaType {
            case .video:
                self.queue.async { [weak self] in
                    guard let `self` = self else { return }
                    
                    let options: PHVideoRequestOptions = PHVideoRequestOptions()
                    options.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
                    //options.deliveryMode = PHVideoRequestOptionsDeliveryMode.mediumQualityFormat
                    options.isNetworkAccessAllowed = true
                    options.version = PHVideoRequestOptionsVersion.original
                    //options.version = PHVideoRequestOptionsVersion.current
                    options.progressHandler = { (progress, error, stop, info) in

                        progressUpdate?(progress)
                    }
                    
                    PHImageManager.default().requestExportSession(forVideo: self.asset, options: options, exportPreset: exportPreset.aVAssetExportSessionPreset, resultHandler: { (session: AVAssetExportSession?, info: [AnyHashable : Any]?) in
                        guard let exportSession: AVAssetExportSession = session else { complete?(.failure(ErrorType.exportSession)); return }
                        exportSession.outputURL = importURL
                        exportSession.outputFileType = AVFileType.mp4
                        
                        if exportSession.error != nil {
                            // 書き出しにエラーがあった場合
                            complete?(.failure(ErrorType.exportSession))
                            return
                        }
                        
                        exportSession.exportAsynchronously() {
                            // 書き出し成功
                            CCCameraRoll.Item.stopFlg = true
                            progressUpdate?(1.0)
                            let asset: AVURLAsset = AVURLAsset.init(url: importURL)
                            complete?(.success(asset))
                        }
                        
                        
                        while true {
                            if CCCameraRoll.Item.stopFlg {
                                break
                            }

                            if CCCameraRoll.Item.count < CCCameraRoll.Item.encodeCount {
                                CCCameraRoll.Item.count += 1
                            } else {
                                CCCameraRoll.Item.count = 0
                                
                                if exportSession.progress >= 1.0 {
                                    break
                                }
                                progressUpdate?(Double(exportSession.progress))

                            }

                        }
                    })
                    
                }
            case .image: break
            case .audio: break
            case .unknown: break
            @unknown default: break
            }
        }

        public func importAsset(importURL: URL, exportPreset: Settings.PresetSize, progressUpdate: ((_ progress: Double)->Void)?, complete: @escaping ((_ status: CCCameraRoll.ImportStatus, _ asset: AVURLAsset?)->Void)) {
            switch self.mediaType {
            case .video:
                self.queue.async { [weak self] in
                    self?.importVideoAsset(importURL: importURL, exportPreset: exportPreset, progressUpdate: progressUpdate, complete: complete)
                }
            case .image: break
            case .audio: break
            case .unknown: break
            @unknown default: break
            }
        }
        

    }
}


extension CCCameraRoll.Item {
    public func getVideoURL(exportPreset: Settings.PresetSize, progressUpdate: ((_ progress: Double)->Void)?, complete: ((Result<AVURLAsset, Error>)->Void)?) {
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
		options.isNetworkAccessAllowed = true
		options.version = PHVideoRequestOptionsVersion.original
        options.progressHandler = { (progress, error, stop, info) in
            progressUpdate?(progress)
        }
		
        PHImageManager.default().requestExportSession(forVideo: self.asset, options: options, exportPreset: exportPreset.aVAssetExportSessionPreset, resultHandler: { (session: AVAssetExportSession?, info: [AnyHashable : Any]?) in
			
			if let asset: AVURLAsset = session?.asset as? AVURLAsset {
				complete?(.success(asset))
			} else {
				complete?(.failure(ErrorType.exportSession))
			}
        })
    }

    public func getImageData(progressUpdate: ((_ progress: Double)->Void)?, complete: ((Result<Data, Error>)->Void)?) {
        let options: PHImageRequestOptions = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        //options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.progressHandler = {  (progress, error, stop, info) in
            progressUpdate?(progress)
        }

		PHImageManager.default().requestImageData(for: self.asset, options: options) { (data: Data?, st: String?, orientation: UIImage.Orientation, info: [AnyHashable : Any]?) in
			if let data: Data = data {
				complete?(.success(data))
			} else {
				complete?(.failure(ErrorType.exportSession))
			}

		}
    }
}

extension CCCameraRoll.Item {
    private func importVideoAsset(importURL: URL, exportPreset: Settings.PresetSize, progressUpdate: ((_ progress: Double)->Void)?, complete: @escaping ((_ status: CCCameraRoll.ImportStatus, _ asset: AVURLAsset?)->Void)) {
		let options: PHVideoRequestOptions = PHVideoRequestOptions()
		options.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
		options.isNetworkAccessAllowed = true
		options.version = PHVideoRequestOptionsVersion.original
		options.progressHandler = {  (progress, error, stop, info) in
			progressUpdate?(progress)
		}
		
		PHImageManager.default().requestExportSession(forVideo: self.asset, options: options, exportPreset: exportPreset.aVAssetExportSessionPreset, resultHandler: { (session: AVAssetExportSession?, info: [AnyHashable : Any]?) in
			guard let asset: AVURLAsset = session?.asset as? AVURLAsset else { complete( CCCameraRoll.ImportStatus.error, nil ); return }
			let url: URL = URL.init(fileURLWithPath: importURL.relativePath + "/" + asset.url.lastPathComponent)
			do {
				if FileManager.default.fileExists(atPath: url.relativePath) {
                    complete( CCCameraRoll.ImportStatus.exists, AVURLAsset.init(url: url) )
				} else {
					try FileManager.default.copyItem(at: asset.url, to: url)
					complete( CCCameraRoll.ImportStatus.success, AVURLAsset.init(url: url) )
				}
			} catch {
				complete( CCCameraRoll.ImportStatus.error, nil )
			}
		})
	}
}
