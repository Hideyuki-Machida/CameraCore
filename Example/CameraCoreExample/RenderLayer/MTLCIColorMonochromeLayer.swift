//
//  MTLCIColorMonochromeLayer.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2019/01/02.
//  Copyright © 2019 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation
import CameraCore
import MetalCanvas

public struct MTLCIColorMonochromeLayer: RenderLayerProtocol {
	public let id: RenderLayerId
	public let type: RenderLayerType = RenderLayerType.custom
	public let customIndex: Int = 1
	let filter: CIFilter = CIFilter(name: "CIColorMonochrome")!
	
	public init() {
		self.id = RenderLayerId()
		filter.setValue(CIColor(red: 0.2, green: 0.2, blue: 0.2), forKey: kCIInputColorKey)
		filter.setValue(0.8, forKey: kCIInputIntensityKey)
	}
	
	public func setup(assetData: CompositionVideoAsset) {}
	
	public func dispose() {
	}
}

extension MTLCIColorMonochromeLayer: MetalRenderLayerProtocol {
	public mutating func processing(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
		guard let image: CIImage = CIImage(mtlTexture: source, options: nil) else { return }
		self.filter.setValue(image, forKey: kCIInputImageKey)
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		MCCore.ciContext.render(self.filter.outputImage!, to: destination, commandBuffer: commandBuffer, bounds: self.filter.outputImage!.extent, colorSpace: colorSpace)
	}
	
}
