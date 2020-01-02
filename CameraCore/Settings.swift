//
//  Settings.swift
//  CameraCore
//
//  Created by machidahideyuki on 2018/01/08.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas
import UIKit

public class Settings {
    public enum PresetSize: Int, Codable {
        // case p640x480 = 0 現状は使用しない
        case p960x540 = 1
        case p1280x720 = 2
        case p1920x1080 = 3

        public var aVCaptureSessionPreset: AVCaptureSession.Preset {
            switch self {
            // case .p640x480: return AVCaptureSession.Preset.vga640x480
            case .p960x540: return AVCaptureSession.Preset.iFrame960x540
            case .p1280x720: return AVCaptureSession.Preset.iFrame1280x720
            case .p1920x1080: return AVCaptureSession.Preset.hd1920x1080
            }
        }

        public var aVAssetExportSessionPreset: String {
            switch self {
            // case .p640x480: return AVAssetExportPreset640x480
            case .p960x540: return AVAssetExportPreset960x540
            case .p1280x720: return AVAssetExportPreset1280x720
            case .p1920x1080: return AVAssetExportPreset1920x1080
            }
        }

        public var aVAssetExportSessionHEVCPreset: String {
            switch self {
            // case .p640x480: return AVAssetExportPreset640x480
            case .p960x540: return AVAssetExportPreset960x540
            case .p1280x720: return AVAssetExportPreset1280x720
            case .p1920x1080: return AVAssetExportPresetHEVC1920x1080
            }
        }

        public func size(orientation: AVCaptureVideoOrientation) -> CGSize {
            switch orientation {
            case .portrait, .portraitUpsideDown: return self.portraitSize
            case .landscapeLeft, .landscapeRight: return self.landscapeSize
            @unknown default: return self.portraitSize
            }
        }

        public func size(isOrientation: Bool = true) -> CGSize {
            if isOrientation {
                let currentOrientation: AVCaptureVideoOrientation = Settings.captureVideoOrientation
                return size(orientation: currentOrientation)
            } else {
                return self.landscapeSize
            }
        }

        fileprivate var portraitSize: CGSize {
            switch self {
            // case .p640x480: return CGSize(width: 480, height: 640)
            case .p960x540: return CGSize(width: 540, height: 960)
            case .p1280x720: return CGSize(width: 720, height: 1280)
            case .p1920x1080: return CGSize(width: 1080, height: 1920)
            }
        }

        fileprivate var landscapeSize: CGSize {
            switch self {
            // case .p640x480: return CGSize(width: 640, height: 480)
            case .p960x540: return CGSize(width: 960, height: 540)
            case .p1280x720: return CGSize(width: 1280, height: 720)
            case .p1920x1080: return CGSize(width: 1920, height: 1080)
            }
        }
    }

    public enum PresetFrameRate: Int32 {
        case fps15 = 15
        case fps24 = 24
        case fps30 = 30
        case fps60 = 60
        case fps90 = 90
        case fps120 = 120
        case fps240 = 240
    }

    public enum VideoCodec {
        case h264
        case hevc
        /* 現状は使用しない
         case proRes422
         case proRes4444
         case jpg
         */
        public var val: AVVideoCodecType {
            switch self {
            case .h264: return AVVideoCodecType.h264
            case .hevc: return MetalCanvas.MCTools.shard.hasHEVCHardwareEncoder ? AVVideoCodecType.hevc : AVVideoCodecType.h264
            }
        }
    }

    public enum RenderType: Int, Codable {
        case openGL = 0
        case metal = 1
    }

    private static var stockCaptureVideoOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
    public static var captureVideoOrientation: AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .unknown: break
        case .portrait: self.stockCaptureVideoOrientation = AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown: break
        case .landscapeLeft: self.stockCaptureVideoOrientation = AVCaptureVideoOrientation.landscapeRight
        case .landscapeRight: self.stockCaptureVideoOrientation = AVCaptureVideoOrientation.landscapeLeft
        case .faceUp: break
        case .faceDown: break
        @unknown default: break
        }
        return self.stockCaptureVideoOrientation
    }
}
