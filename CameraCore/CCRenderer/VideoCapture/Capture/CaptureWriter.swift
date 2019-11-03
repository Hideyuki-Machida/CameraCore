//
//  CaptureWriter.swift
//  VideoPlayer
//
//  Created by machidahideyuki on 2017/04/21.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage
import MetalCanvas

extension CCRenderer.VideoCapture {
    final public class CaptureWriter {

        public struct Paramator {
            public let outputFilePath: URL
            public let presetiFrame: Settings.PresetSize
            public let frameRate: Settings.PresetFrameRate
            public let devicePosition: AVCaptureDevice.Position
            public let croppingRect: CGRect?
            public let fileType: AVFileType
            public let videoCodecType: Settings.VideoCodec
            public init (outputFilePath: URL, presetiFrame: Settings.PresetSize, frameRate: Settings.PresetFrameRate, devicePosition: AVCaptureDevice.Position, croppingRect: CGRect?, fileType: AVFileType = AVFileType.mp4, videoCodecType: Settings.VideoCodec = .h264) {
                self.outputFilePath = outputFilePath
                self.presetiFrame = presetiFrame
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

        private static var videoSettings: [String : Any]?
        private static var writer: AVAssetWriter?
        private static var startTime: CMTime?
        private static var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

        private static var paramator: Paramator?

        public static var isWritng: Bool = false
        public static var captureFrameCount: Int = 0

        deinit {
            CaptureWriter.isWritng = false
            if CaptureWriter.writer?.status == .writing {
                CaptureWriter.writer?.cancelWriting()
            }
            MCDebug.deinitLog(self)
        }
        
        init(filePath: String, size: CGSize, frameRate: Int, onReady: (_ status: Bool) -> Void) {
            //self.queue = session.queue
            //self.videoSettings = session.videoSettings
            //CaptureWriter.devicePosition = AVCaptureDevicePosition.back
            //self.canRecording = self.setup(session)
            //onReady(CaptureWriter.setup(filePath: filePath, size: size, frameRate: frameRate))
        }

        /// キャプチャーパラメータセット
        static func setup(_ paramator: Paramator) -> Bool {
            CaptureWriter.paramator = paramator
            let url: URL = paramator.outputFilePath
            
            CaptureWriterParam.set(croppingRect: paramator.croppingRect, sampleSize: paramator.presetiFrame.size())
            
            let w: AVAssetWriter
            do {
                //w = try AVAssetWriter(outputURL: url, fileType: AVFileTypeQuickTimeMovie)
                
                w = try AVAssetWriter(outputURL: url, fileType: paramator.fileType)
            } catch {
                assertionFailure()
                return false
            }
            
            let compressionProperties: NSMutableDictionary = NSMutableDictionary()
            compressionProperties[AVVideoExpectedSourceFrameRateKey] = NSNumber(value: paramator.frameRate.rawValue)
            compressionProperties[AVVideoMaxKeyFrameIntervalKey] = NSNumber(value: paramator.frameRate.rawValue)
            //compressionProperties[AVVideoAverageBitRateKey] = NSNumber(value: 2400000)
            
            let captureW: CGFloat
            let captureH: CGFloat
            if let croppingRect: CGRect = paramator.croppingRect {
                captureW = croppingRect.width
                captureH = croppingRect.height
                //captureW = size.width
                //captureH = size.height
                
            } else {
                captureW = paramator.presetiFrame.size().width
                captureH = paramator.presetiFrame.size().height
            }
            
            let videoOutputSettings: [String: Any] = [
                AVVideoCodecKey: paramator.videoCodecType.val,
                AVVideoWidthKey: captureW,
                AVVideoHeightKey: captureH,
                AVVideoCompressionPropertiesKey: compressionProperties
            ]
            
            // AVAssetWriterInputを生成
            let videoInput: AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            w.add(videoInput)
            
            let audioOutputSettings: [String: Any] = [
                AVFormatIDKey : kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
                ]
            let audioInput: AVAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
            audioInput.expectsMediaDataInRealTime = true
            w.add(audioInput)
            
            // AVAssetWriterInputPixelBufferAdaptorを生成
            let sourcePixelBufferAttributes: [String : Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: captureW,
                kCVPixelBufferHeightKey as String: captureH,
                kCVPixelFormatOpenGLESCompatibility as String : NSNumber(value: true),
                ]
            self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
            
            CaptureWriter.writer = w
            
            return true
        }
        
        /// キャプチャー書き込みスタート
        static func start() -> Bool {
            CaptureWriter.isWritng = true
            CaptureWriter.isAddVideoBuffer = false
            CaptureWriter.startTime = nil
            self.captureFrameCount = 0
            return true
        }
        
        /// キャプチャー書き込み停止
        static func pause() {
            CaptureWriter.isWritng = false
        }
        
        /// キャプチャー書き込み終了
        static func finish(_ completion: ((Bool, _ filePath: URL) -> Void)?) {
            if !CaptureWriter.isWritng { return }
            CaptureWriter.isWritng = false
            self.captureFrameCount = 0
            
            guard let outputFilePath: URL = self.paramator?.outputFilePath else { return }
            let handler: ((Bool) -> Void) = { status in
                CaptureWriter.startTime = nil
                CaptureWriter.writer = nil
                CaptureWriter.pixelBufferAdaptor = nil
                CaptureWriter.recordedDuration = 0.0
                CaptureWriter.paramator = nil
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
            if !CaptureWriter.isWritng { return }
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }
            let timestamp: CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if let time: CMTime = CaptureWriter.startTime {
                CaptureWriter.recordedDuration = CMTimeGetSeconds(CMTimeSubtract(timestamp, time))
            }

            if w.status == AVAssetWriter.Status.failed {
                MCDebug.log("writer status faild")
                return
            }

            if let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                if let _: CMTime = CaptureWriter.startTime {
                } else {
                    CaptureWriter.startTime = timestamp
                    w.startWriting()
                    w.startSession(atSourceTime: timestamp)
                }

                let image: CIImage
                if let _: CGRect = CaptureWriterParam.croppingRect {
                    image = CaptureWriterParam.crip(pixelBuffer: pixelBuffer)
                } else {
                    image = CIImage(cvPixelBuffer: pixelBuffer)
                }
                
                CaptureWriter.isAddVideoBuffer = true
                CaptureWriter._addVideoBuffer(image: image, sampleBuffer: sampleBuffer, timestamp: timestamp)
            } else {
                // 音だけの空白フレームが最初に挿入されないように、AudioBufferが最初に来るのを防ぐ
                guard CaptureWriter.isAddVideoBuffer == true else { return }
                CaptureWriter._addAudioBuffer(sampleBuffer: sampleBuffer)
            }
            self.captureFrameCount += 1
        }
        
