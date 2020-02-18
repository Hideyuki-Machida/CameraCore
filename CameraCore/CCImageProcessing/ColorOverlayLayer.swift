//
//  ColorOverlayLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas

public extension CCImageProcessing {
    final class ColorOverlayLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.colorOverlay
        public let id: RenderLayerId
        public let customIndex: Int = 0
        private let color: CIVector
        private var offset: Float = 0
        private let fragmentShader: CIColorKernel

        public convenience init(color: UIColor, offset: Float) throws {
            try self.init(id: RenderLayerId(), color: color, offset: offset)
        }

        public init(id: RenderLayerId, color: UIColor, offset: Float) throws {
            self.id = id
            let color: CIColor = CIColor(cgColor: color.cgColor)
            self.color = CIVector(x: color.red, y: color.green, z: color.blue)

            let fragmentShaderPath: URL = AssetManager.Shader.colorOverlay.url
            let fragmentShaderString: String = try String(contentsOf: fragmentShaderPath, encoding: .utf8)
            guard let fragmentShader: CIColorKernel = CIColorKernel(source: fragmentShaderString) else { throw RenderLayerErrorType.setupError }
            self.fragmentShader = fragmentShader
            self.offset = offset
        }

        public func update(offset: Float) {
            self.offset = offset
        }

        public func dispose() {}
    }
}

public extension CCImageProcessing.ColorOverlayLayer {
    func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard let image: CIImage = CIImage(mtlTexture: source.texture, options: nil) else { throw RenderLayerErrorType.renderingError }
        let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let outImage: CIImage = try self.processing(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        MCCore.ciContext.render(outImage, to: destination.texture, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
    }
}

fileprivate extension CCImageProcessing.ColorOverlayLayer {
    func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
        let arguments: [Any] = [
            image,
            CIVector(x: image.extent.width, y: image.extent.height),
            self.color,
            NSNumber(value: self.offset),
        ]

        guard let img: CIImage = self.fragmentShader.apply(extent: image.extent, arguments: arguments) else {
            throw RenderLayerErrorType.renderingError
        }

        return img
    }
}
