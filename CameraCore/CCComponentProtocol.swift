//
//  CCComponentProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/03/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation

public protocol CCComponentProtocol {
    var setup: CCComponentSetupProtocol { get set }
    var triger: CCComponentTrigerProtocol { get set }
    var pipe: CCComponentPipeProtocol { get set }
}

/*
extension CCComponentProtocol {
    var setup:
}
*/
public protocol CCComponentSetupProtocol {
}

public protocol CCComponentTrigerProtocol {
}

public protocol CCComponentPipeProtocol {
}
