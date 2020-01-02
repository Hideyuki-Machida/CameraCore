//
//  CompositionVideoAssetContentMode.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/28.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import UIKit

public enum CompositionVideoAssetContentMode: Int, Codable {
    case scaleToFill = 0
    case scaleAspectFit
    case scaleAspectFill
    case redraw
    case center
    case top
    case bottom
    case left
    case right
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case none
    
    func transform(videoSize: CGSize, renderSize: CGSize, transform: CGAffineTransform) -> CGAffineTransform {
        switch self {
        case .scaleToFill: return CGAffineTransform.identity
        case .scaleAspectFit: return CGAffineTransform.identity
        case .scaleAspectFill: return CompositionVideoAssetContentModeTransform.scaleAspectFill(videoSize: videoSize, renderSize: renderSize, transform: transform)
        case .redraw: return CGAffineTransform.identity
        case .center: return CGAffineTransform.identity
        case .top: return CGAffineTransform.identity
        case .bottom: return CGAffineTransform.identity
        case .left: return CGAffineTransform.identity
        case .right: return CGAffineTransform.identity
        case .topLeft: return CGAffineTransform.identity
        case .topRight: return CGAffineTransform.identity
        case .bottomLeft: return CGAffineTransform.identity
        case .bottomRight: return CGAffineTransform.identity
        case .none: return CGAffineTransform.identity
        }
    }
}


class CompositionVideoAssetContentModeTransform {
    public static func scaleAspectFill(videoSize: CGSize, renderSize: CGSize, transform: CGAffineTransform) -> CGAffineTransform {
        guard renderSize != videoSize else { return transform }
        
        var transform: CGAffineTransform = transform
        let originalSize: CGSize
        //let originalSize: CGSize = videoSize.applying(CGAffineTransform(rotationAngle: transform.rotation))
        switch transform.isRotate {
        case .portrait, .portraitUpsideDown:
            originalSize = CGSize(width: videoSize.height, height: videoSize.width)
            
            // 左下座標系の時計回り回転になるので、txが無いと画がある部分が左枠外に行ってしまう。
            // 計算上この回転がかかるものはtxが回転後の横幅の値である必要がある。
            transform.tx = videoSize.height
            transform = transform.concatenating(CGAffineTransform(rotationAngle: .pi)).concatenating(CGAffineTransform(translationX: originalSize.width, y: originalSize.height))
        default:
            originalSize = CGSize(width: videoSize.width, height: videoSize.height)
        }
        // スケールを設定
        let scaleW: CGFloat = renderSize.width / originalSize.width
        let scaleH: CGFloat = renderSize.height / originalSize.height
        
        Debug.ActionLog("scaleW: \(scaleW)")
        Debug.ActionLog("scaleH: \(scaleH)")
        
        let scale: CGFloat = scaleW > scaleH ? scaleW : scaleH
        let resizeSize: CGSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        Debug.ActionLog("scale: \(scale)")
        Debug.ActionLog("resizeSize: \(resizeSize)")
        
        
        let resultTransform: CGAffineTransform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: ((renderSize.width / 2) - (resizeSize.width / 2)) * (1 / scale), y: ((renderSize.height / 2) - (resizeSize.height / 2)) * (1 / scale) )
        Debug.ActionLog("resultTransform: \(resultTransform)")
        Debug.ActionLog("resultTransform: \(transform.concatenating(resultTransform))")
        return transform.concatenating(resultTransform)
        //.concatenating(CGAffineTransform(rotationAngle: .pi))
        //return transform
    }
    
    public static func getImageCroppingTransform(imageSize: CGSize, renderSize: CGSize) -> CGAffineTransform {
        guard renderSize != imageSize else { return CGAffineTransform(scaleX: 1.0, y: 1.0)  }
        
        let originalSize: CGSize = CGSize(width: imageSize.width, height: imageSize.height)
        
        // スケールを設定
        let scaleW: CGFloat = renderSize.width / originalSize.width
        let scaleH: CGFloat = renderSize.height / originalSize.height
        
        let scale: CGFloat = scaleW > scaleH ? scaleW : scaleH
        let resizeSize: CGSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        let resultTransform: CGAffineTransform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: ((renderSize.width / 2) - (resizeSize.width / 2)) * (1 / scale), y: ((renderSize.height / 2) - (resizeSize.height / 2)) * (1 / scale) )
        return resultTransform
        //.concatenating(CGAffineTransform(rotationAngle: .pi))
        //return transform
    }
}
