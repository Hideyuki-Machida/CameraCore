//
//  CCComponentProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/03/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import MetalCanvas

public protocol CCComponentSetupProtocol {
}

public protocol CCComponentTrigerProtocol {
}

public protocol CCComponentPipeProtocol: NSObjectProtocol {
}

public protocol CCComponentProtocol: NSObjectProtocol {
    //var setup: CCComponentSetupProtocol { get }
    //var triger: CCComponentTrigerProtocol { get }
    //var pipe: CCComponentPipeProtocol { get }
    
    var debugger: ComponentDebugger? { get set }
    var isDebugMode: Bool { get set }
}

extension CCComponentProtocol {
    public var isDebugMode: Bool {
        get {
            return self.debugger != nil
        }
        set {
            self.debugger = newValue ? ComponentDebugger() : nil
        }
    }
}
