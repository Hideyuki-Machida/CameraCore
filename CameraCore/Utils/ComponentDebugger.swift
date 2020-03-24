//
//  ComponentDebugger.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/03/19.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import MetalCanvas

public class ComponentDebugger {
    private var framerateDebugger: MCDebug.Framerate = MCDebug.Framerate()

    init() {}

    func update() {
        self.framerateDebugger.update()
    }

    public func fps() -> Int {
        return self.framerateDebugger.fps()
    }
}
