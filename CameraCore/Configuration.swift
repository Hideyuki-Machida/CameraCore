//
//  Configuration.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/08.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import AVFoundation

public struct Configuration {
	//public static var captureSize: Settings.PresetiFrame = .p1920x1080
	public static var captureSize: Settings.PresetiFrame = .p1280x720
	public static var captureFramerate: Int32 = 30
	public static var compositionFramerate: Int32 = 30
	public static var timeScale: Int32 = 44100
	
	// kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange について
	// http://kentaroid.com/kcvpixelformattype%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6%E3%81%AE%E8%80%83%E5%AF%9F/
	public static var sourcePixelBufferPixelFormatTypeKey: OSType = kCVPixelFormatType_32BGRA
	//public static var outputPixelBufferPixelFormatTypeKey: OSType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
	public static var outputPixelBufferPixelFormatTypeKey: OSType = kCVPixelFormatType_32BGRA
	
	public static var colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
	//public static var colorSpace: CGColorSpace = CGColorSpace.init(name: CGColorSpace.displayP3)!
}
