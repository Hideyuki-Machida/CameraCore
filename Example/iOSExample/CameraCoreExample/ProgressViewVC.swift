//
//  ProgressViewVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/08/27.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import CameraCore
import MetalCanvas

class ProgressViewVC: UIViewController {
    @IBOutlet weak var progressLabel: UILabel!
    
    deinit {
        MCDebug.deinitLog(self)
    }
}
