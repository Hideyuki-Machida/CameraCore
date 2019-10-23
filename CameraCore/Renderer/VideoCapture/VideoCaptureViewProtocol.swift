//
//  VideoCaptureViewProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public protocol VideoCaptureViewProtocol {
    var status: VideoCaptureStatus { get }
    var capture: Renderer.VideoCapture.VideoCapture? { get }
    var isRecording: Bool  { get }

    var croppingRect: CGRect? { get set }
    var renderSize: CGSize? { get set }
    
    /////////////////////////////////////////////////
    // Event
    var event: VideoCaptureViewEvent? { get set }

    /////////////////////////////////////////////////
    // RenderLayers
    var renderLayers: [RenderLayerProtocol]  { get set }
    
    /////////////////////////////////////////////////
    // Set
    func setup(frameRate: Int32, presetiFrame: Settings.PresetiFrame, position: AVCaptureDevice.Position) throws
    
    /////////////////////////////////////////////////
    // Capture Control
    func play()
    func pause()
    func dispose()

    /////////////////////////////////////////////////
    // Recording Control
    func recordingStart(_ paramator: Renderer.VideoCapture.CaptureWriter.Paramator) throws
    func recordingStop()
    func recordingCancelled()
}
