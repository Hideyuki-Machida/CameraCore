//
//  CaptureInfo.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/12/28.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas

extension CCCapture.VideoCapture {
    public class CaptureInfo {
        private let traceQueue: DispatchQueue = DispatchQueue(label: "CCCapture.VideoCapture.CaptureInfo.Queue")

        public private(set) var device: AVCaptureDevice?
        public private(set) var deviceFormat: AVCaptureDevice.Format?
        public private(set) var deviceType: AVCaptureDevice.DeviceType?
        public private(set) var presetSize: Settings.PresetSize = Settings.PresetSize.p1280x720
        public private(set) var captureSize: MCSize = Settings.PresetSize.p1280x720.size(orientation: Configuration.shared.currentUIInterfaceOrientation)
        public private(set) var devicePosition: AVCaptureDevice.Position = .back
        public private(set) var frameRate: Int32 = 30
        public private(set) var colorSpace: AVCaptureColorSpace = .sRGB
        public private(set) var outPutPixelFormatType: MCPixelFormatType = MCPixelFormatType.kCV32BGRA
        public private(set) var videoHDR: Bool?
        public private(set) var isSmoothAutoFocusEnabled: Bool = true
        public private(set) var depthDataOut: Bool = false

        func updateAr() {
            self.captureSize = MCSize.init(1920, 1440)
            self.frameRate = 60
            self.outPutPixelFormatType = MCPixelFormatType.kCV420YpCbCr8BiPlanarFullRange
        }
        
        func update(device: AVCaptureDevice, deviceFormat: AVCaptureDevice.Format, outPutPixelFormatType: MCPixelFormatType, itemList: [CCCapture.VideoCapture.Property.Item]) {
            self.device = device
            self.devicePosition = device.position
            self.deviceFormat = deviceFormat
            self.outPutPixelFormatType = outPutPixelFormatType
            for item in itemList {
                switch item {
                case let .captureSize(captureSize):
                    self.presetSize = captureSize
                    let w: Int32 = CMVideoFormatDescriptionGetDimensions(deviceFormat.formatDescription).width
                    let h: Int32 = CMVideoFormatDescriptionGetDimensions(deviceFormat.formatDescription).height
                    self.captureSize = MCSize(w: CGFloat(w), h: CGFloat(h))
                case let .frameRate(frameRate):
                    self.frameRate = self.frameRate(frameRate: frameRate, deviceFormat: deviceFormat)
                case let .colorSpace(colorSpace):
                    let colorSpaces: [AVCaptureColorSpace] = deviceFormat.supportedColorSpaces.filter { $0 == colorSpace }
                    guard let colorSpace: AVCaptureColorSpace = colorSpaces.first else { break }
                    self.colorSpace = colorSpace
                case .videoHDR:
                    self.videoHDR = deviceFormat.isVideoHDRSupported
                case let .isSmoothAutoFocusEnabled(on):
                    self.isSmoothAutoFocusEnabled = (on && device.isSmoothAutoFocusSupported) ? true : false
                }
            }

            self.traceQueue.async { [weak self] () in
                self?.trace()
            }
        }

        private func frameRate(frameRate: Settings.PresetFrameRate, deviceFormat: AVCaptureDevice.Format) -> Int32 {
            var resultFrameRate: Int32 = 1
            for videoSupportedFrameRateRange: Any in deviceFormat.videoSupportedFrameRateRanges {
                guard let range: AVFrameRateRange = videoSupportedFrameRateRange as? AVFrameRateRange else { continue }
                if range.minFrameRate <= Float64(frameRate.rawValue), Float64(frameRate.rawValue) <= range.maxFrameRate {
                    // MAX・MINともにレンジに収まっている
                    resultFrameRate = frameRate.rawValue
                    break
                } else if range.minFrameRate > Float64(frameRate.rawValue), Float64(frameRate.rawValue) <= range.maxFrameRate {
                    // MAXはレンジに収まっているがMINよりも小さい
                    resultFrameRate = Int32(range.minFrameRate)
                    continue
                } else if range.minFrameRate <= Float64(frameRate.rawValue), Float64(frameRate.rawValue) > range.maxFrameRate {
                    // MINはレンジに収まっているがMAXよりも大きい
                    resultFrameRate = Int32(range.maxFrameRate)
                    continue
                }
            }
            return resultFrameRate
        }

        func trace() {
            MCDebug.log("----------------------------------------------------")
            MCDebug.log("■ deviceInfo")
            if let device: AVCaptureDevice = self.device {
                MCDebug.log("device: \(device)")
            }
            if let deviceFormat: AVCaptureDevice.Format = self.deviceFormat {
                MCDebug.log("deviceFormat: \(deviceFormat)")
                MCDebug.log("videoHDR: \(deviceFormat.isVideoHDRSupported)")
            }
            MCDebug.log("deviceType: \(String(describing: self.deviceType))")
            MCDebug.log("captureSize: \(self.captureSize)")
            MCDebug.log("frameRate: \(self.frameRate)")
            MCDebug.log("devicePosition: \(self.devicePosition.toString)")
            MCDebug.log("colorSpace: \(self.colorSpace.toString)")
            MCDebug.log("isSmoothAutoFocusEnabled: \(self.isSmoothAutoFocusEnabled)")
            MCDebug.log("----------------------------------------------------")
        }
    }
}

