//
//  CameraRollManagerImagePreviewVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/09/07.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class CameraRollManagerImagePreviewVC: UIViewController {

	public var image: UIImage!
	@IBOutlet weak var imageView: UIImageView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.imageView.image = self.image
	}

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func closeButtonTapAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
