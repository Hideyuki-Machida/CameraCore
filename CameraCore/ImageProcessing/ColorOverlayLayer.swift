//
//  ColorOverlay.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class ColorOverlayLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.colorOverlay
    public let id: RenderLayerId
    public var customIndex: Int = 0
    private var color: CIVector = CIVector(x: 1.0, y: 1.0, z: 1.0)
    private var offset: Float = 0
    private var _transitionThreshold: Float = 0
    private let _fragmentShader: CIColorKernel?
    
    public init(color: UIColor, offset: Float) {
        self.id = RenderLayerId()
        let color: CIColor = CIColor(cgColor: color.cgColor)
        self.color = CIVector(x: color.red, y: color.green, z: color.blue)

        let fragmentShaderPath: URL = AssetManager.Shader.colorOverlay.url()
        let fragmentShaderString: String = try! String(contentsOf: fragmentShaderPath, encoding: .utf8)
        self._fragmentShader = CIColorKernel(source: fragmentShaderString)!
        
        self.offset = offset
    }

    fileprivate init(id: RenderLayerId, color: UIColor, offset: Float) {
        self.id = id
        let color: CIColor = CIColor(cgColor: color.cgColor)
        self.color = CIVector(x: color.red, y: color.green, z: color.blue)
        
        let fragmentShaderPath: URL = AssetManager.Shader.colorOverlay.url()
        let fragmentShaderString: String = try! String(contentsOf: fragmentShaderPath, encoding: .utf8)
        self._fragmentShader = CIColorKernel(source: fragmentShaderString)!
        
        self.offset = offset
    }
    
    //public func setup(assetData: CompositionVideoAsset) { }
    
    public func update(offset: Float) {
        self.offset = offset
    }
    
    public func dispose() { }
}

extension ColorOverlayLayer: MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard let image: CIImage = CIImage.init(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.setupError }
        let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()        
        let outImage: CIImage = try self.processing(image: image, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        MCCore.ciContext.render(outImage, to: destination, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
    }

    fileprivate func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
        let img: CIImage? = self._fragmentShader!.apply(extent: image.extent, arguments: [
            image,
            CIVector(x: image.extent.width, y: image.extent.height),
            self.color,
            NSNumber(value: self.offset)
            ])
        
        if let img: CIImage = img {
            return img
        } else {
            throw CCRenderer.ErrorType.rendering
        }
    }

}
