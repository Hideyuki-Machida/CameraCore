//
//  TransformUtils.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/13.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation

public class TransformUtils {
	public static func convertTransformSKToCI (userTransform: CGAffineTransform, videoSize: CGSize, renderSize: CGSize, preferredTransform: CGAffineTransform) -> CGAffineTransform {
		var conversionUserTransform: CGAffineTransform = userTransform // ユーザー設定トランスフォーム
		let originalSize: CGSize
		switch preferredTransform.isRotate {
		case .portrait, .portraitUpsideDown:
			originalSize = CGSize(width: videoSize.height, height: videoSize.width)
		default:
			originalSize = CGSize(width: videoSize.width, height: videoSize.height)
		}
		
		////////////////////////////////////////////
		// ビデオファイルサイズ と レンダリングサイズ の差
		let diffX: CGFloat = renderSize.width / originalSize.width
		let diffY: CGFloat = renderSize.height / originalSize.height
		let diff: CGFloat = max(diffX, diffY)
		
		let x: CGFloat = (renderSize.width / 2) - ((((originalSize.width * diffX) * conversionUserTransform.a) - ((originalSize.height * diffY) * conversionUserTransform.b)) / 2)
		conversionUserTransform.tx = x + (conversionUserTransform.tx * diff)
		
		let y: CGFloat = (renderSize.height / 2) - ((((originalSize.height * diffY) * conversionUserTransform.d) - ((originalSize.width * diffX) * conversionUserTransform.c)) / 2)
		conversionUserTransform.ty = y + (conversionUserTransform.ty * diff)
		return conversionUserTransform
	}
}
