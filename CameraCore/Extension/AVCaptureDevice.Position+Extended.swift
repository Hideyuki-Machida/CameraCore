//
//  AVCaptureDevice.Position+Extended.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/10/23.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation

extension AVCaptureDevice.Position {
	var toString: String {
		switch self {
		case .back: return "back"
		case .front: return "front"
		case .unspecified: return "unspecified"
		@unknown default: return "unspecified"
		}
	}
}
