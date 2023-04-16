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
import UIKit
import ProcessLogger_Swift
import Combine

extension CCRecorder {
    //static let queue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRecorder.VideoRecorder", attributes: DispatchQueue.Attributes.concurrent)
    static let queue: DispatchQueue = DispatchQueue(label: "CameraCore.CCRecorder.VideoRecorder")

    public class VideoRecorder {
        public let setup: CCRecorder.VideoRecorder.Setup = CCRecorder.VideoRecorder.Setup()
        public let trigger: CCRecorder.VideoRecorder.Trigger = CCRecorder.VideoRecorder.Trigger()
        public let pipe: CCRecorder.VideoRecorder.Pipe = CCRecorder.VideoRecorder.Pipe()


        var captureWriter: CaptureWriter = CaptureWriter()
        public var isRecording: Bool = false

        public init() throws {
            self.setup.videoRecorder = self
            self.trigger.videoRecorder = self
            self.pipe.videoRecorder = self
        }
        
        deinit {
            self.dispose()
            ProcessLogger.deinitLog(self)
        }
    }
}

extension CCRecorder.VideoRecorder {
    class CaptureWriter {
        var writer: AVAssetWriter?

        private var pixelOffsetTime: CMTime = CMTime.zero
        private var audioOffsetTime: CMTime = CMTime.zero
        private var pixelPresentationTimeStamp: CMTime = CMTime.zero
        private var audioPresentationTimeStamp: CMTime = CMTime.zero

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

        func setSampleBuffer(sampleBuffer: CMSampleBuffer) {
            if let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                var info = CMSampleTimingInfo()
                var count: CMItemCount = 1
                CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
                self.setPixelBuffer(pixelBuffer: pixelBuffer, presentationTimeStamp: info.presentationTimeStamp)
            } else {
                self.setAudioBuffer(sampleBuffer: sampleBuffer)
            }
        }

        func setPixelBuffer(pixelBuffer: CVPixelBuffer, presentationTimeStamp: CMTime) {
            guard let w: AVAssetWriter = self.writer else { return }
            var timingInfo: CMSampleTimingInfo = CMSampleTimingInfo()
            if self.pixelOffsetTime == CMTime.zero {
                self.pixelOffsetTime = presentationTimeStamp
            }
            timingInfo.presentationTimeStamp = CMTimeSubtract(presentationTimeStamp, self.pixelOffsetTime)

            guard
                self.pixelPresentationTimeStamp != timingInfo.presentationTimeStamp,
                let formatDescription: CMFormatDescription = CMFormatDescription.create(from: pixelBuffer),
                let sampleBuffer: CMSampleBuffer = CMSampleBuffer.create(from: pixelBuffer, formatDescription: formatDescription, timingInfo: &timingInfo)
            else { return }

            self.pixelPresentationTimeStamp = timingInfo.presentationTimeStamp
            w.inputs
                .filter { $0.mediaType == AVMediaType.video && $0.isReadyForMoreMediaData }
                .forEach { $0.append(sampleBuffer) }
        }

        func setAudioBuffer(sampleBuffer: CMSampleBuffer) {
            guard let w: AVAssetWriter = self.writer else { return }
            var copyBuffer : CMSampleBuffer?
            var info = CMSampleTimingInfo()
            var count: CMItemCount = 1
            CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
            guard self.audioPresentationTimeStamp != info.presentationTimeStamp else { return }
            if self.audioOffsetTime == CMTime.zero {
                self.audioOffsetTime = info.presentationTimeStamp
            }

            info.presentationTimeStamp = CMTimeSubtract(info.presentationTimeStamp, self.audioOffsetTime)
            let status002: OSStatus = CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer, sampleTimingEntryCount: 1, sampleTimingArray: &info, sampleBufferOut: &copyBuffer)
            guard status002 == noErr else { return }

            self.audioPresentationTimeStamp = info.presentationTimeStamp

            w.inputs
                .filter { $0.mediaType == AVMediaType.audio && $0.isReadyForMoreMediaData }
                .forEach { $0.append(copyBuffer!) }
        }

        
        func start() {
            self.pixelOffsetTime = CMTime.zero
            self.audioOffsetTime = CMTime.zero
            self.pixelPresentationTimeStamp = CMTime.zero
            self.audioPresentationTimeStamp = CMTime.zero

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
            ProcessLogger.deinitLog(self)
        }

    }
}

