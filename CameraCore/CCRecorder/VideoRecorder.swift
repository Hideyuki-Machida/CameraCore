//
//  VideoRecorder.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/16.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas


extension CCRecorder {
    public class VideoRecorder {
        public let setup: CCRecorder.VideoRecorder.Setup = CCRecorder.VideoRecorder.Setup()
        public let triger: CCRecorder.VideoRecorder.Triger = CCRecorder.VideoRecorder.Triger()
        public let pipe: CCRecorder.VideoRecorder.Pipe = CCRecorder.VideoRecorder.Pipe()

        fileprivate let imageProcessQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRecorder.VideoRecorder", attributes: DispatchQueue.Attributes.concurrent)

        var captureWriter: CaptureWriter = CaptureWriter()
        public var isRecording: Bool = false

        public init() throws {
            self.setup.videoRecorder = self
            self.triger.videoRecorder = self
            self.pipe.videoRecorder = self
        }
        
        deinit {
            self.dispose()
            MCDebug.deinitLog(self)
        }
    }
}

extension CCRecorder.VideoRecorder {
    func pipe(audioEngine: CCAudio.AudioEngine) throws {
        audioEngine.onUpdateSampleBuffer = { (sampleBuffer: CMSampleBuffer) in
            guard self.isRecording == true else { return }
            self.captureWriter.setSampleBuffer(sampleBuffer: sampleBuffer)
        }
    }
}

/*
extension CCRecorder {
    public class VideoRecorder {
        public var isRecording: Bool {
            get {
                return CCRecorder.CaptureWriter.isWriting
            }
        }

        public init() throws {
        }
    }
}

public extension CCRecorder.VideoRecorder {
    func setup(parameter: CCRecorder.CaptureWriter.Parameter) {
        CCRecorder.CaptureWriter.setup(parameter)
    }

    func start() {
        CCRecorder.CaptureWriter.start()
    }
    
    func stop() {
        CCRecorder.CaptureWriter.finish { (success: Bool, url: URL) in
            print(success)
        }
    }
}

extension CCRecorder.VideoRecorder {
    func pipe(camera: CCCapture.Camera) throws {
        camera.onUpdateCaptureData = { (currentCaptureItem: CCCapture.VideoCapture.CaptureData) in
            guard CCRecorder.CaptureWriter.isWriting == true else { return }
            CCRecorder.CaptureWriter.addCaptureSampleBuffer(sampleBuffer: currentCaptureItem.sampleBuffer)
        }
    }

    func pipe(audioEngine: CCAudio.AudioEngine) throws {
        audioEngine.onUpdateSampleBuffer = { (sampleBuffer: CMSampleBuffer) in
            guard CCRecorder.CaptureWriter.isWriting == true else { return }
            //CCRecorder.CaptureWriter.addCaptureSampleBuffer(sampleBuffer: sampleBuffer)
            CCRecorder.CaptureWriter.addAudioBuffer(sampleBuffer)
        }
    }
}
*/
extension CCRecorder.VideoRecorder {
    class CaptureWriter {
        var writer: AVAssetWriter?
        init() {
            
        }
        func setup(_ parameter: CCRecorder.CaptureWriter.Parameter) throws {
            let url: URL = parameter.outputFilePath

            CaptureWriterParam.set(croppingRect: parameter.croppingRect, sampleSize: parameter.presetFrame.size(orientation: UIInterfaceOrientation.portrait))

            let w: AVAssetWriter = try AVAssetWriter(outputURL: url, fileType: parameter.fileType)

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

            self.writer = w
        }
        
        fileprivate func getCaptureSize(parameter: CCRecorder.CaptureWriter.Parameter) -> CGSize {
            if let croppingRect: CGRect = parameter.croppingRect {
                return croppingRect.size
            }
            return parameter.presetFrame.size(orientation: UIInterfaceOrientation.portrait).toCGSize()
        }
        
        private var videoOffsetTime: CMTime = CMTime.zero
        private var audioOffsetTime: CMTime = CMTime.zero
        func setSampleBuffer(sampleBuffer: CMSampleBuffer) {
            guard let w: AVAssetWriter = self.writer else { return }
            if let _: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                var copyBuffer : CMSampleBuffer?
                var info = CMSampleTimingInfo()
                var count: CMItemCount = 1
                CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
                if self.videoOffsetTime == CMTime.zero {
                    self.videoOffsetTime = info.presentationTimeStamp
                }
                info.presentationTimeStamp = CMTimeSubtract(info.presentationTimeStamp, self.videoOffsetTime)
                let status002: OSStatus = CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleTimingEntryCount: 1, sampleTimingArray: &info, sampleBufferOut: &copyBuffer)
                guard status002 == noErr else { return }
                w.inputs
                    .filter { $0.mediaType == AVMediaType.video && $0.isReadyForMoreMediaData }
                    .forEach { $0.append(copyBuffer!) }

            } else {
                var copyBuffer : CMSampleBuffer?
                var info = CMSampleTimingInfo()
                var count: CMItemCount = 1
                CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
                if self.audioOffsetTime == CMTime.zero {
                    self.audioOffsetTime = info.presentationTimeStamp
                }
                info.presentationTimeStamp = CMTimeSubtract(info.presentationTimeStamp, self.audioOffsetTime)
                let status002: OSStatus = CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleTimingEntryCount: 1, sampleTimingArray: &info, sampleBufferOut: &copyBuffer)
                guard status002 == noErr else { return }

