//
//  CustomVideoCompositionInstruction.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/15.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import AVFoundation


class CustomVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
	
	var compositionVideoAsset: CompositionVideoAssetProtocol?
	var compositionVideoTrack: CompositionVideoTrackProtocol?
	var croppingRect: CGRect?
	
	
	/// The timeRange during which instructions will be effective.
	var overrideTimeRange: CMTimeRange = CMTimeRange()
	/// Indicates whether post-processing should be skipped for the duration of the instruction.
	var overrideEnablePostProcessing = false
	
	/// Indicates whether to avoid some duplicate processing when rendering a frame from the same source and destinatin at different times.
	var overrideContainsTweening = false
	/// The track IDs required to compose frames for the instruction.
	var overrideRequiredSourceTrackIDs: [NSValue]?
	/// Track ID of the source frame when passthrough is in effect.
	var overridePassthroughTrackID: CMPersistentTrackID = 0
	
	/*
	If for the duration of the instruction, the video composition result is one of the source frames, this property
	should return the corresponding track ID. The compositor won't be run for the duration of the instruction and
	the proper source frame will be used instead.
	*/
	var passthroughTrackID: CMPersistentTrackID {
		
		get {
			return self.overridePassthroughTrackID
		}
		set {
			self.overridePassthroughTrackID = newValue
		}
	}
	
	/*
	List of video track IDs required to compose frames for this instruction. If the value of this property
	is nil, all source tracks will be considered required for composition.
	*/
	var requiredSourceTrackIDs: [NSValue]? {
		
		get {
			return self.overrideRequiredSourceTrackIDs
		}
		
		set {
			self.overrideRequiredSourceTrackIDs = newValue
		}
	}
	
	// Indicates the timeRange during which the instruction is effective.
	var timeRange: CMTimeRange {
		
		get {
			return self.overrideTimeRange
		}
		
		set(newTimeRange) {
			self.overrideTimeRange = newTimeRange
		}
	}
	
	// If NO, indicates that post-processing should be skipped for the duration of this instruction.
	var enablePostProcessing: Bool {
		
		get {
			return self.overrideEnablePostProcessing
		}
		
		set(newPostProcessing) {
			self.overrideEnablePostProcessing = newPostProcessing
		}
	}
	
	/*
	If YES, rendering a frame from the same source buffers and the same composition instruction at 2 different
	compositionTime may yield different output frames. If NO, 2 such compositions would yield the
	same frame. The media pipeline may me able to avoid some duplicate processing when containsTweening is NO.
	*/
	var containsTweening: Bool {
		
		get {
			return self.overrideContainsTweening
		}
		
		set(newContainsTweening) {
			self.overrideContainsTweening = newContainsTweening
		}
	}
	
	init(thePassthroughTrackID: CMPersistentTrackID, forTimeRange theTimeRange: CMTimeRange) {
		super.init()
		
		passthroughTrackID = thePassthroughTrackID
		timeRange = theTimeRange
		
		requiredSourceTrackIDs = [NSValue]()
		containsTweening = false
		enablePostProcessing = false
	}
	
	init(theSourceTrackIDs: [NSValue], forTimeRange theTimeRange: CMTimeRange) {
		super.init()
		
		requiredSourceTrackIDs = theSourceTrackIDs
		timeRange = theTimeRange
		
		passthroughTrackID = kCMPersistentTrackID_Invalid
		containsTweening = true
		enablePostProcessing = false
	}
	
}
