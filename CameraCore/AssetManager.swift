//
//  AssetManager.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 hideyuki machida. All rights reserved.
//

import AVFoundation
import UIKit

public final class AssetManager {
    static let shard = AssetManager()
    private let bundle: Bundle

    private init() {
        self.bundle = Bundle(for: type(of: self))
    }

    public enum Shader {
        case mask
        case colorOverlay
        public var url: URL {
            switch self {
            case .mask: return AssetManager.shard.bundle.url(forResource: "Shader/Mask", withExtension: "cikernel")!
            case .colorOverlay: return AssetManager.shard.bundle.url(forResource: "Shader/ColorOverlay", withExtension: "cikernel")!
            }
        }
    }
}
