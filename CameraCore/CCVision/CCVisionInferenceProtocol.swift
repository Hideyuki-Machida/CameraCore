//
//  CCVisionInferenceProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/04/20.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation

// MARK: 推論処理 protocol

public protocol CCVisionInferenceProtocol {
    var id: CCImageProcess.RenderLayerId { get }
    mutating func dispose()
    mutating func process(pixelBuffer: CVPixelBuffer, timeStamp: CMTime, metadataObjects: [AVMetadataObject], userInfo: inout [String : Any]) throws
}
