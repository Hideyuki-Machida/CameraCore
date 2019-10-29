//
//  VideoCaputureProperty.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/10/20.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas

extension CCRenderer.VideoCapture {
    public enum Property {
        case captureSize(Settings.PresetSize)
        case frameRate(Settings.PresetFrameRate)
        case colorSpace(AVCaptureColorSpace)
        case videoHDR(Bool)
        case isSmoothAutoFocusEnabled(Bool)
        case isDepthDataOut(Bool)
        
        public var rawValue: Int {
            switch self {
            case .captureSize: return 0
            case .frameRate: return 1
            case .colorSpace: return 2
            case .videoHDR: return 3
            case .isSmoothAutoFocusEnabled: return 4
            case .isDepthDataOut: return 100
            }
        }
    }

    public class PropertysInfo {
        let traceQueue: DispatchQueue = DispatchQueue(label: "CCRenderer.VideoCapture.PropertysInfo.Queue")
        
        public var device: AVCaptureDevice?
        public var deviceFormat: AVCaptureDevice.Format?
        public var deviceType: AVCaptureDevice.DeviceType?
        public var presetSize: Settings.PresetSize = Settings.PresetSize.p1280x720
        public var captureSize: CGSize = Settings.PresetSize.p1280x720.size()
        public var devicePosition: AVCaptureDevice.Position = .back
        public var frameRate: Int32 = 30
        public var colorSpace: AVCaptureColorSpace = .sRGB
        public var videoHDR: Bool?
        public var isSmoothAutoFocusEnabled: Bool = true
        public var isDepthDataOut: Bool = false
        
        func update(device: AVCaptureDevice, deviceFormat: AVCaptureDevice.Format, propertyList: [Property]) {
            self.device = device
            self.deviceFormat = deviceFormat
            for property in propertyList {
                switch property {
                case .captureSize(let captureSize):
                    self.presetSize = captureSize
                    let w: Int32 = CMVideoFormatDescriptionGetDimensions(deviceFormat.formatDescription).width
                    let h: Int32 = CMVideoFormatDescriptionGetDimensions(deviceFormat.formatDescription).height
                    self.captureSize = CGSize.init(width: CGFloat(w), height: CGFloat(h))
                case .frameRate(let frameRate):
                    var resultFrameRate: Int32 = 1
                    for videoSupportedFrameRateRange: Any in deviceFormat.videoSupportedFrameRateRanges {
                        guard let range: AVFrameRateRange = videoSupportedFrameRateRange as? AVFrameRateRange else { continue }
                        if range.minFrameRate <= Float64(frameRate.rawValue) && Float64(frameRate.rawValue) <= range.maxFrameRate {
                            resultFrameRate = frameRate.rawValue
                            break
                        } else if range.minFrameRate >= Float64(frameRate.rawValue) && Float64(frameRate.rawValue) <= range.maxFrameRate {
                            resultFrameRate = Int32(range.minFrameRate)
                            continue
                        } else if range.minFrameRate <= Float64(frameRate.rawValue) && Float64(frameRate.rawValue) >= range.maxFrameRate {
                            resultFrameRate = Int32(range.maxFrameRate)
                            continue
                        }
                    }
                    self.frameRate = resultFrameRate
                case .colorSpace(let colorSpace):
                    let colorSpaces: [AVCaptureColorSpace] = deviceFormat.supportedColorSpaces.filter { $0 == colorSpace }
                    guard let colorSpace: AVCaptureColorSpace = colorSpaces.first else { break }
                    self.colorSpace = colorSpace
                case .videoHDR(_):
                    self.videoHDR = deviceFormat.isVideoHDRSupported
                case .isSmoothAutoFocusEnabled(let on):
                    self.isSmoothAutoFocusEnabled = (on && device.isSmoothAutoFocusSupported) ? true : false
                case .isDepthDataOut(let on):
                    let isData: Bool = (deviceFormat.supportedDepthDataFormats.filter { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat32 }).count >= 1
                    self.isDepthDataOut = (on && isData) ? true : false
                }
            }
            
            self.traceQueue.async { [weak self] () in
                self?.trace()
            }
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
            MCDebug.log("isDepthDataOut: \(self.isDepthDataOut)")
            MCDebug.log("----------------------------------------------------")
        }
    }

