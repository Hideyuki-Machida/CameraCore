//
//  CustomOperator.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/01.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas

infix operator -->: AdditionPrecedence

@discardableResult
public func --> (camera: CCCapture.Camera, postProcess: CCRenderer.PostProcess) throws -> CCRenderer.PostProcess {
    return try postProcess.pipe.input(camera: camera)
}

@discardableResult
public func --> (camera: CCCapture.Camera, view: CCView) throws -> CCView {
    return try view.pipe.input(camera: camera)
}

@discardableResult
public func --> (camera: CCCapture.Camera, imageRecognition: CCVision.ImageRecognition) throws -> CCVision.ImageRecognition {
    return imageRecognition.pipe(camera: camera)
}

@discardableResult
public func --> (postProcess: CCRenderer.PostProcess, view: CCView) throws -> CCView {
    return try view.pipe.input(postProcess: postProcess)
}

/*
@discardableResult
public func --> (imageRecognition: CCVision.ImageRecognition, view: CCView) throws -> CCView {
    return try view.pipe(imageRecognition: imageRecognition)
}
*/

public func --> (camera: CCCapture.Camera, videoRecorder: CCRecorder.VideoRecorder) throws {
    try videoRecorder.pipe.input(camera: camera)
}

public func --> (postProcess: CCRenderer.PostProcess, videoRecorder: CCRecorder.VideoRecorder) throws {
    try videoRecorder.pipe.input(postProcess: postProcess)
}


@discardableResult
public func --> (audioEngine: CCAudio.AudioEngine, audioPlayer: CCAudio.AudioPlayer) throws -> CCAudio.AudioPlayer {
    var audioEngine: AVAudioEngine = audioEngine.engine
    return try audioPlayer.pipe(audioEngine: &audioEngine)
}

@discardableResult
public func --> (audioEngine: CCAudio.AudioEngine, audioMic: CCAudio.Mic) throws -> CCAudio.Mic {
    var audioEngine: AVAudioEngine = audioEngine.engine
    return try audioMic.pipe(audioEngine: &audioEngine)
}

public func --> (audioEngine: CCAudio.AudioEngine, videoRecorder: CCRecorder.VideoRecorder) throws {
    try videoRecorder.pipe(audioEngine: audioEngine)
}

public func --> (audioEngine: CCAudio.AudioEngine, audioRecorder: CCRecorder.AudioRecorder) throws {
    try audioRecorder.pipe(audioEngine: audioEngine)
}
