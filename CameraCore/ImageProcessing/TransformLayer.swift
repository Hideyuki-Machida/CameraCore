//
//  TransformLayer.swift
//  MystaVideoModule
//
//  Created by 町田 秀行 on 2018/01/21.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import UIKit
import AVFoundation
import MetalCanvas

final public class TransformLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.transformLayer
    public let id: RenderLayerId
    public let customIndex: Int = 0
    public var isAfter: Bool = false
    public var preferredTransform: CGAffineTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
    public var transform: CGAffineTransform
    public var finalTransform: CGAffineTransform?
    public var backgroundColor: UIColor

    public init(transform: CGAffineTransform, backgroundColor: UIColor) {
        self.id = RenderLayerId()
        self.transform = transform
        self.backgroundColor = backgroundColor
    }

    fileprivate init(id: RenderLayerId, transform: CGAffineTransform, backgroundColor: UIColor) {
        self.id = id
        self.transform = transform
        self.backgroundColor = backgroundColor
    }

    public func dispose() {}
}

extension TransformLayer: MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard let image: CIImage = CIImage.init(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.setupError }
        let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let outImage = self.process(image: image, compositionTime: renderLayerCompositionInfo.compositionTime, timeRange: renderLayerCompositionInfo.timeRange, percentComplete: Float(renderLayerCompositionInfo.percentComplete), renderSize: renderLayerCompositionInfo.renderSize) else { throw RenderLayerErrorType.setupError }
        MCCore.ciContext.render(outImage, to: destination, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
    }

    private func process(image: CIImage, compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Float, renderSize: CGSize) -> CIImage? {
        let transformImage: CIImage = image.transformed(by: self.transform)
        let croppingImage: CIImage = transformImage.cropped(to: CGRect(origin: CGPoint.zero, size: renderSize))
        let result: CIFilter = CIFilter(name: Blendmode.alpha.CIFilterName())!
        result.setValue(CIImage(color: CIColor(cgColor: self.backgroundColor.cgColor)), forKey: kCIInputBackgroundImageKey)
        result.setValue(croppingImage, forKey: kCIInputImageKey)
        let croppingImage002: CIImage = result.outputImage!.cropped(to: CGRect(origin: CGPoint.zero, size: renderSize))
        return croppingImage002
    }
}
