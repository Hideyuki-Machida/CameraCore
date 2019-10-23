//
//  UseCoreMLYOLOv3TinyExampleVC.swift
//  CameraCoreExample
//
//  Created by hideyuki machida on 2019/09/23.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import Vision

@available(iOS 12.0, *)
class UseCoreMLYOLOv3TinyExampleVC: UIViewController {

	@IBOutlet weak var videoCaptureView: CameraCore.VideoCaptureView!
	
    private var detectionOverlay: CALayer! = nil
	var videoCaputurePropertys = CCRenderer.VideoCapture.Propertys.init(
		devicePosition: AVCaptureDevice.Position.back,
		isAudioDataOutput: true,
		required: [
			.captureSize(Settings.PresetSize.p960x540),
			.frameRate(Settings.PresetFrameRate.fr30)
		],
		option: []
	)

	
	deinit {
		self.videoCaptureView.pause()
		self.videoCaptureView.dispose()
	}
	
    var rootLayer: CALayer! = nil
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
        let renderSize: CGSize = Settings.PresetSize.p960x540.size()
        
        self.rootLayer = self.videoCaptureView.layer
        self.setupLayers()
        self.updateLayerGeometry()

		do {
			try self.videoCaptureView.setup(self.videoCaputurePropertys)
			let coreMLLayer = try CoreMLYOLOv3TinyLayer()
            coreMLLayer.onUpdate = { [weak self] (items: [ VNRecognizedObjectObservation ]) in
                guard let self = self else { return }
                for objectObservation: VNRecognizedObjectObservation in items {
                    self.detectionOverlay.sublayers = nil                    

                    let topLabelObservation = objectObservation.labels[0]
                    let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(renderSize.width), Int(renderSize.height))
                    
                    let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
                    let textLayer = self.createTextSubLayerInBounds(objectBounds, identifier: topLabelObservation.identifier, confidence: topLabelObservation.confidence)
                    
                    shapeLayer.addSublayer(textLayer)
                    self.detectionOverlay.addSublayer(shapeLayer)
                }
            }
			self.videoCaptureView.renderLayers = [ coreMLLayer ]
		} catch {
		}
        

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.videoCaptureView.play()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.videoCaptureView.pause()
		self.videoCaptureView.dispose()
	}
}

@available(iOS 12.0, *)
extension UseCoreMLYOLOv3TinyExampleVC {
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
        /*
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                            identifier: topLabelObservation.identifier,
                                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
        }
 */
        //self.updateLayerGeometry()
        CATransaction.commit()
    }
    

    func setupLayers() {
        let renderSize: CGSize = Settings.PresetSize.p960x540.size()
        
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: renderSize.width,
                                         height: renderSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let renderSize: CGSize = Settings.PresetSize.p960x540.size()
        
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / renderSize.height
        let yScale: CGFloat = bounds.size.height / renderSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint (x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }

    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
}