        static func _addVideoBuffer(image: CIImage, sampleBuffer: CMSampleBuffer, timestamp: CMTime) {
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }
            guard w.inputs.filter({ $0.mediaType == AVMediaType.video }).filter({ $0.isReadyForMoreMediaData }).count > 0 else { return }
            
            guard let pool: CVPixelBufferPool = self.pixelBufferAdaptor?.pixelBufferPool else {
                MCDebug.errorLog("pixelBufferPool nil")
                return
            }
            
            var outputRenderBuffer: CVPixelBuffer? = nil
            let result: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &outputRenderBuffer)
            
            if result == kCVReturnError {
                MCDebug.errorLog("CVPixelBufferPoolCreatePixelBuffer error")
                return
            }
            
            if let buf: CVPixelBuffer = outputRenderBuffer {
                CVPixelBufferLockBaseAddress(buf, CVPixelBufferLockFlags.readOnly)
                var resultImage: CIImage = image
                if CaptureWriter.paramator?.devicePosition == .front {
                    let fliped: CIImage = image.transformed(by: CGAffineTransform(scaleX: -1.0, y: 1.0))
                    resultImage = fliped.transformed(by: CGAffineTransform(translationX: fliped.extent.width, y: 0.0))
                }
                
                MCCore.ciContext.render(resultImage, to: buf, bounds: resultImage.extent, colorSpace: resultImage.colorSpace ?? Configuration.colorSpace)
                CaptureWriter.pixelBufferAdaptor?.append(buf, withPresentationTime: timestamp)
                CVPixelBufferUnlockBaseAddress(buf, CVPixelBufferLockFlags.readOnly)
            }
        }
        
