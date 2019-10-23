//
//  CompositionAVPlayerProtocol.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/08/21.
//  Copyright © 2018年 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public enum CompositionAVPlayerStatus {
    case setup
    case update
    case ready
    case play
    case pause
    case seek
    case dispose
    case endTime
}

public enum CompositionAVPlayerErrorType: Error {
    case setupError
}

public protocol CompositionAVPlayerProtocol {
    /////////////////////////////////////////////////
    // Event Enum
    associatedtype PlayerStatus = CompositionAVPlayerStatus
    
    /////////////////////////////////////////////////
    // ErrorType Enum
    associatedtype ErrorType = CompositionAVPlayerErrorType

	var curentTime: (time: Double, duration: Double)? {get}
	
    /////////////////////////////////////////////////
    // Events
    var event: Renderer.CompositionAVPlayerEvent? {get set}
    //var onStatusChange: ((_ status: PlayerStatus)->Void)? {get set}
    //var onFrameUpdate: ((_ time: Float64, _ duration: Float64)->Void)? {get set}
    var onPixelUpdate: ((_ pixelBuffer: CVPixelBuffer)->Void)? {get set}
    //var onPreviewFinish: (()->Void)? {get set}
    
    /////////////////////////////////////////////////
    // Set & Update CompositionData
    func setup(compositionData: CompositionDataProtocol) throws
    func updateAll(compositionData: CompositionDataProtocol) throws
    func updateRenderLayer(compositionData: CompositionDataProtocol) throws
    
    /////////////////////////////////////////////////
    // Control
    func play(isRepeat: Bool)
    func replay(isRepeat: Bool)
    func pause()
    func seek(time: CMTime)
    func seek(percent: Float)
    
    /////////////////////////////////////////////////
    // Dispose
    func dispose()
}
