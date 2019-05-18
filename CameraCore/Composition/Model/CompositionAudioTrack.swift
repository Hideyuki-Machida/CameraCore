//
//  CompositionAudioTrack.swift
//  CCamVideo
//
//  Created by hideyuki machida on 2018/08/07.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import AVFoundation

public struct CompositionAudioTrack: CompositionAudioTrackProtocol {
    public var __property: CompositionAudioTrackProperty
    
    public init(assets: [CompositionAudioAssetProtocol], layers: [RenderLayerProtocol] = []) throws {
        self.__property = CompositionAudioTrackProperty.init(
            id: CompositionAudioTrackId(),
            create: Date.init(),
            update: Date.init(),
            dataId: nil,
            compositionAudioTrack: nil,
			layers: layers,
            assets: assets,
            audioMixInputParameters: nil
        )
    }
}

extension CompositionAudioTrack {
	public mutating func setup(composition: inout AVMutableComposition, dataId: CompositionDataId, videoCompositionProperty: VideoCompositionProperty) throws {
		try self.setupAudio(composition: &composition, dataId: dataId, videoCompositionProperty: videoCompositionProperty)
    }
}

extension CompositionAudioTrack {
    enum CodingKeys: String, CodingKey {
        case __property
    }
}

extension CompositionAudioTrack: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.__property, forKey: .__property)
    }
}

extension CompositionAudioTrack: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.__property = try values.decode(CompositionAudioTrackProperty.self, forKey: .__property)
    }
}