    public class Propertys {
        public var devicePosition: AVCaptureDevice.Position
        public var deviceType: AVCaptureDevice.DeviceType
        public var isAudioDataOutput: Bool
        public var required: [Property]
        public var option: [Property]
        public var info: PropertysInfo = PropertysInfo()

        fileprivate var requiredCaptureSize: CGSize? = nil
        
        public init(devicePosition: AVCaptureDevice.Position = .back, deviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, isAudioDataOutput: Bool = true, required: [Property] = [], option: [Property] = []) {
            self.devicePosition = devicePosition
            self.deviceType = deviceType
            self.isAudioDataOutput = isAudioDataOutput
            self.required = required
            self.option = option
        }
    }
}

extension CCRenderer.VideoCapture.Propertys {
    func getDevice(position: AVCaptureDevice.Position, deviceType: AVCaptureDevice.DeviceType, mediaType: AVMediaType = AVMediaType.video) throws -> AVCaptureDevice {
        func setDeviceInfo(device: AVCaptureDevice) {
            self.info.device = device
            self.info.devicePosition = device.position
            self.info.deviceType = device.deviceType
        }
        
        switch position {
        case .front:
            if let device: AVCaptureDevice = AVCaptureDevice.default(deviceType, for: mediaType, position: position) {
                setDeviceInfo(device: device)
                return device
            }
        case .back:
            if let device: AVCaptureDevice = AVCaptureDevice.default(deviceType, for: mediaType, position: position) {
                setDeviceInfo(device: device)
                return device
            }
        case .unspecified:
            throw CCRenderer.VideoCapture.ErrorType.setupError
        @unknown default: break
        }

        MCDebug.errorLog("DeviceType Error: \(deviceType) -> builtInWideAngleCamera")
        if let device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: mediaType, position: position) {
            setDeviceInfo(device: device)
            return device
        } else if let device: AVCaptureDevice = AVCaptureDevice.default(for: mediaType) {
            setDeviceInfo(device: device)
            return device
        }

        throw CCRenderer.VideoCapture.ErrorType.setupError
    }
}

extension CCRenderer.VideoCapture.Propertys {
    public func setup() throws {
        let captureDevice: AVCaptureDevice = try self.getDevice(position: self.devicePosition, deviceType: self.deviceType)
        let formats: [AVCaptureDevice.Format] = captureDevice.formats.filter({ $0.mediaType == .video })

        guard formats.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
        var resultFormats: [AVCaptureDevice.Format] = formats

        //////////////////////////////////////////////////////////
        // 必須のパラメータを設定
        let required: [CCRenderer.VideoCapture.Property] = self.required
        self.requiredCaptureSize = nil
        for property in required {
            resultFormats = try self.filterProperty(property: property, captureDevice: captureDevice, formats: resultFormats, required: true)
        }
        guard resultFormats.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
        //////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////
        // オプションのパラメータを設定
        let option: [CCRenderer.VideoCapture.Property] = self.option
        for property in option {
            do {
                resultFormats = try self.filterProperty(property: property, captureDevice: captureDevice, formats: resultFormats, required: false)
            } catch {
                MCDebug.errorLog("Option Error: \(property)")
            }
        }
        //////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////
        // 解像度によりフォーマットを振り分け
        let resultFormat: AVCaptureDevice.Format
        if let requiredCaptureSize: CGSize = self.requiredCaptureSize {
            // 解像度ジャストサイズのものを選択
            guard let format: AVCaptureDevice.Format = (resultFormats.filter { CMVideoFormatDescriptionGetDimensions($0.formatDescription).width == Int32(requiredCaptureSize.width) }).first else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            resultFormat = format
        } else {
            // 解像度最小のもの
            guard let format: AVCaptureDevice.Format = resultFormats.min(by: { first, second in
                CMVideoFormatDescriptionGetDimensions(first.formatDescription).width > CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
            })
            else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            resultFormat = format
        }
        //////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////
        // PropertysInfoを設定
        self.info.update(device: captureDevice, deviceFormat: resultFormat, propertyList: self.required + self.option)
        //////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////
        self.info.deviceFormat = resultFormat
        //////////////////////////////////////////////////////////
    }

