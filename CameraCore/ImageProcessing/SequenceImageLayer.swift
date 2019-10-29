//
//  SequenceImageLayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation
import MetalCanvas

final public class SequenceImageLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.sequenceImage
    public var id: RenderLayerId
    public let customIndex: Int = 0
    private let imagePaths: [URL]
    private let blendMode: Blendmode
    private let alpha: CGFloat
    private let updateFrameRate: TimeInterval
    private let resize: Bool

    private var _filterCashImageList: [Int: CIImage] = [:] // エフェクトフィルターキャッシュ


    public init(imagePaths: [URL], blendMode: Blendmode, alpha: CGFloat = 1.0, updateFrameRate: Int32 = 30, resize: Bool = true) {
        self.id = RenderLayerId()
        self.imagePaths = imagePaths.sorted(by: {$0.lastPathComponent < $1.lastPathComponent})
        self.blendMode = blendMode
        self.alpha = alpha
        self.updateFrameRate = TimeInterval(updateFrameRate)
        self.resize = resize
    }

    fileprivate init(id: RenderLayerId, imagePaths: [URL], blendMode: Blendmode, alpha: CGFloat = 1.0, updateFrameRate: TimeInterval = 30, resize: Bool = true) {
        self.id = id
        self.imagePaths = imagePaths.sorted(by: {$0.lastPathComponent < $1.lastPathComponent})
        self.blendMode = blendMode
        self.alpha = alpha
        self.updateFrameRate = updateFrameRate
        self.resize = resize
    }

    /// キャッシュを消去
    public func dispose() {
        self._filterCashImageList.removeAll()
    }

}

extension SequenceImageLayer: MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard var inputImage: CIImage = CIImage(mtlTexture: source, options: nil) else { throw RenderLayerErrorType.renderingError }
        inputImage = try process(image: inputImage, renderLayerCompositionInfo: &renderLayerCompositionInfo)
        let colorSpace: CGColorSpace = inputImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        MCCore.ciContext.render(inputImage, to: destination, commandBuffer: commandBuffer, bounds: inputImage.extent, colorSpace: colorSpace)
    }
    
    fileprivate func process(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
        let imageCounter: Float = Float(renderLayerCompositionInfo.compositionTime.value) * Float(self.updateFrameRate) / Float(renderLayerCompositionInfo.compositionTime.timescale)
        
        // フィルターイメージ生成
        let counter: Int = Int(floorf(imageCounter)) % self.imagePaths.count
        guard var filterImage: CIImage = self._getFilterImage(count: counter, renderSize: renderLayerCompositionInfo.renderSize) else { return image }
        
        // 上下反転
        filterImage = filterImage.transformed(by: CGAffineTransform(scaleX: 1, y: -1.0).translatedBy(x: 0, y: -CGFloat(filterImage.extent.height)))
        
        let colorMatrixfilter: CIFilter = CIFilter(name:"CIColorMatrix")!
        colorMatrixfilter.setValue(filterImage, forKey: kCIInputImageKey)
        colorMatrixfilter.setValue(CIVector(x: 0.0, y: 0.0, z: 0.0, w: self.alpha), forKey: "inputAVector")
        
        // フィルター合成
        let result: CIFilter = CIFilter(name: self.blendMode.CIFilterName())!
        
        result.setValue(image, forKey: kCIInputBackgroundImageKey)
        result.setValue(colorMatrixfilter.outputImage!, forKey: kCIInputImageKey)
        
        return result.outputImage ?? image
    }
    
    // MARK: - Private -
    fileprivate func _getFilterImage(count: Int, renderSize: CGSize) -> CIImage? {
        // フィルターイメージ作成
        if let filter: CIImage = self._filterCashImageList[ count ] {
            return filter
        } else {
            if let filetr: CIImage = self._loadFilterImage(count: count, renderSize: renderSize) {
                self._filterCashImageList[ count ] = filetr
                return filetr
            }
            return nil
        }
    }
    
    /// フィルタイメージ生成・取得
    fileprivate func _loadFilterImage(count: Int, renderSize: CGSize) -> CIImage? {
        // フィルターイメージ作成
        let imagePath: URL = self.imagePaths[count]
        guard var effect: CIImage = CIImage(contentsOf: imagePath) else { return nil }
        if self.resize {
            // フィルターイメージリサイズ
            let effectExtent: CGRect = effect.extent
            let ex: CGSize = renderSize
            let p: CGFloat = max(ex.width / effectExtent.width, ex.height / effectExtent.height)
            effect = effect.transformed(by: CGAffineTransform.init(scaleX: p, y: p))
            let y: CGFloat = effect.extent.size.height - renderSize.height
            effect = effect.transformed(by: CGAffineTransform.init(translationX: 0, y: -y))
            effect = effect.cropped(to: CGRect.init(origin: CGPoint.init(0.0, 0.0), size: renderSize) )
            return effect
        } else {
            return effect
        }
    }

}
