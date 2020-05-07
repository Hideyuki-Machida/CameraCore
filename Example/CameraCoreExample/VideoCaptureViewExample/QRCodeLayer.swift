//
//  QRCodeLayer.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2020/05/03.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas
import CameraCore

final public class QRCodeLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.custom
    public let id: CCImageProcess.RenderLayerId = CCImageProcess.RenderLayerId()
    public var customIndex: Int = 0
    
    public init() throws {
    }
    
    deinit {
        MCDebug.deinitLog(self)
    }

    /// キャッシュを消去
    public func dispose() {
    }
}

extension QRCodeLayer {
    public func process(commandBuffer: MTLCommandBuffer, source: CCTexture, destination: inout CCTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        print(renderLayerCompositionInfo.metadataObjects)

        guard
            var destinationPixelBuffer: CVPixelBuffer = destination.pixelBuffer
        else { throw CCImageProcess.ErrorType.process }

        var objects: [MCPrimitiveTypeProtocol] = []
        for metadataObject in renderLayerCompositionInfo.metadataObjects {
            guard let metadataObject: AVMetadataMachineReadableCodeObject = metadataObject as? AVMetadataMachineReadableCodeObject else { continue }
            print(metadataObject.stringValue)
            
            let p: CGPoint = metadataObject.bounds.origin
            let size: CGSize = metadataObject.bounds.size
            let tl: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x), Float(p.y), 0.0), color: MCColor.init(hex: "#FF0000"), size: 10.0)
            objects.append(tl)
            let tr: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x + size.width), Float(p.y), 0.0), color: MCColor.init(hex: "#FF0000"), size: 10.0)
            objects.append(tr)
            let bl: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x), Float(p.y + size.height), 0.0), color: MCColor.init(hex: "#FF0000"), size: 10.0)
            objects.append(bl)
            let br: MCPrimitive.Point = try MCPrimitive.Point.init(position: SIMD3<Float>.init(Float(p.x + size.width), Float(p.y + size.height), 0.0), color: MCColor.init(hex: "#FF0000"), size: 10.0)
            objects.append(br)
        }

        let canvas: MCCanvas = try MCCanvas.init(pixelBuffer: &destinationPixelBuffer, orthoType: MCCanvas.OrthoType.topLeft, renderSize: renderLayerCompositionInfo.renderSize.toCGSize())
        try canvas.draw(commandBuffer: commandBuffer, objects: objects)

    }
}
