//
//  FaceLayer.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/10/15.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas
import CameraCore

final public class FaceLayer: RenderLayerProtocol {
    public let type: RenderLayerType = RenderLayerType.custom
    public let id: RenderLayerId
    public var customIndex: Int = 0
    
    public init() {
        self.id = RenderLayerId()
    }
    
    /// キャッシュを消去
    public func dispose() {
    }
}

extension FaceLayer: MetalRenderLayerProtocol {
    public func process(commandBuffer: inout MTLCommandBuffer, source: MTLTexture, destination: inout MTLTexture, renderLayerCompositionInfo: inout RenderLayerCompositionInfo) throws {
        guard let metadataObjects = renderLayerCompositionInfo.metadataObjects else { return }
        for metadataObject in metadataObjects {
            if let faceObject: AVMetadataFaceObject = metadataObject as? AVMetadataFaceObject {
                print(faceObject)
            }
        }
    }
}
