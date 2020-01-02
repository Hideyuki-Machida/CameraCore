//
//  VideoBitRateEncoder.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/01/19.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import AVFoundation

final public class VideoBitRateEncoder {
    
	public static var status: AVAssetWriter.Status {
        get{
            if let writer: VideoAssetWriter = VideoBitRateEncoder.videoAssetWriter {
                return writer.status
            }
			return AVAssetWriter.Status.unknown
        }
    }
    
    internal enum EncoderError: Error {
        case setupError
    }
	
	public enum Event {
		case progress(progress: Float)
		case complete(status: Bool, exportPath: URL?)
		case memoryWorning
	}
	
	public static var onEvent: ((_ e: Event)->Void)?
	
	fileprivate static var videoAssetWriter: VideoAssetWriter?
    fileprivate static var reader: AVAssetReader?
    fileprivate static var output: AVAssetReaderOutput?
    fileprivate static var exportPath: URL?
    fileprivate static var audioOutput: AVAssetReaderAudioMixOutput?
	fileprivate static var assetTimerange: CMTimeRange = CMTimeRange.zero
    fileprivate static let queue: DispatchQueue = DispatchQueue(label: "CameraCore.VideoBitRateEncoder.queue")
    
	public static func setup(property: VideoEncorderProperty) throws {
        do {
            let playerItem: AVPlayerItem = AVPlayerItem(asset: property.compositionData.composition)
            playerItem.videoComposition = property.compositionData.videoComposition
            playerItem.audioMix = property.compositionData.audioMix
			VideoBitRateEncoder.assetTimerange = CMTimeRangeMake(start: CMTime.zero, duration: playerItem.asset.duration)
            VideoBitRateEncoder.reader = try AVAssetReader(asset: playerItem.asset)
            ///////////////////////////////////////////////////
            // Videoトラック判定
            guard let videoCompositionTracks: [AVMutableCompositionTrack] = playerItem.asset.tracks(withMediaType: AVMediaType.video) as? [AVMutableCompositionTrack] else { throw EncoderError.setupError }
            // durationが0の場合データがない
            guard (videoCompositionTracks.filter { $0.timeRange.duration.value > 0 }).count >= 1 else { throw EncoderError.setupError }
            let videoOutputSettings: [String : Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : Configuration.outputPixelBufferPixelFormatTypeKey,
                kCVPixelBufferWidthKey as String: property.renderSize.width,
                kCVPixelBufferHeightKey as String: property.renderSize.height,
                kCVPixelBufferOpenGLESCompatibilityKey as String: true,
            ]
            let output: AVAssetReaderVideoCompositionOutput = AVAssetReaderVideoCompositionOutput(videoTracks: videoCompositionTracks, videoSettings: videoOutputSettings)
            output.videoComposition = property.compositionData.videoComposition
            output.alwaysCopiesSampleData = false
            if self.reader?.canAdd(output) == true {
                self.reader?.add(output)
                self.output = output
            }
            ///////////////////////////////////////////////////
            
            ///////////////////////////////////////////////////
            // 音声トラック判定
			if let audioCompositionTracks: [AVMutableCompositionTrack] = playerItem.asset.tracks(withMediaType: AVMediaType.audio) as? [AVMutableCompositionTrack] {
                let unNullAudioTrack: [AVMutableCompositionTrack] = audioCompositionTracks.filter { $0.timeRange.duration.value > 0 }
                if unNullAudioTrack.count >= 1 {

					let audioOutputSettings: [String : Any] = [
						AVFormatIDKey as String : kAudioFormatLinearPCM,
						AVSampleRateKey as String: 44100.0,
						AVLinearPCMBitDepthKey as String: 16,
						AVLinearPCMIsNonInterleaved as String: false,
						AVLinearPCMIsFloatKey as String: false,
						AVLinearPCMIsBigEndianKey as String: false,
					]
					
					let audio: AVAssetReaderAudioMixOutput = AVAssetReaderAudioMixOutput(audioTracks: unNullAudioTrack, audioSettings: audioOutputSettings)
                    audio.audioMix = playerItem.audioMix
                    audio.alwaysCopiesSampleData = false
                    if self.reader?.canAdd(audio) == true {
                        self.reader?.add(audio)
                        self.audioOutput = audio
                    }
                }
            }
			
			self.videoAssetWriter = VideoAssetWriter()
			try self.videoAssetWriter?.setup(property)

            self.exportPath = property.exportPath
        } catch {
            throw EncoderError.setupError
        }
    }
	
	
    public static func start() {
        self.reader?.startReading()
        
        if let error: NSError = self.reader?.error as NSError? {
            Debug.ErrorLog(error)
			VideoBitRateEncoder.onEvent?(.complete(status: false, exportPath: self.exportPath))
            return
        }
		
		do {
			try self.videoAssetWriter?.start()
			let duration: Double = VideoBitRateEncoder.assetTimerange.duration.seconds
			self.videoAssetWriter?.videoInput?.requestMediaDataWhenReady(on: VideoBitRateEncoder.queue) {
				VideoBitRateEncoder.encode(duration: duration)
			}
		} catch {
			
		}
    }
	
