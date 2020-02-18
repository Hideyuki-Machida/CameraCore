//
//  VideoRecorder.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/16.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation


extension CCRecorder {
    public class VideoRecorder {
        var captureWriter: CaptureWriter = CaptureWriter()
        public var isRecording: Bool = false

        public init() throws {
        }
    }
}

public extension CCRecorder.VideoRecorder {
    func setup(parameter: CCRecorder.CaptureWriter.Parameter) throws {
        try self.captureWriter.setup(parameter)
    }

    func start() {
        self.isRecording = true
        self.captureWriter.start()
    }
    
    func stop() {
        self.isRecording = false
        self.captureWriter.stop()
        /*
        CCRecorder.CaptureWriter.finish { (success: Bool, url: URL) in
            print(success)
        }
 */
    }
}

extension CCRecorder.VideoRecorder {
    func pipe(camera: CCCapture.Camera) throws {
        camera.onUpdateCaptureData = { (currentCaptureItem: CCCapture.VideoCapture.CaptureData) in
            guard self.isRecording == true else { return }
            self.captureWriter.setSampleBuffer(sampleBuffer: currentCaptureItem.sampleBuffer)
        }
    }

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

    }
}
