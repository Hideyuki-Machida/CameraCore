//
//  CIColorMonochromeLayer.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2019/01/02.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import CameraCore
import MetalCanvas

public class CIColorMonochromeLayer: CameraCore.RenderLayerProtocol {
	
	public let id: RenderLayerId
	public let type: RenderLayerType = RenderLayerType.custom
	public let customIndex: Int = 1
	let filter: CIFilter = CIFilter(name: "CIColorMonochrome")!
	
	public init() {
		self.id = RenderLayerId()
		self.filter.setValue(CIColor(red: 0.2, green: 0.2, blue: 0.2), forKey: kCIInputColorKey)
		self.filter.setValue(0.8, forKey: kCIInputIntensityKey)
	}
	
	public func setup(assetData: CompositionVideoAsset) {}
	
	public func dispose() {
	}
}

extension CIColorMonochromeLayer: CameraCore.CIImageRenderLayerProtocol {
	public func processing(image: CIImage, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws -> CIImage {
		self.filter.setValue(image, forKey: kCIInputImageKey)
		if let img: CIImage = self.filter.outputImage {
			return img
		} else {
			throw Renderer.ErrorType.rendering
		}
	}
}
