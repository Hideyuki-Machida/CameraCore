//
//  ImageLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas

public extension CCImageProcessing {
    /// ImageLayer 画像オーバーレイエフェクト
    final class ImageLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.image
        public let id: RenderLayerId
        public let customIndex: Int = 0
        public let transform: CGAffineTransform
        private let imagePath: URL
        private let blendMode: Blendmode
        private let alpha: CGFloat
        private let renderSize: CGSize
        private let contentMode: CompositionImageLayerContentMode
        private var contentModeTransform: CGAffineTransform?
        private var _image: CIImage?
        private var overTexture: CCTexture?

        public convenience init(imagePath: URL, blendMode: Blendmode, alpha: CGFloat = 1.0, renderSize: CGSize, contentMode: CompositionImageLayerContentMode = .none, transform: CGAffineTransform? = nil) {
            self.init(id: RenderLayerId(), imagePath: imagePath, blendMode: blendMode, alpha: alpha, renderSize: renderSize, contentMode: contentMode, transform: transform)
        }

        public init(id: RenderLayerId, imagePath: URL, blendMode: Blendmode, alpha: CGFloat = 1.0, renderSize: CGSize, contentMode: CompositionImageLayerContentMode = .none, transform: CGAffineTransform? = nil) {
            self.id = id
            self.imagePath = imagePath
            self.blendMode = blendMode
            self.alpha = alpha
            self.renderSize = renderSize
            self.contentMode = contentMode
            self.transform = transform ?? CGAffineTransform.identity
        }

        public func dispose() {
            self._image = nil
        }
    }
}

public extension CCImageProcessing.ImageLayer {
    func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard var inputImage: CIImage = CIImage(mtlTexture: source.texture, options: nil) else { throw RenderLayerErrorType.renderingError }
        inputImage = try self.process(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let commandBuffer: MTLCommandBuffer = MCCore.commandQueue.makeCommandBuffer() else { return }
        MCCore.ciContext.render(inputImage, to: destination.texture, commandBuffer: commandBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
        commandBuffer.commit()
    }
}


fileprivate extension CCImageProcessing.ImageLayer {
    func process(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
        // フィルターイメージ生成
        if let selfImage = self._image {
            // フィルター合成
            guard let result: CIFilter = CIFilter(name: self.blendMode.CIFilterName) else { throw RenderLayerErrorType.renderingError }
            result.setValue(image, forKey: kCIInputBackgroundImageKey)
            result.setValue(selfImage, forKey: kCIInputImageKey)

            return result.outputImage ?? image
        } else {
            // フィルターイメージ作成
            guard var effect: CIImage = CIImage(contentsOf: self.imagePath) else { throw RenderLayerErrorType.renderingError }

            // 上下反転
            effect = effect.transformed(by: CGAffineTransform(scaleX: 1, y: -1.0).translatedBy(x: 0, y: -CGFloat(effect.extent.height)))

            if self.contentModeTransform == nil {
                let imageSize: CGSize = effect.extent.size
                self.contentModeTransform = self.contentMode.transform(imageSize: imageSize, renderSize: self.renderSize)
            }

            guard let colorMatrixFilter: CIFilter = CIFilter(name: "CIColorMatrix") else { throw RenderLayerErrorType.renderingError }
            colorMatrixFilter.setValue(effect, forKey: kCIInputImageKey)
            colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: self.alpha), forKey: "inputAVector")

            ///////////////////////////////////////////////////////////////////////////////////////////////////
            // まずcontentModeの設定を反映
            guard
                let alphaImage: CIImage = colorMatrixFilter.outputImage,
                let contentModeTransform: CGAffineTransform = self.contentModeTransform,
                let contentModeTransformFilter: CIFilter = CIFilter(name: "CIAffineTransform")
            else { throw RenderLayerErrorType.renderingError }

            contentModeTransformFilter.setValue(alphaImage, forKey: kCIInputImageKey)
            contentModeTransformFilter.setValue(NSValue(cgAffineTransform: contentModeTransform), forKey: "inputTransform")
            guard let contentModeTransformImage: CIImage = contentModeTransformFilter.outputImage else { throw RenderLayerErrorType.renderingError }
            ///////////////////////////////////////////////////////////////////////////////////////////////////

            ///////////////////////////////////////////////////////////////////////////////////////////////////
            // まずcontentModeの設定を反映
            let transform: CGAffineTransform = TransformUtils.convertTransformSKToCI(
                userTransform: self.transform,
                videoSize: image.extent.size,
                renderSize: renderSize,
                preferredTransform: CGAffineTransform.identity
            )

            guard let transformFilter: CIFilter = CIFilter(name: "CIAffineTransform") else { throw RenderLayerErrorType.renderingError }
            transformFilter.setValue(contentModeTransformImage, forKey: kCIInputImageKey)
            transformFilter.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
            guard var transformImage: CIImage = transformFilter.outputImage else { throw RenderLayerErrorType.renderingError }
            transformImage = transformImage.cropped(to: CGRect(origin: CGPoint(x: 0, y: 0), size: self.renderSize))
            ///////////////////////////////////////////////////////////////////////////////////////////////////

            self._image = transformImage

            // フィルター合成
            guard let result: CIFilter = CIFilter(name: self.blendMode.CIFilterName) else { throw RenderLayerErrorType.renderingError }

            result.setValue(image, forKey: kCIInputBackgroundImageKey)
            result.setValue(transformImage, forKey: kCIInputImageKey)
            return result.outputImage ?? image
        }
    }
}

