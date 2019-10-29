//
//  MaskLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class MaskLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.mask
    public var id: RenderLayerId
    public let mask: CIImage
    public var customIndex: Int = 0
    public var maskShader: CIColorKernel
    
    public init(mask: CIImage) {
        self.id = RenderLayerId()
        
        let maskShaderPath: URL = AssetManager.Shader.mask.url()
        let maskShaderString: String = try! String(contentsOf: maskShaderPath, encoding: .utf8)
        self.maskShader = CIColorKernel(source: maskShaderString)!
        self.mask = mask
    }

    fileprivate init(id: RenderLayerId, mask: CIImage) {
        self.id = id
        
        let maskShaderPath: URL = AssetManager.Shader.mask.url()
        let maskShaderString: String = try! String(contentsOf: maskShaderPath, encoding: .utf8)
        self.maskShader = CIColorKernel(source: maskShaderString)!
        self.mask = mask
    }
    
    public func dispose() { }
}

extension MaskLayer: MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard let image: CIImage = CIImage.init(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.setupError }
        
        let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let outImage = try self.process(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        MCCore.ciContext.render(outImage, to: destination, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
    }

    fileprivate func process(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
        let image: CIImage = self.maskShader.apply(extent: image.extent, arguments: [
            image,
            self.mask,
            CIVector(x: image.extent.width, y: image.extent.height),
            ])!
        
        return image
    }

}
