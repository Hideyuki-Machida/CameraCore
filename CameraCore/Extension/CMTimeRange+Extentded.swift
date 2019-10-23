//
//  CMTimeRange+Extentded.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/23.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

extension CMTimeRange {
	static public func convertTimeRange(timeRange: CMTimeRange, rate: Float64, timescale: CMTimeScale) -> CMTimeRange {
		let start: CMTime = CMTimeMultiplyByFloat64(timeRange.start, multiplier: rate).convertScale(timescale, method:.roundHalfAwayFromZero)
		let duration: CMTime = CMTimeMultiplyByFloat64(timeRange.duration, multiplier: rate).convertScale(timescale, method:.roundHalfAwayFromZero)
		let newTimeRange: CMTimeRange = CMTimeRange(start: start, duration: duration)
		return newTimeRange
	}
}

