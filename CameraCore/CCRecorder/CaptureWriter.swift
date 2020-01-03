//
//  CaptureWriter.swift
//  VideoPlayer
//
//  Created by machidahideyuki on 2017/04/21.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import CoreImage
import Foundation
import MetalCanvas

// モジュールテスト用
// TODO: テスト用のためのClass。本番使用時には再設計 & レビューが必要
extension CCRecorder {
    public final class CaptureWriter {
        // swiftlint:disable:next nesting
        public struct Parameter {
            // swiftlint:disable:previous nesting
            public let outputFilePath: URL
            public let presetFrame: Settings.PresetSize
            public let frameRate: Int32
            public let devicePosition: AVCaptureDevice.Position
            public let croppingRect: CGRect?
            public let fileType: AVFileType
            public let videoCodecType: Settings.VideoCodec
            public init(outputFilePath: URL, presetFrame: Settings.PresetSize, frameRate: Int32, devicePosition: AVCaptureDevice.Position, croppingRect: CGRect?, fileType: AVFileType = AVFileType.mp4, videoCodecType: Settings.VideoCodec = .h264) {
                self.outputFilePath = outputFilePath
                self.presetFrame = presetFrame
                self.frameRate = frameRate
                self.devicePosition = devicePosition
                self.croppingRect = croppingRect
                self.fileType = fileType
                self.videoCodecType = videoCodecType
            }
        }

        private static let queue: DispatchQueue = DispatchQueue(label: "CameraCore.video_exporter.queue")
        private static var videoInput: AVAssetWriterInput?

        private(set) static var recordedDuration: TimeInterval = 0.0

        private static var videoSettings: [String: Any]?
        private static var writer: AVAssetWriter?
        private static var startTime: CMTime?
        private static var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

        private static var parameter: Parameter?

        public static var isWriting: Bool = false
        public static var captureFrameCount: Int = 0

        deinit {
            CaptureWriter.isWriting = false
            if CaptureWriter.writer?.status == .writing {
                CaptureWriter.writer?.cancelWriting()
            }
            MCDebug.log(self)
        }

        /// キャプチャーパラメータセット
        @discardableResult
        static func setup(_ parameter: Parameter) -> Bool {
            CaptureWriter.parameter = parameter
            let url: URL = parameter.outputFilePath

            CaptureWriterParam.set(croppingRect: parameter.croppingRect, sampleSize: parameter.presetFrame.size())

            let w: AVAssetWriter
            do {
                w = try AVAssetWriter(outputURL: url, fileType: parameter.fileType)
            } catch {
                assertionFailure()
                return false
            }

            let compressionProperties: NSMutableDictionary = NSMutableDictionary()
            compressionProperties[AVVideoExpectedSourceFrameRateKey] = NSNumber(value: parameter.frameRate)
            compressionProperties[AVVideoMaxKeyFrameIntervalKey] = NSNumber(value: parameter.frameRate)

            let captureSize: CGSize = getCaptureSize(parameter: parameter)

            let videoOutputSettings: [String: Any] = [
                AVVideoCodecKey: parameter.videoCodecType.val,
                AVVideoWidthKey: captureSize.width,
                AVVideoHeightKey: captureSize.height,
                AVVideoCompressionPropertiesKey: compressionProperties,
            ]

            // AVAssetWriterInputを生成
            let videoInput: AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            w.add(videoInput)

            let audioOutputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
            ]
            let audioInput: AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
            audioInput.expectsMediaDataInRealTime = true
            w.add(audioInput)

