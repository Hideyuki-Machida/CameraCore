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
        public var isAudioDataOutput: Bool
		public var isDepthDataOutput: Bool
        public init (presetiFrame: Settings.PresetiFrame, frameRate: Int32, devicePosition: AVCaptureDevice.Position, isAudioDataOutput: Bool = true, isDepthDataOutput: Bool = false) {
			self.presetiFrame = presetiFrame
			self.frameRate = frameRate
			self.devicePosition = devicePosition
            self.isAudioDataOutput = isAudioDataOutput
			self.isDepthDataOutput = isDepthDataOutput
		}
	}
}
