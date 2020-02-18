//
//  TransformLayer.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/01/21.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas
import UIKit

public extension CCImageProcessing {
    final class TransformLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.transformLayer
        public let id: RenderLayerId
        public let customIndex: Int = 0
        public let transform: CGAffineTransform
        public let backgroundColor: UIColor

        public convenience init(transform: CGAffineTransform, backgroundColor: UIColor) {
            self.init(id: RenderLayerId(), transform: transform, backgroundColor: backgroundColor)
        }

        public init(id: RenderLayerId, transform: CGAffineTransform, backgroundColor: UIColor) {
            self.id = id
            self.transform = transform
            self.backgroundColor = backgroundColor
        }

        public func dispose() {}
    }
}

public extension CCImageProcessing.TransformLayer {
    func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard let image: CIImage = CIImage(mtlTexture: source.texture, options: nil) else { throw RenderLayerErrorType.renderingError }
        let colorSpace: CGColorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let outImage = try self.process(image: image,
                                        compositionTime: renderLayerCompositionInfo.compositionTime,
                                        timeRange: renderLayerCompositionInfo.timeRange,
                                        percentComplete: Float(renderLayerCompositionInfo.percentComplete),
                                        renderSize: renderLayerCompositionInfo.renderSize)
        MCCore.ciContext.render(outImage, to: destination.texture, commandBuffer: commandBuffer, bounds: outImage.extent, colorSpace: colorSpace)
    }
}

private extension CCImageProcessing.TransformLayer {
    func process(image: CIImage, compositionTime: CMTime, timeRange: CMTimeRange, percentComplete: Float, renderSize: MCSize) throws -> CIImage {
        let transformImage: CIImage = image.transformed(by: self.transform)
        let croppingImage: CIImage = transformImage.cropped(to: CGRect(origin: CGPoint.zero, size: renderSize.toCGSize()))
        guard let result: CIFilter = CIFilter(name: Blendmode.alpha.CIFilterName) else { throw RenderLayerErrorType.renderingError }
        result.setValue(CIImage(color: CIColor(cgColor: self.backgroundColor.cgColor)), forKey: kCIInputBackgroundImageKey)
        result.setValue(croppingImage, forKey: kCIInputImageKey)
        guard let croppingImage002: CIImage = result.outputImage?.cropped(to: CGRect(origin: CGPoint.zero, size: renderSize.toCGSize())) else { throw RenderLayerErrorType.renderingError }
        return croppingImage002
    }
}
