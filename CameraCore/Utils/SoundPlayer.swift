//
//  SoundPlayer.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/03/28.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public final class SoundPlayer {
	public static let shared = SoundPlayer()

	public enum Status{
		case delay
		case play
		case pause
	}

	public enum ErrorType: Error {
		case initialError
		case writeingError
		case renderFailed
	}

	fileprivate var timer: Timer?
	fileprivate var count: Double = 0
	fileprivate var deray: Double = 0

	fileprivate var displayLink: CADisplayLink?
	fileprivate var player: AVAudioPlayerNode = AVAudioPlayerNode()

	public var onUpdate: ((_ time: Float)->Void)?
	public var onChangeStatus: ((_ status: Status)->Void)?

	let engine: AVAudioEngine = AVAudioEngine()
	let reverb: AVAudioUnitReverb = AVAudioUnitReverb()
	var sourceFile: AVAudioFile?
	var buffer: AVAudioPCMBuffer?
	var workItem: DispatchWorkItem?

	let pitchUnit = AVAudioUnitTimePitch()

	public var pitch: Float {
		set {
			self.pitchUnit.pitch = newValue
		}
		get {
			return self.pitchUnit.pitch
		}
	}
	public var volume: Float {
		set {
			self.player.volume = newValue
		}
		get {
			return self.player.volume
		}
	}
	public var duration: Float {
		get {
			let seconds = Double(self.sourceFile!.length) / self.sourceFile!.fileFormat.sampleRate
			return Float(seconds)
		}
	}
	public var isPlaying: Bool {
		get {
			return self.player.isPlaying || timer != nil
		}
	}
	var offSet: Double = 0
	public var time: Float {
		get {
			let nodeTime = self.player.lastRenderTime
			let playerTime = self.player.playerTime(forNodeTime: nodeTime!)
			let seconds = (Double(playerTime!.sampleTime) / self.sourceFile!.fileFormat.sampleRate)
			return Float(seconds)
		}
	}
	public init() {
		// attach
		//self.engine.attach(self.player)
		self.engine.attach(self.pitchUnit)
		self.engine.attach(self.reverb)
		
		// set desired reverb parameters
		self.reverb.loadFactoryPreset(.mediumHall)
		self.reverb.wetDryMix = 50
	}

	public func setup(url: URL) throws {
		self.pause()
		self.player = AVAudioPlayerNode()
		self.engine.attach(self.player)
		do {
			self.sourceFile = try AVAudioFile(forReading: url)
			guard
				let sourceFile: AVAudioFile = self.sourceFile,
				let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: sourceFile.processingFormat, frameCapacity: AVAudioFrameCount(sourceFile.length))
				else { throw ErrorType.initialError }
			try self.sourceFile?.read(into: buffer)
			
			self.engine.connect(self.player, to: self.pitchUnit, format: buffer.format)
			self.engine.connect(self.pitchUnit, to: self.engine.mainMixerNode, format: buffer.format)
			self.engine.connect(self.reverb, to: self.engine.mainMixerNode, format: sourceFile.processingFormat)
			
			self.player.scheduleBuffer(buffer, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
			//try self.engine.start()
			self.buffer = buffer
		} catch {
			self.sourceFile = nil
			throw ErrorType.initialError
		}
	}

	deinit {
		self.pause()
		Debug.DeinitLog(self)
	}

	public func play(time: Double = 0.0, deray: Double = 0.0) {
		self.deray = deray
		self.offSet = time
		if deray > 0.0 {
			self.onChangeStatus?(.delay)
			self.count = 0
			self.timer?.invalidate()
			self.timer = Timer.scheduledTimer(timeInterval: 30 / 1000, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
		} else {
			self._play(time: time, deray: deray)
		}
	}

	public func pause() {
		self.closeLink()
		self.player.pause()
		self.engine.stop()
		self.timer?.invalidate()
		self.timer = nil
		self.onChangeStatus?(.pause)
	}

	public func write(outputURL: URL, time: Double = 0.0, onProgress: ((_ progress: Float)->Void)?, onConplete: ((_ outputURL: URL)->Void)?) throws {
		self.engine.stop()
		self.player.stop()
		guard let sourceFile: AVAudioFile = self.sourceFile else { throw ErrorType.writeingError }

		let time: Double = time < 0.0 ? 0.0 : time
		
		let sampleRate = sourceFile.fileFormat.sampleRate
		let position: Double = time
		let newsampletime = AVAudioFramePosition(sampleRate * position)
		let length = Double(self.duration) - position
		let framestoplay = AVAudioFrameCount(sampleRate * length)
		if framestoplay > 100 {
			// 指定の位置から再生するようスケジューリング
			
			self.player.scheduleSegment(sourceFile, startingFrame: newsampletime, frameCount: framestoplay, at: nil, completionHandler: nil)
		}
		let maxNumberOfFrames: AVAudioFrameCount = 4096 // maximum number of frames the engine will be asked to render in any single render call
		
		if #available(iOS 11.0, *) {

			do {
				try self.engine.enableManualRenderingMode(.offline, format: sourceFile.processingFormat, maximumFrameCount: maxNumberOfFrames)
			} catch {
				throw ErrorType.renderFailed
			}
			
			// Start the engine and player
			do {
				try self.engine.start()
				self.player.play()
			} catch {
				throw ErrorType.renderFailed
			}

			// Start the engine and player
			let outputFile: AVAudioFile
			do {
				outputFile = try AVAudioFile(forWriting: outputURL, settings: sourceFile.processingFormat.settings)
			} catch {
				throw ErrorType.renderFailed
			}

			DispatchQueue.global().async { [weak self] in
				guard let engine: AVAudioEngine = self?.engine else { return }
				let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
				while engine.manualRenderingSampleTime < sourceFile.length {
					do {
						let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(sourceFile.length - engine.manualRenderingSampleTime))
						let status = try engine.renderOffline(framesToRender, to: buffer)
						switch status {
						case .success:
							try outputFile.write(from: buffer)
						case .insufficientDataFromInputNode:
							// applicable only if using the input node as one of the sources
							break
						case .cannotDoInCurrentContext:
							// engine could not render in the current render call, retry in next iteration
							break
						case .error:
							break
							//throw ErrorType.renderFailed
						@unknown default:
							break
						}
					} catch {
						//throw ErrorType.renderFailed
					}
					DispatchQueue.main.async {
						let p: Float = Float(engine.manualRenderingSampleTime) / Float(sourceFile.length)
						onProgress?(p)
					}
				}
				DispatchQueue.main.async { [weak self] in
					self?.engine.disableManualRenderingMode()
					self?.player.stop()
					self?.engine.stop()
					Debug.ActionLog("AVAudioEngine offline rendering completed")
					Debug.ActionLog("Output \(outputFile.url)")
					
					onConplete?(outputFile.url)
				}
			}

			
		} else {
			/*
	print(outputURL)
			do {
				let input = self.engine.inputNode
				//let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: engine.manualRenderingMaximumFrameCount)!
				let recordingFormat = input.outputFormat(forBus: 0)
				//let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
				AVAudioPCMBuffer(pcmFormat: <#T##AVAudioFormat#>, frameCapacity: <#T##AVAudioFrameCount#>)
				let buffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: self.engine.manualRenderingFormat, frameCapacity: self.engine.manualRenderingMaximumFrameCount)!
				let fff = try AVAudioFile.init(forWriting: outputURL, settings: sourceFile.processingFormat.settings)
				try fff.write(from: self.buffer!)
				/*
				input.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat, block: { (aBuffer, audioTime) in
					print(aBuffer, audioTime)
					try! fff.write(from: aBuffer)
				})
				//self.engine.prepare()
				try self.engine.start()
				self.player.play()
				 */
			} catch {
				
			}
				*/
		}
	}


	@objc func timerUpdate() {
		self.count += 30 / 1000
		if self.count >= self.deray {
			self.count = 0
			self.timer?.invalidate()
			self.timer = nil
			self._play(time: self.offSet, deray: self.deray)
			self.onChangeStatus?(.play)
		} else {
			self.onUpdate?( -Float(self.deray - self.count) )
		}
	}

	private func _play(time: Double = 0.0, deray: Double = 0.0) {
		if #available(iOS 11.0, *) {
			self.engine.disableManualRenderingMode()
		}
		self.engine.stop()
		self.player.stop()
		let sampleRate = self.sourceFile!.fileFormat.sampleRate
		let position: Double = time
		let newsampletime = AVAudioFramePosition(sampleRate * position)
		let length = Double(self.duration) - position
		let framestoplay = AVAudioFrameCount(sampleRate * length)
		if framestoplay > 100 {
			// 指定の位置から再生するようスケジューリング
			self.player.scheduleSegment(self.sourceFile!, startingFrame: newsampletime, frameCount: framestoplay, at: nil, completionHandler: nil)
		}
		do {
			self.startLink()
			try self.engine.start()
			self.player.play()
			self.onChangeStatus?(.play)
		} catch {
			
		}
	}



	/*
	public func write() {
		guard
			let file: AVAudioFile = self.file,
			let buffer: AVAudioPCMBuffer = self.buffer
			else { return }
		
		do {
			let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
			let uu = URL(fileURLWithPath: documentDir + "/sample.caf")
			
			//let filePath: String = NSTemporaryDirectory() + "ss.mp3"
			//let uu = URL.init(fileURLWithPath: filePath)
			print(uu)
			print(file.fileFormat.settings)
			let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
			
			
			let fff = try AVAudioFile.init(forWriting: uu, settings: format.settings)
			
			let input = self.engine.inputNode
			input.volume = 0
			print(buffer)
			print(input)
			print(buffer.frameLength)
			
			let recordingFormat = input.outputFormat(forBus: 0)
			input.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { (aBuffer, audioTime) in
				print(aBuffer)
				//try fff.write(from: buffer)
			})
			self.engine.prepare()
			try self.engine.start()
			
			//let recognitionTask = recognizer.recognitionTask(with: request, resultHandler: {/***/}
		} catch {
			
		}
	}
	*/

	public func pitchUp() {
		self.pitchUnit.pitch = self.pitchUnit.pitch + 100
	}

	public func pitchDown() {
		self.pitchUnit.pitch = self.pitchUnit.pitch - 100
	}

}

extension SoundPlayer {
	fileprivate func startLink() {
		self.closeLink()
		self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidRefresh))
		self.displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
	}

	fileprivate func closeLink() {
		self.displayLink?.remove(from: RunLoop.main, forMode: RunLoop.Mode.common)
		self.displayLink?.invalidate()
		self.displayLink = nil
	}

	@objc fileprivate func displayLinkDidRefresh() {
		Debug.ActionLog("\(self.time + Float(self.offSet)) / \(self.duration)")
		self.onUpdate?(self.time + Float(self.offSet))
		if self.duration <= (self.time + Float(self.offSet)) {
			self.pause()
		}
	}
}
