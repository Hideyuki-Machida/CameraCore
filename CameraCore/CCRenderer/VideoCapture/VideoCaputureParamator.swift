//
//  VideoCaputureParamator.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/09/21.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation

extension CCRenderer.VideoCapture {
	public struct VideoCaputureParamator {
		public var presetiFrame: Settings.PresetiFrame
		public var frameRate: Int32
		public var devicePosition: AVCaptureDevice.Position
		public var isDepth: Bool
		public init (presetiFrame: Settings.PresetiFrame, frameRate: Int32, devicePosition: AVCaptureDevice.Position, isDepth: Bool) {
			self.presetiFrame = presetiFrame
			self.frameRate = frameRate
			self.devicePosition = devicePosition
			self.isDepth = isDepth
		}
	}
}
