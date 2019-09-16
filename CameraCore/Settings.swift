//
//  Settings.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/08.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public class Settings {
    public enum PresetiFrame: Int, Codable {
		case p1920x1080 = 0
		case p1280x720 = 1
		case p960x540 = 2
		
		public func aVCaptureSessionPreset() -> String  {
			switch self {
			case .p1920x1080: return AVCaptureSession.Preset.hd1920x1080.rawValue
			case .p1280x720: return AVCaptureSession.Preset.iFrame1280x720.rawValue
			case .p960x540: return AVCaptureSession.Preset.iFrame960x540.rawValue
			}
		}
		public func aVAssetExportSessionPreset() -> String  {
			switch self {
			case .p1920x1080: return AVAssetExportPreset1920x1080
			case .p1280x720: return AVAssetExportPreset1280x720
			case .p960x540: return AVAssetExportPreset960x540
			}
		}
		public func aVAssetExportSessionHEVCPreset() -> String  {
			switch self {
			case .p1920x1080:
				if #available(iOS 11.0, *) {
					return AVAssetExportPresetHEVC1920x1080
				} else {
					return AVAssetExportPreset1920x1080
				}
			case .p1280x720: return AVAssetExportPreset1280x720
			case .p960x540: return AVAssetExportPreset960x540
			}
		}
		
		public func size() -> CGSize  {
			switch self {
			case .p1920x1080: return CGSize(width: 1080, height: 1920)
			case .p1280x720: return CGSize(width: 720, height: 1280)
			case .p960x540: return CGSize(width: 540, height: 960)
			}
		}
	}
    
    public enum VideoCodec {
        case h264
        case hevc
        /*
        case proRes422
        case proRes4444
        case jpg
        */
        public var val: AVVideoCodecType {
            get {
                switch self {
				case .h264: return AVVideoCodecType.h264
                case .hevc:
                    if #available(iOS 11.0, *), CameraCore.Tools.hasHEVCHardwareEncoder == true {
						return AVVideoCodecType.hevc
                    } else {
						return AVVideoCodecType.h264
                    }
                }
            }
        }
    }
    
	public enum RenderType: Int, Codable {
		case openGL = 0
		case metal = 1
	}
	
}