    func filterProperty(property: CCRenderer.VideoCapture.Property, captureDevice: AVCaptureDevice, formats: [AVCaptureDevice.Format], required: Bool) throws -> [AVCaptureDevice.Format] {
        switch property {
        case .captureSize(let captureSize):
            if required {
                self.requiredCaptureSize = captureSize.size(isOrientation: false)
            }
            let width: CGFloat = captureSize.size().height
            let height: CGFloat = captureSize.size().width

            var list: [AVCaptureDevice.Format] = []
            for format: AVCaptureDevice.Format in formats {
                let maxWidth: Int32 = CMVideoFormatDescriptionGetDimensions(format.formatDescription).width
                let maxHeight: Int32 = CMVideoFormatDescriptionGetDimensions(format.formatDescription).height
                
                let g: CGFloat = self.gcd(x: CGFloat(maxWidth), y: CGFloat(maxHeight)) // 最大公約数
                if width <= CGFloat(maxWidth) && height <= CGFloat(maxHeight) && (CGFloat(maxWidth) / g) == 16.0 && (CGFloat(maxHeight) / g) == 9.0 {
                    list.append(format)
                }
            }

            guard list.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            return list
        case .frameRate(let frameRate):
            var list: [AVCaptureDevice.Format] = []
            for format: AVCaptureDevice.Format in formats {
                for videoSupportedFrameRateRange: Any in format.videoSupportedFrameRateRanges {
                    guard let range: AVFrameRateRange = videoSupportedFrameRateRange as? AVFrameRateRange else { continue }
                    if range.minFrameRate <= Float64(frameRate.rawValue) && Float64(frameRate.rawValue) <= range.maxFrameRate {
                        list.append(format)
                    }
                }
            }

            guard list.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            return list
        case .colorSpace(let colorSpace):
            let list: [AVCaptureDevice.Format] = formats.filter {
                let colorSpaces: [AVCaptureColorSpace] = $0.supportedColorSpaces.filter { $0 == colorSpace }
                return colorSpaces.count >= 1
            }

            guard list.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            return list
        case .videoHDR(let on):
            if on {
                let list: [AVCaptureDevice.Format] = formats.filter { $0.isVideoHDRSupported == true }

                guard list.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
                return list
            } else {
                if required {
                    let list: [AVCaptureDevice.Format] = formats.filter { $0.isVideoHDRSupported == false }
                    guard list.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
                    return list
                }
                return formats
            }
        case .isSmoothAutoFocusEnabled(let on):
            if on && required {
                if captureDevice.isSmoothAutoFocusSupported {
                    throw CCRenderer.VideoCapture.ErrorType.setupError
                }
            }
            return formats

        case .isDepthDataOut(let on):
            if on {
                let list: [AVCaptureDevice.Format] = formats.filter { ($0.supportedDepthDataFormats.filter { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat32 }).count >= 1 }
                guard list.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
                return list
            } else {
                return formats
            }
        }
    }
}

extension CCRenderer.VideoCapture.Propertys {
    public func swap(property: CCRenderer.VideoCapture.Property) throws {
        var isUpdate: Bool = false
        func map(prop: CCRenderer.VideoCapture.Property) -> CCRenderer.VideoCapture.Property {
            if prop.rawValue == property.rawValue {
                isUpdate = true
                return property
            } else {
                return prop
            }
        }
        self.required = self.required.map { map(prop: $0) }
        self.option = self.option.map { map(prop: $0) }
        
        if !isUpdate {
            throw CCRenderer.VideoCapture.ErrorType.setupError
        }
    }
}

extension CCRenderer.VideoCapture.Propertys {
    private func gcd(x: Float, y: Float) -> Float {
        if(y == 0) { return x }
        return gcd(x: y, y: x.truncatingRemainder(dividingBy: y))
    }
    private func gcd(x: CGFloat, y: CGFloat) -> CGFloat {
        if(y == 0) { return x }
        return gcd(x: y, y: x.truncatingRemainder(dividingBy: y))
    }
}
