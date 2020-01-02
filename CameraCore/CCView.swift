//
//  CCView.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/01.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas
import MetalKit
import UIKit

public class CCView: MCImageRenderView {
    private let renderQueue: DispatchQueue = DispatchQueue(label: "CameraCore.VideoCaptureView.render.queue")
    public override func awakeFromNib() {
        super.awakeFromNib()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate var _presentationTimeStamp: CMTime = CMTime()
    public var presentationTimeStamp: CMTime = CMTime()
    public var drawTexture: MTLTexture?
    
    public override func setup() throws {
        try super.setup()
        self.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
    }

    public override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        super.mtkView(view, drawableSizeWillChange: size)
    }

    public override func draw(in view: MTKView) {
        super.draw(in: view)
        drawQueue.async {
            guard
                self._presentationTimeStamp != self.presentationTimeStamp,
                let drawTexture: MTLTexture = self.drawTexture
            else { return }
            self._presentationTimeStamp = self.presentationTimeStamp
            self.drawUpdate(drawTexture: drawTexture)
        }
    }

}
