//
//  Inference.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/01/07.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import AVFoundation
import MetalCanvas



public extension CCVision {
    class Inference: NSObject {
        public let setup: CCVision.Inference.Setup = CCVision.Inference.Setup()
        public let triger: CCVision.Inference.Triger = CCVision.Inference.Triger()
        public let pipe: CCVision.Inference.Pipe = CCVision.Inference.Pipe()

        deinit {
            self.dispose()
            MCDebug.deinitLog(self)
        }
    }
}

fileprivate extension CCVision.Inference {
    func dispose() {
        self.setup._dispose()
        self.triger._dispose()
        self.pipe._dispose()
    }
}

extension CCVision.Inference {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var inference: CCVision.Inference?

        fileprivate func _dispose() {
            self.inference = nil
        }
    }

    // MARK: - Triger
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var inference: CCVision.Inference?

        public func dispose() {
            self.inference?.dispose()
        }

        fileprivate func _dispose() {
            self.inference = nil
        }
    }

    // MARK: - Pipe
    public class Pipe: NSObject, CCComponentPipeProtocol {
        fileprivate var observations: [NSKeyValueObservation] = []
        
        fileprivate var inference: CCVision.Inference?

       func input(camera: CCCapture.Camera) -> CCVision.Inference {
            let observation: NSKeyValueObservation = camera.pipe.observe(\.outPresentationTimeStamp, options: [.new]) { [weak self] (object: CCCapture.Camera.Pipe, change) in

                guard let self = self else { return }
                
            }

            self.observations.append(observation)
            return self.inference!
       }

        fileprivate func _dispose() {
            self.inference = nil
            self.observations.forEach { $0.invalidate() }
            self.observations.removeAll()
        }
    }
}
