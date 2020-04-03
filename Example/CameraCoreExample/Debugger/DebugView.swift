//
//  DebugView.swift
//  CameraCoreExample
//
//  Created by machida.hideyuki on 2020/03/06.
//  Copyright © 2020 Donuts. All rights reserved.
//

import CameraCore
import MetalCanvas
import UIKit

class DebugView: UIView {
    @IBOutlet weak var label: UILabel!

    deinit {
        MCDebug.deinitLog(self)
    }

    func set(debugData: CCDebug.ComponentDebugger.Output.Data) {
        var str: String = ""
        str += "Time: \(debugData.time)\n"
        str += "\n-- Device --\n"
        str += "usedCPU: \(debugData.usedCPU)\n"
        str += "usedMemory: \(debugData.usedMemory)\n"
        str += "thermalState: \(debugData.thermalState)\n\n"
        str += "\n-- FPS --\n"
        str += "mainthredFPS: \(debugData.mainthredFPS)\n"
        for i: CCDebug.ComponentDebugger.Output.Data.CompornetFPS in debugData.compornetFPSList {
            str += "\(i.name)FPS: \(i.fps)\n"
        }
        self.label.text = str
    }
}