            // AVAssetWriterInputPixelBufferAdaptorを生成
            let sourcePixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: captureSize.width,
                kCVPixelBufferHeightKey as String: captureSize.height,
                kCVPixelFormatOpenGLESCompatibility as String: NSNumber(value: true),
            ]
            self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)

            CaptureWriter.writer = w

            return true
        }

        /// キャプチャー書き込みスタート
        @discardableResult
        static func start() -> Bool {
            CaptureWriter.isWriting = true
            CaptureWriter.isAddVideoBuffer = false
            CaptureWriter.startTime = nil
            self.captureFrameCount = 0
            return true
        }

        /// キャプチャー書き込み停止
        static func pause() {
            CaptureWriter.isWriting = false
        }

        /// キャプチャー書き込み終了
        static func finish(_ completion: ((Bool, _ filePath: URL) -> Void)?) {
            if !CaptureWriter.isWriting { return }
            CaptureWriter.isWriting = false
            self.captureFrameCount = 0

            guard let outputFilePath: URL = self.parameter?.outputFilePath else { return }
            let handler: ((Bool) -> Void) = { status in
                CaptureWriter.startTime = nil
                CaptureWriter.writer = nil
                CaptureWriter.pixelBufferAdaptor = nil
                CaptureWriter.recordedDuration = 0.0
                CaptureWriter.parameter = nil
                completion?(status, outputFilePath)
            }

            guard let w: AVAssetWriter = CaptureWriter.writer else {
                handler(false)
                return
            }

            if w.status == .writing {
                w.inputs.forEach { $0.markAsFinished() }
                w.finishWriting {
                    if w.status == .completed {
                        handler(true)
                    } else {
                        handler(false)
                    }
                }
            } else {
                handler(false)
            }
        }

        private(set) static var isAddVideoBuffer: Bool = false // 音だけの空白フレームが最初に挿入されないようにするフラグ
        static func addCaptureSampleBuffer(sampleBuffer: CMSampleBuffer) {
            if !CaptureWriter.isWriting { return }
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }
            let timestamp: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if let time: CMTime = CaptureWriter.startTime {
                CaptureWriter.recordedDuration = CMTimeGetSeconds(CMTimeSubtract(timestamp, time))
            }

            if w.status == AVAssetWriter.Status.failed {
                MCDebug.log("writer status failed")
                return
            }

            if let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                if CaptureWriter.startTime == nil {
                    CaptureWriter.startTime = timestamp
                    w.startWriting()
                    w.startSession(atSourceTime: timestamp)
                }

                let image: CIImage = CaptureWriterParam.croppingRect != nil ? CaptureWriterParam.crop(pixelBuffer: pixelBuffer) : CIImage(cvPixelBuffer: pixelBuffer)

                CaptureWriter.isAddVideoBuffer = true
                CaptureWriter.addVideoBuffer(image: image, sampleBuffer: sampleBuffer, timestamp: timestamp)
            } else {
                // 音だけの空白フレームが最初に挿入されないように、AudioBufferが最初に来るのを防ぐ
                guard CaptureWriter.isAddVideoBuffer else { return }
                CaptureWriter._addAudioBuffer(sampleBuffer: sampleBuffer)
            }
            self.captureFrameCount += 1
        }

        static func addVideoBuffer(image: CIImage, sampleBuffer: CMSampleBuffer, timestamp: CMTime) {
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }
            guard w.inputs.filter({ $0.mediaType == AVMediaType.video }).filter({ $0.isReadyForMoreMediaData }).count > 0 else { return }

            guard let pool: CVPixelBufferPool = self.pixelBufferAdaptor?.pixelBufferPool else {
                MCDebug.errorLog("pixelBufferPool nil")
                return
            }

            var outputRenderBuffer: CVPixelBuffer?
            let result: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &outputRenderBuffer)

            if result == kCVReturnError {
                MCDebug.errorLog("CVPixelBufferPoolCreatePixelBuffer error")
                return
            }

            guard let buf: CVPixelBuffer = outputRenderBuffer else { return }
            CVPixelBufferLockBaseAddress(buf, CVPixelBufferLockFlags.readOnly)
            var resultImage: CIImage = image
            if CaptureWriter.parameter?.devicePosition == .front {
                let flipped: CIImage = image.transformed(by: CGAffineTransform(scaleX: -1.0, y: 1.0))
                resultImage = flipped.transformed(by: CGAffineTransform(translationX: flipped.extent.width, y: 0.0))
            }

            MCCore.ciContext.render(resultImage, to: buf, bounds: resultImage.extent, colorSpace: resultImage.colorSpace ?? Configuration.colorSpace)
            CaptureWriter.pixelBufferAdaptor?.append(buf, withPresentationTime: timestamp)
            CVPixelBufferUnlockBaseAddress(buf, CVPixelBufferLockFlags.readOnly)
        }

        private static func _addAudioBuffer(sampleBuffer: CMSampleBuffer) {
            if !CaptureWriter.isWriting { return }
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }

            w.inputs
                .filter { $0.mediaType == AVMediaType.audio && $0.isReadyForMoreMediaData }
                .forEach { $0.append(sampleBuffer) }
        }

        /// 動画ファイルに画像追加
        static func addCaptureImage(sampleBuffer: CMSampleBuffer) {
            if !CaptureWriter.isWriting { return }
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }

            let timestamp: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if let time: CMTime = CaptureWriter.startTime {
                CaptureWriter.recordedDuration = CMTimeGetSeconds(CMTimeSubtract(timestamp, time))
            } else {
                CaptureWriter.startTime = timestamp
                w.startWriting()
                w.startSession(atSourceTime: timestamp)
            }

            if w.status == AVAssetWriter.Status.failed {
                return
            }

            guard w.inputs.filter({ $0.mediaType == AVMediaType.video }).filter({ $0.isReadyForMoreMediaData }).count > 0 else { return }

            if let buf: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                CVPixelBufferLockBaseAddress(buf, CVPixelBufferLockFlags.readOnly)

                if CaptureWriter.parameter?.devicePosition == .front {
                    CaptureWriter.pixelBufferAdaptor?.append(buf, withPresentationTime: timestamp)
                } else {
                    CaptureWriter.pixelBufferAdaptor?.append(buf, withPresentationTime: timestamp)
                }

                CVPixelBufferUnlockBaseAddress(buf, CVPixelBufferLockFlags.readOnly)
            } else {
                MCDebug.errorLog("outputRenderBuffer.pointee error")
            }
        }

        static func addAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
            if !CaptureWriter.isWriting { return }
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }

            w.inputs
                .filter { $0.mediaType == AVMediaType.audio && $0.isReadyForMoreMediaData }
                .forEach { $0.append(sampleBuffer) }
        }
    }
}

