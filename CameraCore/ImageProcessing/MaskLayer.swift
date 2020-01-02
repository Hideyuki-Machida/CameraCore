//
//  MaskLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas

public extension CCImageProcessing {
    final class MaskLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.mask
        public let id: RenderLayerId
        public let mask: CIImage
        public let customIndex: Int = 0
        public let maskShader: CIColorKernel

        public convenience init(mask: CIImage) throws {
            try self.init(id: RenderLayerId(), mask: mask)
        }

        public init(id: RenderLayerId, mask: CIImage) throws {
            self.id = id

            let maskShaderPath: URL = AssetManager.Shader.mask.url
            let maskShaderString: String = try String(contentsOf: maskShaderPath, encoding: .utf8)
            guard let maskShader: CIColorKernel = CIColorKernel(source: maskShaderString) else { throw RenderLayerErrorType.setupError }
            self.maskShader = maskShader
            self.mask = mask
        }

        public func dispose() {}
    }
}

public extension CCImageProcessing.MaskLayer {
    func process(commandBuffer: MTLCommandBuffer, source: MCTexture, destination: inout MCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard let image: CIImage = CIImage(mtlTexture: source.texture, options: nil) else { throw RenderLayerErrorType.renderingError }

        let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let outImage = try self.process(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        MCCore.ciContext.render(outImage, to: destination.texture, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
    }
}

fileprivate extension CCImageProcessing.MaskLayer {
    func process(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
        guard
            let image: CIImage = self.maskShader.apply(extent: image.extent, arguments: [
                image,
                self.mask,
                CIVector(x: image.extent.width, y: image.extent.height),
            ])
        else { throw RenderLayerErrorType.renderingError }

        return image
    }
}
