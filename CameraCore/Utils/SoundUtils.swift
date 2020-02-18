//
//  SoundUtils.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/04/09.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MetalCanvas

public final class SoundUtils {
	public static let shared = SoundUtils()

	public func brank(url: URL) -> Double {
		do {
			let audioFile = try AVAudioFile(forReading: url)
			let rate: Int = Int(audioFile.fileFormat.sampleRate)
			let frameCount = UInt32(audioFile.length)
			//let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
			let PCMBuffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount)!
			try audioFile.read(into: PCMBuffer, frameCount: frameCount)
			for i in 0..<audioFile.fileFormat.channelCount - 1 {
				let buf: [Float] = Array(UnsafeMutableBufferPointer(start: PCMBuffer.floatChannelData![Int(i)], count: Int(frameCount)))
				for (index, value) in buf.enumerated() {
					if value > 0 {
						return Double(index / rate)
					}
				}
			}
			
			//self.ffmpeg(url: url)
		} catch {
			MCDebug.log(url)
		}
		return 0
	}

}