extension CCRecorder.CaptureWriter {
    fileprivate static func getCaptureSize(parameter: Parameter) -> CGSize {
        if let croppingRect: CGRect = parameter.croppingRect {
            return croppingRect.size
        }
        return parameter.presetFrame.size().toCGSize()
    }
}

struct CaptureWriterParam {
    fileprivate static var croppingVector: CIVector?
    fileprivate static var croppingRect: CGRect?
    fileprivate static var sampleSize: MCSize?
    static func set(croppingRect: CGRect?, sampleSize: MCSize?) {
        CaptureWriterParam.croppingVector = nil
        CaptureWriterParam.croppingRect = nil
        CaptureWriterParam.sampleSize = nil
        guard let croppingRect: CGRect = croppingRect, let sampleSize: MCSize = sampleSize else { return }
        CaptureWriterParam.croppingRect = croppingRect
        let y: CGFloat = CGFloat(sampleSize.h) - croppingRect.size.height - croppingRect.origin.y
        CaptureWriterParam.croppingVector = CIVector(x: croppingRect.origin.x, y: y, z: croppingRect.size.width, w: croppingRect.size.height)
    }

    static func crop(pixelBuffer: CVPixelBuffer) -> CIImage {
        let tempImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter?.setValue(tempImage, forKey: kCIInputImageKey)
        cropFilter?.setValue(CaptureWriterParam.croppingVector, forKey: "inputRectangle")
        guard let croppingVector: CIVector = CaptureWriterParam.croppingVector else { return tempImage }
        return cropFilter?.outputImage?.transformed(by: CGAffineTransform(translationX: 0, y: -croppingVector.y)) ?? tempImage
    }
}