fileprivate extension CCRecorder.VideoRecorder {
    func dispose() {
        self.setup._dispose()
        self.trigger._dispose()
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


    // MARK: - Trigger
    public class Trigger: CCComponentTriggerProtocol {
        fileprivate var videoRecorder: CCRecorder.VideoRecorder?

        public func start() {
            CCRecorder.queue.async { [weak self] in
                guard let self = self else { return }
                self.videoRecorder?.captureWriter.start()
                self.videoRecorder?.isRecording = true
            }
        }

        public func stop() {
            CCRecorder.queue.async { [weak self] in
                guard let self = self else { return }
                self.videoRecorder?.captureWriter.stop()
                self.videoRecorder?.isRecording = false
            }
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
        fileprivate var cancellableBag: [AnyCancellable] = []

        @objc dynamic public var outPresentationTimeStamp: CMTime = CMTime.zero

        func set(audioPCMBuffer: AVAudioPCMBuffer, audioTime: AVAudioTime) {
            CCRecorder.queue.async { [weak self] in
                guard let buffer: CMSampleBuffer = CMSampleBuffer.create(audioPCMBuffer: audioPCMBuffer, audioTime: audioTime) else { return }
                //self?.videoRecorder?.captureWriter.setAudioBuffer(sampleBuffer: sampleBuffer)
            }
        }
        
        func input(camera: CCCapture.Camera) throws {
            //////////////////////////////////////////////////////////////////////////
            /// update VideoCaptureData

            camera.pipe.videoCaptureItem
                .receive(on: CCRecorder.queue)
                .sink { completion in
                    switch completion {
                        case .finished:
                            print("Received finished")
                        case .failure(let error):
                            print("Received error: \(error)")
                        }
                } receiveValue: { [weak self] (captureData: CCCapture.VideoCapture.CaptureData) in
                    guard
                        let self = self,
                        self.videoRecorder?.isRecording == true,
                        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(captureData.sampleBuffer)
                    else { return }

                    self.videoRecorder?.captureWriter.setPixelBuffer(pixelBuffer: pixelBuffer, presentationTimeStamp: captureData.presentationTimeStamp)
                }.store(in: &self.cancellableBag)

            //////////////////////////////////////////////////////////////////////////
            camera.pipe.audioCaptureItem
                .receive(on: CCRecorder.queue)
                .sink { completion in
                    switch completion {
                        case .finished:
                            print("Received finished")
                        case .failure(let error):
                            print("Received error: \(error)")
                        }
                } receiveValue: { [weak self] (captureData: CCCapture.VideoCapture.CaptureData) in
                    guard
                        let self = self,
                        self.videoRecorder?.isRecording == true
                    else { return }

                    self.videoRecorder?.captureWriter.setAudioBuffer(sampleBuffer: captureData.sampleBuffer)
                }.store(in: &self.cancellableBag)
        }

        func input(imageProcess: CCImageProcess.ImageProcess) throws {
            imageProcess.pipe.outTexture
                .receive(on: CCRecorder.queue)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("Received finished")
                    case .failure(let error):
                        print("Received error: \(error)")
                    }
                } receiveValue: { [weak self] (outTexture: CCTexture) in
                    guard
                        let self = self,
                        self.videoRecorder?.isRecording == true,
                        let pixelBuffer: CVPixelBuffer = outTexture.pixelBuffer
                    else { return }

                    self.videoRecorder?.captureWriter.setPixelBuffer(pixelBuffer: pixelBuffer, presentationTimeStamp: outTexture.presentationTimeStamp)
                }.store(in: &self.cancellableBag)
        }

        func input(audioEngine: CCAudio.AudioEngine) throws {
            /*
            //////////////////////////////////////////////////////////////////////////
            /// updatePixelPresentationTimeStamp
            audioEngine.pipe.$audioCaptureSampleBuffer
                .receive(on: CCRecorder.queue)
                .compactMap{$0}
                .sink { [weak self] (sampleBuffer: CMSampleBuffer) in
                    guard
                        let self = self,
                        self.videoRecorder?.isRecording == true
                    else { return }

                    self.videoRecorder?.captureWriter.setAudioBuffer(sampleBuffer: sampleBuffer)
            }.store(in: &self.cancellableBag)
            //////////////////////////////////////////////////////////////////////////
             */
            
        }

        func input(microphone: CCAudio.Microphone) throws {
            /*
            //////////////////////////////////////////////////////////////////////////
            /// updatePixelPresentationTimeStamp
            microphone.pipe.$audioCaptureSampleBuffer
                .receive(on: CCRecorder.queue)
                .compactMap{$0}
                .sink { [weak self] (sampleBuffer: CMSampleBuffer) in
                    guard
                        let self = self,
                        self.videoRecorder?.isRecording == true
                    else { return }

                    self.videoRecorder?.captureWriter.setAudioBuffer(sampleBuffer: sampleBuffer)
            }.store(in: &self.cancellableBag)
            //////////////////////////////////////////////////////////////////////////
             */
            
        }

        fileprivate func _dispose() {
            self.videoRecorder = nil
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
        }
    }
}