        private static func _addAudioBuffer(sampleBuffer: CMSampleBuffer) {
            if !CaptureWriter.isWritng { return }
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }
            
            w.inputs
                .filter { $0.mediaType == AVMediaType.audio }
                .filter { $0.isReadyForMoreMediaData }
                .forEach { $0.append(sampleBuffer) }
        }
        
        
        /// 動画ファイルに画像追加
        static func addCaptureImage(sampleBuffer: CMSampleBuffer) {
            if !CaptureWriter.isWritng { return }
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
                //SodaCore.debugLog("writer status faild")
                return
            }
            
            guard w.inputs.filter({ $0.mediaType == AVMediaType.video }).filter({ $0.isReadyForMoreMediaData }).count > 0 else { return }
            
            if let buf: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                CVPixelBufferLockBaseAddress(buf, CVPixelBufferLockFlags.readOnly)
                
                if CaptureWriter.paramator?.devicePosition == .front {
                    //let fliped = image.applying(CGAffineTransform(scaleX: -1.0, y: 1.0))
                    //let i = fliped.applying(CGAffineTransform(translationX: fliped.extent.width, y: 0.0))
                    CaptureWriter.pixelBufferAdaptor?.append(buf, withPresentationTime: timestamp)
                } else {
                    CaptureWriter.pixelBufferAdaptor?.append(buf, withPresentationTime: timestamp)
                }
                
                CVPixelBufferUnlockBaseAddress(buf, CVPixelBufferLockFlags.readOnly)
            } else {
                //SodaCore.debugLog("outputRenderBuffer.pointee error")
            }
        }
        
        static func addAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
            if !CaptureWriter.isWritng { return }
            guard let w: AVAssetWriter = CaptureWriter.writer else { return }
            
            w.inputs
                .filter { $0.mediaType == AVMediaType.audio }
                .filter { $0.isReadyForMoreMediaData }
                .forEach { $0.append(sampleBuffer) }
        }
    }
}


struct CaptureWriterParam {
    fileprivate static var croppingVector: CIVector?
    fileprivate static var croppingRect: CGRect?
    fileprivate static var sampleSize: CGSize?
    static func set(croppingRect: CGRect?, sampleSize: CGSize?) {
        CaptureWriterParam.croppingVector = nil
        CaptureWriterParam.croppingRect = nil
        CaptureWriterParam.sampleSize = nil
        guard let croppingRect: CGRect = croppingRect, let sampleSize: CGSize = sampleSize else { return }
        CaptureWriterParam.croppingRect = croppingRect
        let y: CGFloat = sampleSize.height - croppingRect.size.height - croppingRect.origin.y
        CaptureWriterParam.croppingVector = CIVector(x: croppingRect.origin.x, y: y, z: croppingRect.size.width, w: croppingRect.size.height)
    }
    static func crip(pixelBuffer: CVPixelBuffer) -> CIImage {
        let tempImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
        //image = CIImage(cvPixelBuffer: pixelBuffer).applying(CGAffineTransform(translationX: 0, y: -500  ))
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter?.setValue(tempImage, forKey: kCIInputImageKey)
        cropFilter?.setValue(CaptureWriterParam.croppingVector, forKey: "inputRectangle")
        return (cropFilter?.outputImage)!.transformed(by: CGAffineTransform(translationX: 0, y: -(CaptureWriterParam.croppingVector?.y)! ))
    }
}