extension CCImageProcessing.ImageLayer {
    // 設計されているが、まだ未実装のenum項目をコメントアウト
    public enum CompositionImageLayerContentMode: Int, Codable {
        // case scaleToFill = 0
        // case scaleAspectFit
        case scaleAspectFill = 2
        // case redraw
        // case center
        // case top
        // case bottom
        // case left
        // case right
        // case topLeft
        // case topRight
        // case bottomLeft
        // case bottomRight
        case none

        public func transform(imageSize: CGSize, renderSize: CGSize) -> CGAffineTransform {
            switch self {
            // case .scaleToFill: return CGAffineTransform.identity
            // case .scaleAspectFit: return CGAffineTransform.identity
            case .scaleAspectFill: return CompositionImageLayerContentModeTransform.scaleAspectFill(imageSize: imageSize, renderSize: renderSize)
            // case .scaleAspectFill: return CGAffineTransform.identity
            // case .redraw: return CGAffineTransform.identity
            // case .center: return CGAffineTransform.identity
            // case .top: return CGAffineTransform.identity
            // case .bottom: return CGAffineTransform.identity
            // case .left: return CGAffineTransform.identity
            // case .right: return CGAffineTransform.identity
            // case .topLeft: return CGAffineTransform.identity
            // case .topRight: return CGAffineTransform.identity
            // case .bottomLeft: return CGAffineTransform.identity
            // case .bottomRight: return CGAffineTransform.identity
            case .none: return CGAffineTransform.identity
            }
        }
    }

    // swiftlint:disable:next type_name
    class CompositionImageLayerContentModeTransform {
        // swiftlint:disable:previous type_name
        public static func scaleAspectFill(imageSize: CGSize, renderSize: CGSize) -> CGAffineTransform {
            guard renderSize != imageSize else { return CGAffineTransform(scaleX: 1.0, y: 1.0) }

            let originalSize: CGSize = CGSize(width: imageSize.width, height: imageSize.height)

            // スケールを設定
            let scaleW: CGFloat = renderSize.width / originalSize.width
            let scaleH: CGFloat = renderSize.height / originalSize.height

            let scale: CGFloat = scaleW > scaleH ? scaleW : scaleH
            let resizeSize: CGSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)

            let resultTransform: CGAffineTransform = CGAffineTransform(scaleX: scale, y: scale)
                .translatedBy(x: ((renderSize.width / 2) - (resizeSize.width / 2)) * (1 / scale),
                              y: ((renderSize.height / 2) - (resizeSize.height / 2)) * (1 / scale))
            return resultTransform
        }
    }

}
