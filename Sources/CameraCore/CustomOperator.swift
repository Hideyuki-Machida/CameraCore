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


// MARK: - infix operator

infix operator -->: AdditionPrecedence


// MARK: - CCImageProcess.ImageProcess

@discardableResult
public func --> (camera: CCCapture.Camera, imageProcess: CCImageProcess.ImageProcess) throws -> CCImageProcess.ImageProcess {
    return try imageProcess.pipe.input(camera: camera)
}

@discardableResult
public func --> (player: CCPlayer, imageProcess: CCImageProcess.ImageProcess) throws -> CCImageProcess.ImageProcess {
    return try imageProcess.pipe.input(player: player)
}

@discardableResult
@available(iOS 13.0, *)
public func --> (camera: CCARCapture.cARCamera, imageProcess: CCImageProcess.ImageProcess) throws -> CCImageProcess.ImageProcess {
    return try imageProcess.pipe.input(camera: camera)
}

@discardableResult
public func --> (inference: CCVision.Inference, imageProcess: CCImageProcess.ImageProcess) throws -> CCImageProcess.ImageProcess {
    return try imageProcess.pipe.input(inference: inference)
}


// MARK: - CCVision.Inference

@discardableResult
public func --> (camera: CCCapture.Camera, imageRecognition: CCVision.Inference) throws -> CCVision.Inference {
    return try imageRecognition.pipe.input(camera: camera)
}

@discardableResult
public func --> (player: CCPlayer, inference: CCVision.Inference) throws -> CCVision.Inference {
    return try inference.pipe.input(player: player)
}


// MARK: - CCView

public func --> (camera: CCCapture.Camera, view: CCView) throws {
    try view.pipe.input(camera: camera)
}

@available(iOS 13.0, *)
public func --> (camera: CCARCapture.cARCamera, view: CCView) throws {
    try view.pipe.input(camera: camera)
}

public func --> (imageProcess: CCImageProcess.ImageProcess, view: CCView) throws {
    try view.pipe.input(imageProcess: imageProcess)
}

public func --> (player: CCPlayer, view: CCView) throws {
    try view.pipe.input(player: player)
}


// MARK: - CCRecorder.VideoRecorder

public func --> (camera: CCCapture.Camera, videoRecorder: CCRecorder.VideoRecorder) throws {
    try videoRecorder.pipe.input(camera: camera)
}

public func --> (imageProcess: CCImageProcess.ImageProcess, videoRecorder: CCRecorder.VideoRecorder) throws {
    try videoRecorder.pipe.input(imageProcess: imageProcess)
}

public func --> (audioEngine: CCAudio.AudioEngine, videoRecorder: CCRecorder.VideoRecorder) throws {
    try videoRecorder.pipe(audioEngine: audioEngine)
}




@discardableResult
public func --> (audioEngine: CCAudio.AudioEngine, audioRecorder: CCRecorder.AudioRecorder) throws {
    try audioRecorder.pipe(audioEngine: audioEngine)
}





/*
@discardableResult
public func --> (imageRecognition: CCVision.ImageRecognition, view: CCView) throws -> CCView {
    return try view.pipe(imageRecognition: imageRecognition)
}
*/




@discardableResult
public func --> (audioEngine: CCAudio.AudioEngine, audioPlayer: CCAudio.AudioPlayer) throws -> CCAudio.AudioPlayer {
    var audioEngine: CCAudio.AudioEngine = audioEngine
    return try audioPlayer.pipe.input(audioEngine: &audioEngine)
}

@discardableResult
public func --> (audioEngine: CCAudio.AudioEngine, audioMic: CCAudio.Mic) throws -> CCAudio.Mic {
    var audioEngine: AVAudioEngine = audioEngine.engine
    return try audioMic.pipe(audioEngine: &audioEngine)
}