    public static func removeCache(exportPath: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: exportPath)
            return true
        } catch {
            return false
        }
    }
    
    public static func stop() throws {
		try VideoBitRateEncoder.videoAssetWriter?.stop()
		VideoBitRateEncoder.reader?.cancelReading()
		VideoBitRateEncoder.reader = nil
		VideoBitRateEncoder.output = nil
		VideoBitRateEncoder.audioOutput = nil
		VideoBitRateEncoder.stopFlg = true
		VideoBitRateEncoder.videoAssetWriter = nil
/*
		do {
			try VideoBitRateEncoder.videoAssetWriter?.stop()
			VideoBitRateEncoder.reader?.cancelReading()
			VideoBitRateEncoder.reader = nil
			VideoBitRateEncoder.output = nil
			VideoBitRateEncoder.audioOutput = nil
			VideoBitRateEncoder.stopFlg = true
			VideoBitRateEncoder.videoAssetWriter = nil
		} catch {
			
		}
*/
		//VideoBitRateEncoder.pixelBufferAdaptor = nil
    }
    
    fileprivate static func finish(complete: @escaping ()->Void) {
		do {
			try VideoBitRateEncoder.videoAssetWriter?.finish(complete: complete)
			VideoBitRateEncoder.reader = nil
			VideoBitRateEncoder.output = nil
			VideoBitRateEncoder.audioOutput = nil
			VideoBitRateEncoder.videoAssetWriter = nil
		} catch {
			
		}
    }
    
    fileprivate static func addBuffer(_ sampleBuffer: CMSampleBuffer, _ input: AVAssetWriterInput?) {
        while (input?.isReadyForMoreMediaData == false) {
            if input == nil { return }
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.1 , false)
        }
        
        input?.append(sampleBuffer)
    }
	
	
	fileprivate static let encodeCount: Int = 500000
	//fileprivate static let encodeCount: Int = 1
	fileprivate static var count: Int = 0
	fileprivate static var stopFlg: Bool = false
	fileprivate static func encode(duration: Double) {
		VideoBitRateEncoder.stopFlg = false
		let start: TimeInterval = Date().timeIntervalSince1970
		while true {
			if VideoBitRateEncoder.stopFlg {
				break
			}
			//let mem: UInt64 = getMemoryUsed()
			//if VideoBitRateEncoder.count < 5000 {
			if VideoBitRateEncoder.count < VideoBitRateEncoder.encodeCount {
				VideoBitRateEncoder.count += 1
			} else {
				VideoBitRateEncoder.count = 0
				/*
				if mem > 300 {
					print(mem)
					//VideoBitRateEncoder.onEvent?(.memoryWorning)
					//break
				}
				*/
				if !self.appendBuffer(duration: duration) {
					break
				}
			}
		}
		guard VideoBitRateEncoder.stopFlg != true else { return }
		let end: TimeInterval = Date().timeIntervalSince1970
		Debug.SuccessLog("time: \(end - start)")
		VideoBitRateEncoder.finish {
			DispatchQueue.main.async {
				//progress?(1.0)
				VideoBitRateEncoder.onEvent?(.progress(progress: 1.0))
				VideoBitRateEncoder.onEvent?(.complete(status: true, exportPath: VideoBitRateEncoder.exportPath))
				//self.videoComposition = nil
			}
		}
	}
	
	fileprivate static func appendBuffer(duration: Double) -> Bool {
		if VideoBitRateEncoder.videoAssetWriter?.videoInput?.isReadyForMoreMediaData == true, VideoBitRateEncoder.videoAssetWriter?.audioInput?.isReadyForMoreMediaData == true {
			if let videoSampleBuffer: CMSampleBuffer = VideoBitRateEncoder.output?.copyNextSampleBuffer() {
				let timestamp: CMTime = CMSampleBufferGetPresentationTimeStamp(videoSampleBuffer)
				let progressNum: Float = Float(timestamp.seconds / duration)
				let _ = VideoBitRateEncoder.videoAssetWriter?.addVideoBuffer(videoBuffer: videoSampleBuffer, timestamp: timestamp)
				if let audioSampleBuffer: CMSampleBuffer = VideoBitRateEncoder.audioOutput?.copyNextSampleBuffer() {
					VideoBitRateEncoder.videoAssetWriter?.addAudioBuffer(audioBuffer: audioSampleBuffer)
				}
				DispatchQueue.main.async {
					//let progressNum: Float = Float(timestamp.seconds / duration)
					VideoBitRateEncoder.onEvent?(.progress(progress: progressNum))
				}
			} else {
				return false
			}
		}
		return true
	}

}


func getMemoryUsed() -> UInt64 {
	// タスク情報を取得
	var info = mach_task_basic_info()
	// `info`の値からその型に必要なメモリを取得
	var count = UInt32(MemoryLayout.size(ofValue: info) / MemoryLayout<integer_t>.size)
	let result = withUnsafeMutablePointer(to: &info) {
		task_info(mach_task_self_,
				  task_flavor_t(MACH_TASK_BASIC_INFO),
				  // `task_info`の引数にするためにInt32のメモリ配置と解釈させる必要がある
			$0.withMemoryRebound(to: Int32.self, capacity: 1) { pointer in
				UnsafeMutablePointer<Int32>(pointer)
		}, &count)
	}
	// MB表記に変換して返却
	return result == KERN_SUCCESS ? info.resident_size / 1024 / 1024 : 0
}

