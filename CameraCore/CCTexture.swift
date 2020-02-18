//
//  CCTexture.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/06.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas

public typealias CCTexture = MCTexture

extension CCTexture {
    enum CCTextureOptionKey: String {
        case presentationTimeStamp = "CCTexture.presentationTimeStamp"
        case captureVideoOrientation = "CCTexture.captureVideoOrientation"
        case presetSize = "CCTexture.captureSize"
    }

    public var presentationTimeStamp: CMTime {
        get {
            return (self.userInfo[CCTextureOptionKey.presentationTimeStamp.rawValue] as? CMTime) ?? CMTime()
        }
        set {
            self.userInfo[CCTextureOptionKey.presentationTimeStamp.rawValue] = newValue
        }
    }

    public var captureVideoOrientation: AVCaptureVideoOrientation? {
        get {
            return self.userInfo[CCTextureOptionKey.captureVideoOrientation.rawValue] as? AVCaptureVideoOrientation
        }
        set {
            self.userInfo[CCTextureOptionKey.captureVideoOrientation.rawValue] = newValue
        }
    }

    public var presetSize: Settings.PresetSize {
        get {
            return (self.userInfo[CCTextureOptionKey.presetSize.rawValue] as? Settings.PresetSize) ?? Settings.PresetSize.p1280x720
        }
        set {
            self.userInfo[CCTextureOptionKey.presetSize.rawValue] = newValue
        }
    }
}
