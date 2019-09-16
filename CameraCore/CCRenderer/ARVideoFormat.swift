//
//  ARVideoFormat.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/01/05.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation
import ARKit

extension CCRenderer {
	public enum ARVideoFormat {
		case p1280x720
		case p1920x1080
		case p1920x1440
		
		public var size: CGSize {
			switch self {
			case .p1280x720: return CGSize.init(width: 720, height: 1280)
			case .p1920x1080: return CGSize.init(width: 1080, height: 1920)
			case .p1920x1440: return CGSize.init(width: 1440, height: 1920)
			}
		}
		
		var imageResolution: CGSize {
			switch self {
			case .p1280x720: return CGSize.init(width: 1280, height: 720)
			case .p1920x1080: return CGSize.init(width: 1920, height: 1080)
			case .p1920x1440: return CGSize.init(width: 1920, height: 1440)
			}
		}
		
	}
}
