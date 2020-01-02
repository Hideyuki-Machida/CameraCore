//
//  VideoCaptureViewProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation

public protocol VideoCaptureViewProtocol {
    var status: VideoCaptureView.Status { get }
    var capture: CCRenderer.VideoCapture.VideoCaptureManager? { get }
    var isRecording: Bool { get }

    var croppingRect: CGRect? { get set }
    var renderSize: CGSize? { get set }

    /////////////////////////////////////////////////
    // Event
    var event: VideoCaptureViewEvent? { get set }

    /////////////////////////////////////////////////
    // RenderLayers
    var renderLayers: [RenderLayerProtocol] { get set }

    /////////////////////////////////////////////////
    // Set
    func setup(_ property: CCRenderer.VideoCapture.Property) throws

    /////////////////////////////////////////////////
    // Capture Control
    func play()
    func pause()
    func dispose()

    /////////////////////////////////////////////////
    // Recording Control
    func recordingStart(_ parameter: CCRenderer.VideoCapture.CaptureWriter.Parameter) throws
    func recordingStop()
    func recordingCancelled()
}
