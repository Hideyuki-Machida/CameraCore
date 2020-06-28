//
//  AssetType.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/08.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation
import Photos

extension CCCameraRoll {
    public enum AssetType: Int, Codable {
        case unknown = 0
        case image = 1
        case video = 2
        case audio = 3

        public var phAssetMediaType: PHAssetMediaType {
            get {
                return PHAssetMediaType.init(rawValue: self.rawValue)!
            }
        }
    }
}