                w.inputs
                    .filter { $0.mediaType == AVMediaType.audio && $0.isReadyForMoreMediaData }
                    .forEach { $0.append(copyBuffer!) }

            }
        }

        func set(pixelBuffer: CVPixelBuffer, presentationTimeStamp: CMTime) {
            guard let w: AVAssetWriter = self.writer else { return }
            var timingInfo: CMSampleTimingInfo = CMSampleTimingInfo()
            if self.videoOffsetTime == CMTime.zero {
                self.videoOffsetTime = presentationTimeStamp
            }
            timingInfo.presentationTimeStamp = CMTimeSubtract(presentationTimeStamp, self.videoOffsetTime)
            guard
                let formatDescription: CMFormatDescription = CMFormatDescription.create(from: pixelBuffer),
                let sampleBuffer: CMSampleBuffer = CMSampleBuffer.create(from: pixelBuffer, formatDescription: formatDescription, timingInfo: &timingInfo)
            else { return }
            w.inputs
                .filter { $0.mediaType == AVMediaType.video && $0.isReadyForMoreMediaData }
                .forEach { $0.append(sampleBuffer) }
        }
        
        func start() {
            self.writer?.startWriting()
            self.writer?.startSession(atSourceTime: CMTime.zero)
        }

        func stop() {
            guard let w: AVAssetWriter = self.writer else { return }
            w.inputs.forEach { $0.markAsFinished() }
            self.writer?.finishWriting(completionHandler: {

            })
        }

        deinit {
            MCDebug.deinitLog(self)
        }

    }
}

fileprivate extension CCRecorder.VideoRecorder {
    func dispose() {
        self.setup._dispose()
        self.triger._dispose()
        self.pipe._dispose()
        NotificationCenter.default.removeObserver(self)
    }
}

extension CCRecorder.VideoRecorder {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var videoRecorder: CCRecorder.VideoRecorder?
        
        public func setup(parameter: CCRecorder.CaptureWriter.Parameter) throws {
           try self.videoRecorder?.captureWriter.setup(parameter)
       }

        fileprivate func _dispose() {
            self.videoRecorder = nil
        }
    }

    // MARK: - Triger
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var videoRecorder: CCRecorder.VideoRecorder?

        public func start() {
            self.videoRecorder?.isRecording = true
            self.videoRecorder?.captureWriter.start()
        }

        public func stop() {
            self.videoRecorder?.isRecording = false
            self.videoRecorder?.captureWriter.stop()
        }

        public func dispose() {
            self.videoRecorder?.dispose()
        }

        fileprivate func _dispose() {
            self.videoRecorder = nil
        }
    }

    // MARK: - Pipe
    public class Pipe: NSObject, CCComponentPipeProtocol {
        fileprivate var videoRecorder: CCRecorder.VideoRecorder?
        fileprivate var observations: [NSKeyValueObservation] = []

        @objc dynamic public var outPresentationTimeStamp: CMTime = CMTime.zero

        func input(camera: CCCapture.Camera) throws {
            let observation: NSKeyValueObservation = camera.pipe.observe(\.outVideoCapturePresentationTimeStamp, options: [.new]) { [weak self] (object: CCCapture.Camera.Pipe, change) in
                guard let captureData: CCCapture.VideoCapture.CaptureData = object.currentVideoCaptureItem else { return }

                guard let self = self else { return }
                guard self.videoRecorder?.isRecording == true else { return }
                self.videoRecorder?.captureWriter.setSampleBuffer(sampleBuffer: captureData.sampleBuffer)
            }
            self.observations.append(observation)
        }

        func input(imageProcess: CCImageProcess.ImageProcess) throws {
            let observation: NSKeyValueObservation = imageProcess.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCImageProcess.ImageProcess.Pipe, change) in
                guard let outTexture: CCTexture = object.outTexture else { return }

                guard let self = self else { return }
                guard self.videoRecorder?.isRecording == true else { return }
                guard let pixelBuffer: CVPixelBuffer = outTexture.pixelBuffer else { return }

                self.videoRecorder?.captureWriter.set(pixelBuffer: pixelBuffer, presentationTimeStamp: outTexture.presentationTimeStamp)
            }
            self.observations.append(observation)
        }

        fileprivate func _dispose() {
            self.videoRecorder = nil
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
        }
    }
}
