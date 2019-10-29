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

    case ImageBlend = 100
    
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
        case .ImageBlend: return ImageBlendLayer.self
        case .custom: return nil
        }
    }
}

// MARK: レンダリングブレンドモード
public enum Blendmode: String, Codable {
    case alpha = "alpha"
    case addition = "addition" // 加算
    case multiplication = "multiplication" // 乗算
    case screen = "screen" //スクリーン
    case softLight = "softLight" //ソフトライト
    case hardLight = "hardLight" //ハードライト
    case overlay = "overlay" //オーバーレイ

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
    mutating func dispose()
}

public protocol MetalRenderLayerProtocol: RenderLayerProtocol {
    mutating func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> Void
}

public protocol CVPixelBufferRenderLayerProtocol: RenderLayerProtocol {
    mutating func process(commandBuffer: inout MTLCommandBuffer, pixelBuffer: inout CVPixelBuffer, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> Void
}
