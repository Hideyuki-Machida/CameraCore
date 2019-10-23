//
//  CompositionVideoTrack.swift
//  CCamVideo
//
//  Created by hideyuki machida on 2018/08/07.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public struct CompositionVideoTrack: CompositionVideoTrackProtocol {
    public var __property: CompositionVideoTrackProperty
    
    public init(assets: [CompositionVideoAssetProtocol], layers: [RenderLayerProtocol] = []) throws {
        self.__property = CompositionVideoTrackProperty.init(
            id: CompositionVideoTrackId(),
            create: Date.init(),
            update: Date.init(),
            dataId: nil,
            compositionVideoTrack: nil,
            compositionAudioTrack: nil,
			layers: layers,
            assets: assets,
            videoCompositionInstruction: nil,
            audioMixInputParameters: nil
        )
    }
}


extension CompositionVideoTrack {
    public mutating func setup(composition: inout AVMutableComposition, dataId: CompositionDataId, videoCompositionProperty: inout VideoCompositionProperty) throws {
		try self.setupVideo(composition: &composition, dataId: dataId, videoCompositionProperty: &videoCompositionProperty)
    }
}

extension CompositionVideoTrack {
    enum CodingKeys: String, CodingKey {
        case __property
    }
}

extension CompositionVideoTrack: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.__property, forKey: .__property)
    }
}

extension CompositionVideoTrack: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.__property = try values.decode(CompositionVideoTrackProperty.self, forKey: .__property)
    }
}
