//
//  AudioWriter.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/17.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
/*
public final class AudioWriter {
	
	private(set) var canRecording: Bool = true
	
	private let captureAudioSession: CaptureAudioSession
	private let queue: DispatchQueue
	private var videoSettings: [String : Any]?
	
	private let fileName: String = NSUUID().uuidString
	
	private var url: URL?
	private var writer: AVAssetWriter?
	private var startTime: CMTime?
	
	private(set) var isWritng: Bool = false
	
	deinit {
		self.isWritng = false
		if self.writer?.status == .writing {
			self.writer?.cancelWriting()
		}
	}
	
	public init?() {
		let session = CaptureAudioSession()
		if !session.canUseSession { return nil }
		self.captureAudioSession = session
		self.queue = session.queue
		let result = self.setup()
		if !result { return nil }
	}
	
	private func setup() -> Bool {
		guard let url = ContentPath.voice.generateFilePathURL(self.fileName) else { return false }
		
		let w: AVAssetWriter
		do {
			w = try AVAssetWriter(outputURL: url, fileType: self.captureAudioSession.fileType)
		} catch let error as NSError {
			SodaCore.debugLog("CaptureWriter setup error: \(error.localizedDescription)")
			return false
		}
		
		var audioSettings = self.captureAudioSession.audioSettings
		audioSettings?[AVFormatIDKey] = NSNumber(value: kAudioFormatMPEG4AAC)
		
		let audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioSettings)
		audioInput.expectsMediaDataInRealTime = true
		
		if w.canAdd(audioInput) {
			w.add(audioInput)
		}
		
		self.writer = w
		self.url = url
		
		self.captureAudioSession.captureAudioBufferHandler = { [weak self] sampleBuffer in
			self?.addAudioBuffer(sampleBuffer)
		}
		
		return true
	}
	
	public func start() -> Bool {
		self.isWritng = true
		self.captureAudioSession.start()
		
		return true
	}
	
	public func pause() {
		self.captureAudioSession.pause()
		self.isWritng = false
	}
	
	public func stop(_ completion: ((String?) -> Void)?) {
		self.finish(completion)
		self.captureAudioSession.stop(nil)
	}
	
	public func cancel() {
		self.captureAudioSession.stop(nil)
		self.isWritng = false
		self.writer?.cancelWriting()
		self.writer = nil
	}
	
	private func finish(_ completion: ((String?) -> Void)?) {
		if !self.isWritng { return }
		self.isWritng = false
		
		let handler: ((String?) -> Void) = { [weak self] fileName in
			self?.writer = nil
			SodaCore.fireMainThread { completion?(fileName) }
		}
		
		let fileName = self.fileName
		guard let w = self.writer else {
			handler(nil)
			return
		}
		
		if w.status == .writing {
			w.inputs.forEach { $0.markAsFinished() }
			w.finishWriting {
				if w.status == .completed {
					handler(fileName)
				} else {
					Debug.ErrorLog("CaptureWriter status not completed")
					SodaCore.debugLog("CaptureWriter status not completed")
					handler(nil)
				}
			}
		} else {
			handler(nil)
		}
	}
	
	public func addAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
		if !self.isWritng { return }
		guard let w = self.writer else { return }
		
		let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
		
		if self.startTime == nil {
			self.startTime = timestamp
			w.startWriting()
			w.startSession(atSourceTime: timestamp)
		}
		
		w.inputs
			.filter { $0.mediaType == AVMediaTypeAudio }
			.filter { $0.isReadyForMoreMediaData }
			.forEach { $0.append(sampleBuffer) }
	}
}
*/
