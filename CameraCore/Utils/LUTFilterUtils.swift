//
//  LUTFilterUtils.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import MetalCanvas

class LUTFilterUtils: NSObject {
	static func generateLUTFilterCubeData(lutImage: UIImage, dimension: Int) -> NSData? {
		guard let cgImage: CGImage = lutImage.cgImage else { return nil }
		
		let rowNum: Int = cgImage.height / dimension
		let columnNum: Int = cgImage.width / dimension
		
		if cgImage.width % dimension != 0 || cgImage.height % dimension != 0 || (rowNum * columnNum != dimension) { return nil }
		
		guard let bitmap: UnsafeMutablePointer<UInt8> = self.createRGBABitmapFromCGImage(cgImage) else { return nil }
		
		let size: Int = dimension * dimension * dimension * MemoryLayout<Float>.size * 4
		let data: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: size)
		
		var bitmapOffest: Int = 0
		var z: Int = 0
		
		let div_255: Double = 1.0 / 255.0;
		for _ in 0..<rowNum {
			for y in 0..<dimension {
				let tmp = z
				
				for _ in 0..<columnNum {
					for x in 0..<dimension {
						let r: Double = Double(bitmap[bitmapOffest]) * div_255
						let g: Double = Double(bitmap[bitmapOffest + 1]) * div_255
						let b: Double = Double(bitmap[bitmapOffest + 2]) * div_255
						//let a: Double = Double(bitmap[bitmapOffest + 3]) * div_255
						
						let dataOffset = (z * dimension * dimension + y * dimension + x) * 4
						data[dataOffset] = Float(r)
						data[dataOffset + 1] = Float(g)
						data[dataOffset + 2] = Float(b)
						data[dataOffset + 3] = 1.0
						
						bitmapOffest += 4
					}
					z += 1
				}
				
				z = tmp
			}
			z += columnNum
		}
		
		bitmap.deinitialize(count: cgImage.byteLength)
		//bitmap.deinitialize()
		//bitmap.deallocate(capacity: cgImage.byteLength)
		let cubeData: NSData = NSData(bytesNoCopy: data, length: size, freeWhenDone: true)
		return cubeData
	}

	static func generateLUTFilterCubeData2(lutImage: UIImage, dimension: Int) -> NSData? {
		guard let cgImage: CGImage = lutImage.cgImage else { return nil }
		
		let rowNum: Int = cgImage.height / dimension
		let columnNum: Int = cgImage.width / dimension
		
		if cgImage.width % dimension != 0 || cgImage.height % dimension != 0 || (rowNum * columnNum != dimension) { return nil }
		
		guard let bitmap: UnsafeMutablePointer<UInt8> = self.createRGBABitmapFromCGImage(cgImage) else { return nil }
		
		let size: Int = dimension * dimension * dimension * MemoryLayout<Float>.size * 4
		let data: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: size)
		
		var bitmapOffest: Int = 0
		var z: Int = 0
		
		let div_255: Double = 1.0 / 255.0;
		for _ in 0..<rowNum {
			for y in 0..<dimension {
				let tmp = z
				
				for _ in 0..<columnNum {
					for x in 0..<dimension {
						let r: Double = Double(bitmap[bitmapOffest]) * div_255
						let g: Double = Double(bitmap[bitmapOffest + 1]) * div_255
						let b: Double = Double(bitmap[bitmapOffest + 2]) * div_255
						//let a: Double = Double(bitmap[bitmapOffest + 3]) * div_255
						
						let dataOffset = (z * dimension * dimension + y * dimension + x) * 4
						MCDebug.log("r: \(bitmap[bitmapOffest + 1])")
						data[dataOffset] = Float(r)
						data[dataOffset + 1] = Float(g)
						data[dataOffset + 2] = Float(b)
						data[dataOffset + 3] = 1.0
						
						bitmapOffest += 4
					}
					z += 1
				}
				
				z = tmp
			}
			z += columnNum
		}
		
		bitmap.deinitialize(count: cgImage.byteLength)
		//bitmap.deinitialize()
		//bitmap.deallocate(capacity: cgImage.byteLength)
		let cubeData: NSData = NSData(bytesNoCopy: data, length: size, freeWhenDone: true)
		return cubeData
	}


	private static func createRGBABitmapFromCGImage(_ cgImage: CGImage) -> UnsafeMutablePointer<UInt8>? {
		let data = UnsafeMutablePointer<UInt8>.allocate(capacity: cgImage.byteLength)
		
		let context = CGContext(
			data: data,
			width: cgImage.width,
			height: cgImage.height,
			bitsPerComponent: cgImage.bitsPerComponent,
			bytesPerRow: cgImage.bytesPerRow,
			space: cgImage.colorSpace ?? Configuration.colorSpace,
			bitmapInfo: cgImage.bitmapInfo.rawValue
		)
		
		guard let _context = context else {
			data.deinitialize(count: cgImage.byteLength)
			//data.deinitialize()
			//data.deallocate(capacity: cgImage.byteLength)
			return nil
		}
		
		_context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
		
		return data
	}

}

extension CGImage {
	var byteLength: Int {
		let rowBytes = Int(self.width) * (self.bitsPerPixel / self.bitsPerComponent)
		return rowBytes * Int(self.height)
	}
}
