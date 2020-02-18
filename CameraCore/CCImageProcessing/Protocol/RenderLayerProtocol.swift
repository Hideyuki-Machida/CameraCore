//
//  RenderLayerProtocol.swift
//  CameraCore
//
//  Created by machidahideyuki on 2018/01/07.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import CoreImage
import Metal
import UIKit
import MetalCanvas

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

    //case imageBlend = 100

    case custom = 9999

    public var type: RenderLayerProtocol.Type? {
        switch self {
        case .blank: return CCImageProcessing.BlankLayer.self
        case .transformLayer: return CCImageProcessing.TransformLayer.self
        case .image: return CCImageProcessing.ImageLayer.self
        case .lut: return CCImageProcessing.LutLayer.self
        case .sequenceImage: return CCImageProcessing.SequenceImageLayer.self
        case .mask: return CCImageProcessing.MaskLayer.self
        case .colorOverlay: return CCImageProcessing.ColorOverlayLayer.self
        //case .imageBlend: return CCImageProcessing.ImageBlendLayer.self
        case .custom: return nil
        }
    }
}

// MARK: レンダリングブレンドモード

public enum Blendmode: String, Codable {
    case alpha
    case addition // 加算
    case multiplication // 乗算
    case screen // スクリーン
    case softLight // ソフトライト
    case hardLight // ハードライト
    case overlay // オーバーレイ

    public var CIFilterName: String {
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
    var id: CCImageProcessing.RenderLayerId { get }
    var type: RenderLayerType { get }
    var customIndex: Int { get }
    mutating func dispose()
    mutating func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws
}

public extension RenderLayerProtocol {
    func blitEncoder(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture) throws {
        guard source.size == destination.size else { throw RenderLayerErrorType.renderingError }
        let blitEncoder: MTLBlitCommandEncoder? = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: source.texture,
                          sourceSlice: 0,
                          sourceLevel: 0,
                          sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                          sourceSize: MTLSizeMake(source.texture.width, source.texture.height, source.texture.depth),
                          to: destination.texture,
                          destinationSlice: 0,
                          destinationLevel: 0,
                          destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder?.endEncoding()
    }
}
