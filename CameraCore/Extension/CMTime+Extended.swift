//
//  CMTime+Extended.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/08/21.
//  Copyright © 2018年 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

extension CMTime {
    public static func + (left: CMTime, right: CMTimeValue) -> CMTime {
        return CMTime.init(value: left.value + right, timescale: left.timescale)
    }

    public static func - (left: CMTime, right: CMTimeValue) -> CMTime {
        return CMTime.init(value: left.value - right, timescale: left.timescale)
    }

    public static func * (left: CMTime, right: CMTimeValue) -> CMTime {
        return CMTime.init(value: left.value * right, timescale: left.timescale)
    }

    public static func / (left: CMTime, right: CMTimeValue) -> CMTime {
        return CMTime.init(value: left.value / right, timescale: left.timescale)
    }
    }

    extension CMTime {
    public static func + (left: CMTimeValue, right: CMTime) -> CMTime {
        return CMTime.init(value: left + right.value, timescale: right.timescale)
    }

    public static func - (left: CMTimeValue, right: CMTime) -> CMTime {
        return CMTime.init(value: left - right.value, timescale: right.timescale)
    }

    public static func * (left: CMTimeValue, right: CMTime) -> CMTime {
        return CMTime.init(value: left * right.value, timescale: right.timescale)
    }

    public static func / (left: CMTimeValue, right: CMTime) -> CMTime {
        return CMTime.init(value: left / right.value, timescale: right.timescale)
    }
}
