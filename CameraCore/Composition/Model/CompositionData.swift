//
//  CompositionData.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/07.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import UIKit
import AVFoundation

public struct CompositionData: CompositionDataProtocol {
    public var __property: CompositionDataProperty
    //private let queue: DispatchQueue = DispatchQueue(label: "CameraCore.VideoCompositor")

    public init(videoTracks: [CompositionVideoTrackProtocol], audioTracks: [CompositionAudioTrackProtocol], property: VideoCompositionProperty) {
        self.__property = CompositionDataProperty.init(
            videoTracks: videoTracks,
			audioTracks: audioTracks,
            property: property
        )
    }
    
    public init(to: CompositionDataProperty) {
        self.__property = to
    }
}

extension CompositionData {
    enum CodingKeys: String, CodingKey {
        case __property
    }
}

extension CompositionData: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.__property, forKey: .__property)
    }
}

extension CompositionData: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.__property = try values.decode(CompositionDataProperty.self, forKey: .__property)
    }
}

