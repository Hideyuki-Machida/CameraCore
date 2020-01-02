//
//  VideoCaptureProperty.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/10/20.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas

extension CCRenderer.VideoCapture {
    public class Property {
        // swiftlint:disable:next nesting
        public enum Item {
            // swiftlint:disable:previous nesting
            case captureSize(Settings.PresetSize)
            case frameRate(Settings.PresetFrameRate)
            case colorSpace(AVCaptureColorSpace)
            case videoHDR(Bool)
            case isSmoothAutoFocusEnabled(Bool)

            fileprivate var rawValue: Int {
                switch self {
                case .captureSize: return 0
                case .frameRate: return 1
                case .colorSpace: return 2
                case .videoHDR: return 3
                case .isSmoothAutoFocusEnabled: return 4
                }
            }

            static func == (left: Item, right: Item) -> Bool {
                return left.rawValue == right.rawValue
            }
        }

        public var devicePosition: AVCaptureDevice.Position
        public var deviceType: AVCaptureDevice.DeviceType
        public var isAudioDataOutput: Bool
        public var required: [Item]
        public var option: [Item]
        public var captureInfo: CCRenderer.VideoCapture.CaptureInfo = CCRenderer.VideoCapture.CaptureInfo()

        fileprivate var requiredCaptureSize: CGSize?

        public init(devicePosition: AVCaptureDevice.Position = .back, deviceType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera, isAudioDataOutput: Bool = true, required: [Item] = [], option: [Item] = []) {
            self.devicePosition = devicePosition
            self.deviceType = deviceType
            self.isAudioDataOutput = isAudioDataOutput
            self.required = required
            self.option = option
        }
    }
}

extension CCRenderer.VideoCapture.Property {
    func getDevice(position: AVCaptureDevice.Position, deviceType: AVCaptureDevice.DeviceType, mediaType: AVMediaType = AVMediaType.video) throws -> AVCaptureDevice {
        switch position {
        case .front:
            if let device: AVCaptureDevice = AVCaptureDevice.default(deviceType, for: mediaType, position: position) {
                return device
            }
        case .back:
            if let device: AVCaptureDevice = AVCaptureDevice.default(deviceType, for: mediaType, position: position) {
                return device
            }
        case .unspecified:
            throw CCRenderer.VideoCapture.ErrorType.setupError
        @unknown default: break
        }

        MCDebug.errorLog("DeviceType Error: \(deviceType) -> builtInWideAngleCamera")
        if let device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: mediaType, position: position) {
            return device
        } else if let device: AVCaptureDevice = AVCaptureDevice.default(for: mediaType) {
            return device
        }

        throw CCRenderer.VideoCapture.ErrorType.setupError
    }
}

