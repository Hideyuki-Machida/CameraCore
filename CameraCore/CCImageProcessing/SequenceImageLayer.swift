//
//  SequenceImageLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas

public extension CCImageProcessing {
    final class SequenceImageLayer: RenderLayerProtocol {
        public let type: RenderLayerType = RenderLayerType.sequenceImage
        public let id: RenderLayerId
        public let customIndex: Int = 0
        private let imagePaths: [URL]
        private let blendMode: Blendmode
        private let alpha: CGFloat
        private let updateFrameRate: TimeInterval
        private let resize: Bool
        private var filterCacheImageList: [Int: CIImage] = [:] // エフェクトフィルターキャッシュ

        public init(imagePaths: [URL], blendMode: Blendmode, alpha: CGFloat = 1.0, updateFrameRate: Int32 = 30, resize: Bool = true) {
            self.id = RenderLayerId()
            self.imagePaths = imagePaths.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            self.blendMode = blendMode
            self.alpha = alpha
            self.updateFrameRate = TimeInterval(updateFrameRate)
            self.resize = resize
        }

        fileprivate init(id: RenderLayerId, imagePaths: [URL], blendMode: Blendmode, alpha: CGFloat = 1.0, updateFrameRate: TimeInterval = 30, resize: Bool = true) {
            self.id = id
            self.imagePaths = imagePaths.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            self.blendMode = blendMode
            self.alpha = alpha
            self.updateFrameRate = updateFrameRate
            self.resize = resize
        }

        /// キャッシュを消去
        public func dispose() {
            self.filterCacheImageList.removeAll()
        }
    }
}

public extension CCImageProcessing.SequenceImageLayer {
    func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard
            !self.imagePaths.isEmpty,
            var inputImage: CIImage = CIImage(mtlTexture: source.texture, options: nil)
        else { throw RenderLayerErrorType.renderingError }

        inputImage = try process(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        MCCore.ciContext.render(inputImage, to: destination.texture, commandBuffer: commandBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
    }
}

fileprivate extension CCImageProcessing.SequenceImageLayer {
    func process(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
        let imageCounter: Float = Float(renderLayerCompositionInfo.compositionTime.value) * Float(self.updateFrameRate) / Float(renderLayerCompositionInfo.compositionTime.timescale)

        // フィルターイメージ生成
        let counter: Int = Int(floorf(imageCounter)) % self.imagePaths.count
        var filterImage: CIImage = try self.filterImage(count: counter, renderSize: renderLayerCompositionInfo.renderSize)

        // 上下反転
        filterImage = filterImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1.0).translatedBy(x: 0, y: -CGFloat(filterImage.extent.height)))

        guard let colorMatrixFilter: CIFilter = CIFilter(name: "CIColorMatrix") else { throw RenderLayerErrorType.renderingError }
        colorMatrixFilter.setValue(filterImage, forKey: kCIInputImageKey)
        colorMatrixFilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: self.alpha), forKey: "inputAVector")

        // フィルター合成
        guard
            let result: CIFilter = CIFilter(name: self.blendMode.CIFilterName),
            let colorMatrixFilterOutputImage: CIImage = colorMatrixFilter.outputImage
        else { throw RenderLayerErrorType.renderingError }

        result.setValue(image, forKey: kCIInputBackgroundImageKey)
        result.setValue(colorMatrixFilterOutputImage, forKey: kCIInputImageKey)

        guard let outImage: CIImage = result.outputImage else { throw RenderLayerErrorType.renderingError }
        return outImage
    }

    // MARK: - Private -

    func filterImage(count: Int, renderSize: MCSize) throws -> CIImage {
        // フィルターイメージ作成
        if let filter: CIImage = self.filterCacheImageList[count] {
            return filter
        }
        let filter: CIImage = try self.loadFilterImage(count: count, renderSize: renderSize)
        self.filterCacheImageList[count] = filter
        return filter
    }

    /// フィルタイメージ生成・取得
    func loadFilterImage(count: Int, renderSize: MCSize) throws -> CIImage {
        let renderSize: CGSize = renderSize.toCGSize()
        // フィルターイメージ作成
        guard self.imagePaths.indices.contains(count) else { throw RenderLayerErrorType.renderingError }
        let imagePath: URL = self.imagePaths[count]
        guard var effect: CIImage = CIImage(contentsOf: imagePath) else { throw RenderLayerErrorType.renderingError }
        if self.resize {
            // フィルターイメージリサイズ
            let effectExtent: CGRect = effect.extent
            let scale: CGFloat = max(renderSize.width / effectExtent.width, renderSize.height / effectExtent.height)
            effect = effect.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            let y: CGFloat = effect.extent.size.height - renderSize.height
            effect = effect.transformed(by: CGAffineTransform(translationX: 0, y: -y))
            effect = effect.cropped(to: CGRect(origin: CGPoint(0.0, 0.0), size: renderSize))
            return effect
        }
        return effect
    }
}
