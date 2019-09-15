//
//  RenderLayer.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/07.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation
import Metal


///////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - RenderLayerErrorType
public enum RenderLayerErrorType: Error {
    case decodeError
	case setupError
	case renderingError
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - ImageProcessing

// MARK: レンダリングレイヤータイプ
public enum RenderLayerType: Int, Codable {
	case blank = 0
	case transformLayer = 1
	case image = 2
	case lut = 3
    case sequenceImage = 4
    case mask = 5
    case colorOverlay = 6

    case metalImageBlend = 100
	
	case group = 1000
	
    case custom = 9999

    public func type() -> RenderLayerProtocol.Type? {
        switch self {
        case .blank: return BlankLayer.self
        case .transformLayer: return TransformLayer.self
        case .image: return ImageLayer.self
        case .lut: return LutLayer.self
        case .sequenceImage: return SequenceImageLayer.self
        case .mask: return MaskLayer.self
        case .colorOverlay: return ColorOverlayLayer.self
		case .group: return GroupLayer.self
        case .custom: return nil
		case .metalImageBlend: return MetalImageBlendLayer.self
		}
    }
}

// MARK: レンダリングブレンドモード
public enum Blendmode: String, Codable {
	case alpha = "alpha"
	case addition = "addition" // 加算
	case multiplication = "multiplication" // 乗算
	case screen = "screen"
	case softLight = "softLight"
	case hardLight = "hardLight"
	case overlay = "overlay"
	
	public func CIFilterName() -> String {
		switch self {
		case .alpha: return "CISourceAtopCompositing"
		case .addition: return "CIAdditionCompositing"
		case .multiplication: return "CIMultiplyCompositing"
		case .screen: return "CIScreenBlendMode"
		case .softLight: return "CISoftLightBlendMode"
		case .hardLight: return "CIHardLightBlendMode"
		case .overlay: return "CIOverlayBlendMode"
		}
	}
}

// MARK: レンダリングレイヤー protocol
public protocol RenderLayerProtocol {
	var id: RenderLayerId { get }
    var type: RenderLayerType { get }
    var customIndex: Int { get }
    mutating func setup(assetData: CompositionVideoAsset)
	
	/*
	mutating func processing(commandBuffer: inout MTLCommandBuffer, sourceTexture: inout MTLTexture, destinationTexture: inout MTLTexture, sourcePixelBuffer: inout CVPixelBuffer, destinationPixelBuffer: inout CVPixelBuffer, renderSize: CGSize) -> Void
*/
	mutating func dispose()
    //func toJsonData() throws -> Data
    //static func decode(to: Data) throws -> RenderLayerProtocol
}

public protocol CIImageRenderLayerProtocol: RenderLayerProtocol {
	mutating func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage
}

public protocol MetalRenderLayerProtocol: RenderLayerProtocol {
	mutating func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> Void
}

public protocol OpenGLRenderLayerProtocol: RenderLayerProtocol {
	mutating func processing(pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> Void
}

public protocol CVPixelBufferRenderLayerProtocol: RenderLayerProtocol {
	mutating func processing(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> Void
}