extension CCRenderer.VideoCapture.Property {
    public func setup() throws {
        let captureDevice: AVCaptureDevice = try self.getDevice(position: self.devicePosition, deviceType: self.deviceType)
        let formats: [AVCaptureDevice.Format] = captureDevice.formats.filter { $0.mediaType == .video }

        guard formats.count >= 1 else { throw CCRenderer.VideoCapture.ErrorType.setupError }
        var resultFormats: [AVCaptureDevice.Format] = formats

        //////////////////////////////////////////////////////////
        // 必須のパラメータを設定
        let required: [CCRenderer.VideoCapture.Property.Item] = self.required
        self.requiredCaptureSize = nil
        for item in required {
            resultFormats = try self.filterProperty(item: item, captureDevice: captureDevice, formats: resultFormats, required: true)
        }
        guard !resultFormats.isEmpty else { throw CCRenderer.VideoCapture.ErrorType.setupError }
        //////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////
        // オプションのパラメータを設定
        let option: [CCRenderer.VideoCapture.Property.Item] = self.option
        for item in option {
            do {
                resultFormats = try self.filterProperty(item: item, captureDevice: captureDevice, formats: resultFormats, required: false)
            } catch {
                MCDebug.errorLog("Option Error: \(item)")
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
                CMVideoFormatDescriptionGetDimensions(first.formatDescription).width < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
            })
            else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            resultFormat = format
        }
        //////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////
        // Infoを設定
        self.captureInfo.update(device: captureDevice, deviceFormat: resultFormat, itemList: self.required + self.option)
        //////////////////////////////////////////////////////////
    }

    fileprivate func filterProperty(item: CCRenderer.VideoCapture.Property.Item, captureDevice: AVCaptureDevice, formats: [AVCaptureDevice.Format], required: Bool) throws -> [AVCaptureDevice.Format] {
        switch item {
        case let .captureSize(captureSize):
            if required {
                self.requiredCaptureSize = captureSize.size(isOrientation: false)
            }
            return try self.getCaptureSizeFormat(captureSize: captureSize, item: item, captureDevice: captureDevice, formats: formats, required: required)
        case let .frameRate(frameRate):
            return try self.getFrameRateFormat(frameRate: frameRate, item: item, captureDevice: captureDevice, formats: formats, required: required)
        case let .colorSpace(colorSpace):
            return try self.getColorSpaceFormat(colorSpace: colorSpace, item: item, captureDevice: captureDevice, formats: formats, required: required)
        case let .videoHDR(on):
            return try self.getVideoHDRFormat(on: on, item: item, captureDevice: captureDevice, formats: formats, required: required)
        case let .isSmoothAutoFocusEnabled(on):
            return try self.getSmoothAutoFocusEnabledFormat(on: on, item: item, captureDevice: captureDevice, formats: formats, required: required)
        }
    }

    fileprivate func getCaptureSizeFormat(captureSize: Settings.PresetSize, item: CCRenderer.VideoCapture.Property.Item, captureDevice: AVCaptureDevice, formats: [AVCaptureDevice.Format], required: Bool) throws -> [AVCaptureDevice.Format] {
        // AVCaptureDevice.Formatと照合するためのOrientationの適応されていないsizeを取得
        let captureSize: CGSize = captureSize.size(isOrientation: false)
        let width: CGFloat = captureSize.width
        let height: CGFloat = captureSize.height

        var list: [AVCaptureDevice.Format] = []
        for format: AVCaptureDevice.Format in formats {
            let maxWidth: Int32 = CMVideoFormatDescriptionGetDimensions(format.formatDescription).width
            let maxHeight: Int32 = CMVideoFormatDescriptionGetDimensions(format.formatDescription).height

            let gcd: CGFloat = self.gcd(x: CGFloat(maxWidth), y: CGFloat(maxHeight)) // 最大公約数
            if width <= CGFloat(maxWidth), height <= CGFloat(maxHeight), (CGFloat(maxWidth) / gcd) == 16.0, (CGFloat(maxHeight) / gcd) == 9.0 {
                list.append(format)
            }
        }

        guard !list.isEmpty else { throw CCRenderer.VideoCapture.ErrorType.setupError }
        return list
    }

    fileprivate func getFrameRateFormat(frameRate: Settings.PresetFrameRate, item: CCRenderer.VideoCapture.Property.Item, captureDevice: AVCaptureDevice, formats: [AVCaptureDevice.Format], required: Bool) throws -> [AVCaptureDevice.Format] {
        var list: [AVCaptureDevice.Format] = []
        for format: AVCaptureDevice.Format in formats {
            for range: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                if range.minFrameRate <= Float64(frameRate.rawValue), Float64(frameRate.rawValue) <= range.maxFrameRate {
                    list.append(format)
                    break
                }
            }
        }

        guard !list.isEmpty else { throw CCRenderer.VideoCapture.ErrorType.setupError }
        return list
    }

    fileprivate func getColorSpaceFormat(colorSpace: AVCaptureColorSpace, item: CCRenderer.VideoCapture.Property.Item, captureDevice: AVCaptureDevice, formats: [AVCaptureDevice.Format], required: Bool) throws -> [AVCaptureDevice.Format] {
        let list: [AVCaptureDevice.Format] = formats.filter {
            let colorSpaces: [AVCaptureColorSpace] = $0.supportedColorSpaces.filter { $0 == colorSpace }
            return !colorSpaces.isEmpty
        }

        guard !list.isEmpty else { throw CCRenderer.VideoCapture.ErrorType.setupError }
        return list
    }

    fileprivate func getVideoHDRFormat(on: Bool, item: CCRenderer.VideoCapture.Property.Item, captureDevice: AVCaptureDevice, formats: [AVCaptureDevice.Format], required: Bool) throws -> [AVCaptureDevice.Format] {
        if on {
            let list: [AVCaptureDevice.Format] = formats.filter { $0.isVideoHDRSupported == true }

            guard !list.isEmpty else { throw CCRenderer.VideoCapture.ErrorType.setupError }
            return list
        } else {
            if required {
                let list: [AVCaptureDevice.Format] = formats.filter { $0.isVideoHDRSupported == false }
                guard !list.isEmpty else { throw CCRenderer.VideoCapture.ErrorType.setupError }
                return list
            }
            return formats
        }
    }

    fileprivate func getSmoothAutoFocusEnabledFormat(on: Bool, item: CCRenderer.VideoCapture.Property.Item, captureDevice: AVCaptureDevice, formats: [AVCaptureDevice.Format], required: Bool) throws -> [AVCaptureDevice.Format] {
        if on, required {
            if captureDevice.isSmoothAutoFocusSupported {
                throw CCRenderer.VideoCapture.ErrorType.setupError
            }
        }
        return formats
    }
}

extension CCRenderer.VideoCapture.Property {
    public func swap(property: CCRenderer.VideoCapture.Property.Item) throws {
        var isUpdate: Bool = false
        func map(prop: CCRenderer.VideoCapture.Property.Item) -> CCRenderer.VideoCapture.Property.Item {
            if prop == property {
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

extension CCRenderer.VideoCapture.Property {
    private func gcd(x: Float, y: Float) -> Float {
        if y == 0 { return x }
        return gcd(x: y, y: x.truncatingRemainder(dividingBy: y))
    }

    private func gcd(x: CGFloat, y: CGFloat) -> CGFloat {
        if y == 0 { return x }
        return gcd(x: y, y: x.truncatingRemainder(dividingBy: y))
    }
}
