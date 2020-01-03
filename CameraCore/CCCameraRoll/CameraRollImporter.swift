//
//  VideoImporter.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/08.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import Photos
import AVFoundation

extension CCCameraRoll {
    public final class Importer: NSObject {
        public var onProgress: ((_ progress: Double)->Void)?
        public var onComplete: ((_ status: Bool)->Void)?
        
        public func start(data: CCCameraRoll.Item, importPath: URL, exportPreset: Settings.PresetSize, outputFileType: AVFileType) {
            switch data.mediaType {
            case .video:
                self.video(importPath: importPath, data: data, exportPreset: exportPreset, outputFileType: outputFileType)
            case .image: break
            case .audio: break
            case .unknown: break
            @unknown default: break
            }
        }

        public func start(mediaType: CCCameraRoll.AssetType, asset: AVURLAsset, importPath: URL, exportPreset: Settings.PresetSize, outputFileType: AVFileType) {
            switch mediaType {
            case .video:
                self.video(asset: asset, importPath: importPath, exportPreset: exportPreset, outputFileType: outputFileType)
            case .image: break
            case .audio: break
            case .unknown: break
            }
        }
        
        private func video(importPath: URL, data: CCCameraRoll.Item, exportPreset: Settings.PresetSize, outputFileType: AVFileType) {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
            options.isNetworkAccessAllowed = true
            options.progressHandler = {  (progress, error, stop, info) in
                DispatchQueue.main.async { [weak self] in
                    self?.onProgress?(progress)
                }
            }
            
            PHImageManager.default().requestExportSession(forVideo: data.asset, options: options, exportPreset: exportPreset.aVAssetExportSessionPreset, resultHandler: { [weak self] (session: AVAssetExportSession?, info: [AnyHashable : Any]?) in
                
                guard let exportSession: AVAssetExportSession = session else { return }
                exportSession.outputFileType = outputFileType
                exportSession.outputURL = importPath
                exportSession.exportAsynchronously(completionHandler: { [weak self] in
                    switch exportSession.status {
                    case .completed:
                        Debug.SuccessLog("importPHAsset: completed")
                        self?.onComplete?(true)
                    case .waiting:
                        Debug.ErrorLog("importPHAsset: waiting")
                    case .unknown:
                        Debug.ErrorLog("importPHAsset: unknown")
                    case .exporting:
                        Debug.ErrorLog("importPHAsset: exporting")
                    case .cancelled:
                        Debug.ErrorLog("importPHAsset: cancelled")
                        self?.onComplete?(false)
                    case .failed:
                        Debug.ErrorLog("importPHAsset: failed")
                        self?.onComplete?(false)
                    @unknown default:
                        self?.onComplete?(false)
                    }
                })
                
            })
        }
        
        private func video(asset: AVURLAsset, importPath: URL, exportPreset: Settings.PresetSize, outputFileType: AVFileType) {
            guard let exportSession: AVAssetExportSession = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetPassthrough) else { self.onComplete?(true); return }
            exportSession.outputFileType = outputFileType
            exportSession.outputURL = importPath
            exportSession.exportAsynchronously(completionHandler: { [weak self] in
                switch exportSession.status {
                case .completed:
                    Debug.SuccessLog("importPHAsset: completed")
                    self?.onComplete?(true)
                case .waiting:
                    Debug.ErrorLog("importPHAsset: waiting")
                case .unknown:
                    Debug.ErrorLog("importPHAsset: unknown")
                case .exporting:
                    Debug.ErrorLog("importPHAsset: exporting")
                case .cancelled:
                    Debug.ErrorLog("importPHAsset: cancelled")
                    self?.onComplete?(false)
                case .failed:
                    Debug.ErrorLog("importPHAsset: failed")
                    self?.onComplete?(false)
                @unknown default:
                    self?.onComplete?(false)
                }
            })
        }

    }
}
