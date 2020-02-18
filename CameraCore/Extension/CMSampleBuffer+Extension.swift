//
//  CMSampleBuffer+Extension.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/03.
//  Copyright © 2020 Donuts. All rights reserved.
//

import AVFoundation
import Foundation

public extension CMSampleBuffer {
    static func create(from pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription, timingInfo: inout CMSampleTimingInfo) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil,
                                           refcon: nil, formatDescription: formatDescription, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
        return sampleBuffer
    }

    static func create(audioPCMBuffer: AVAudioPCMBuffer, audioTime: AVAudioTime) -> CMSampleBuffer? {
        var asbd: AudioStreamBasicDescription = audioPCMBuffer.format.streamDescription.pointee
        var formatDescriptionOut: CMAudioFormatDescription? = nil
    
        let audioFormatDescriptionCreateStatus: OSStatus = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescriptionOut
        )
        guard audioFormatDescriptionCreateStatus == noErr else { return nil }

        let presentationTimeStamp: CMTime = CMTime.init(value: Int64(audioTime.audioTimeStamp.mSampleTime), timescale: CMTimeScale(asbd.mSampleRate))
        var timingInfo: CMSampleTimingInfo = CMSampleTimingInfo.init(duration: CMTime.init(value: 1, timescale: CMTimeScale(asbd.mSampleRate)), presentationTimeStamp: presentationTimeStamp, decodeTimeStamp: CMTime.zero)

        var sampleBuffer: CMSampleBuffer? = nil
        let status002: OSStatus = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescriptionOut,
            sampleCount: CMItemCount(audioPCMBuffer.frameLength),
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        guard status002 == noErr else { return nil }
        print("@@@")
        
        let status003: OSStatus = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer!, blockBufferAllocator: kCFAllocatorDefault, blockBufferMemoryAllocator: kCFAllocatorDefault, flags: 0, bufferList: audioPCMBuffer.audioBufferList)
        guard status003 == noErr else { return nil }
        print("@@@1")

        return sampleBuffer
    }

}
