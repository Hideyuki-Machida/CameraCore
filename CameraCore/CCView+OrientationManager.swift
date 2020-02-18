//
//  CCView+OrientationManager.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/02/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import MetalCanvas
import UIKit

extension CCView {
    class OrientationManager {
        var canvas: MCCanvas?
        var angle: CGFloat = 0

        deinit {
            MCDebug.deinitLog(self)
        }

        func rotateTexture(commandBuffer: MTLCommandBuffer, source: CCTexture, colorPixelFormat: MTLPixelFormat, captureVideoOrientation: AVCaptureVideoOrientation?) throws -> CCTexture {
            let currentUIInterfaceOrientation: UIInterfaceOrientation = Configuration.shared.currentUIInterfaceOrientation
            guard
                let captureVideoOrientation: AVCaptureVideoOrientation = captureVideoOrientation,
                let currentAVCaptureVideoOrientation: AVCaptureVideoOrientation = currentUIInterfaceOrientation.toAVCaptureVideoOrientation,
                captureVideoOrientation != currentAVCaptureVideoOrientation
            else {
                self.canvas = nil
                return source
            }

            self.angle = self.getAngle(captureVideoOrientation: captureVideoOrientation, currentUIInterfaceOrientation: currentUIInterfaceOrientation)
            guard self.angle != 0 else { return source }

            let rotationSize: MCSize = source.presetSize.size(orientation: currentUIInterfaceOrientation)

            if rotationSize != self.canvas?.mcTexture.size {
                do {
                    self.canvas = try self.updateCanvas(size: rotationSize)
                } catch {
                    return source
                }
            }

            var mat: MCGeom.Matrix4x4 = MCGeom.Matrix4x4()
            mat.rotateZ(radians: Float(angle))
            try self.canvas?.draw(commandBuffer: commandBuffer, objects: [
                try MCPrimitive.Image(
                    texture: source,
                    position: SIMD3<Float>(x: 0, y: 0, z: 0),
                    transform: mat,
                    anchorPoint: .center
                ),
            ])

            return self.canvas?.mcTexture ?? source
        }

        private func getAngle(captureVideoOrientation: AVCaptureVideoOrientation, currentUIInterfaceOrientation: UIInterfaceOrientation) -> CGFloat {
            switch captureVideoOrientation {
            case .portrait:
                return self.portraitAngle(currentUIInterfaceOrientation: currentUIInterfaceOrientation)
            case .portraitUpsideDown:
                return self.portraitUpsideDownAngle(currentUIInterfaceOrientation: currentUIInterfaceOrientation)
            case .landscapeLeft:
                return self.landscapeLeftAngle(currentUIInterfaceOrientation: currentUIInterfaceOrientation)
            case .landscapeRight:
                return self.landscapeRightAngle(currentUIInterfaceOrientation: currentUIInterfaceOrientation)
            default:
                return self.portraitAngle(currentUIInterfaceOrientation: currentUIInterfaceOrientation)
            }
        }

        private func portraitAngle(currentUIInterfaceOrientation: UIInterfaceOrientation) -> CGFloat {
            switch currentUIInterfaceOrientation {
            case .portrait:
                return 0
            case .portraitUpsideDown:
                return 1.0 * CGFloat.pi
            case .landscapeLeft:
                return 0.5 * CGFloat.pi
            case .landscapeRight:
                return -0.5 * CGFloat.pi
            default:
                return self.angle
            }
        }

        private func portraitUpsideDownAngle(currentUIInterfaceOrientation: UIInterfaceOrientation) -> CGFloat {
            switch currentUIInterfaceOrientation {
            case .portrait:
                return 1.0 * CGFloat.pi
            case .portraitUpsideDown:
                return 0
            case .landscapeLeft:
                return -0.5 * CGFloat.pi
            case .landscapeRight:
                return 0.5 * CGFloat.pi
            default:
                return self.angle
            }
        }

        private func landscapeLeftAngle(currentUIInterfaceOrientation: UIInterfaceOrientation) -> CGFloat {
            switch currentUIInterfaceOrientation {
            case .portrait:
                return -0.5 * CGFloat.pi
            case .portraitUpsideDown:
                return 0.5 * CGFloat.pi
            case .landscapeLeft:
                return 0
            case .landscapeRight:
                return 1 * CGFloat.pi
            default:
                return self.angle
            }
        }

        private func landscapeRightAngle(currentUIInterfaceOrientation: UIInterfaceOrientation) -> CGFloat {
            switch currentUIInterfaceOrientation {
            case .portrait:
                return 0.5 * CGFloat.pi
            case .portraitUpsideDown:
                return -0.5 * CGFloat.pi
            case .landscapeLeft:
                return 1 * CGFloat.pi
            case .landscapeRight:
                return 0
            default:
                return self.angle
            }
        }

        func updateCanvas(size: MCSize) throws -> MCCanvas {
            guard
                let emptyPixelBuffer: CVPixelBuffer = CVPixelBuffer.create(size: size)
            else { throw ErrorType.draw }
            var destinationTexture: CCTexture = try CCTexture(pixelBuffer: emptyPixelBuffer, planeIndex: 0)
            let canvas = try MCCanvas(destination: &destinationTexture, orthoType: .center)
            return canvas
        }
    }
}
