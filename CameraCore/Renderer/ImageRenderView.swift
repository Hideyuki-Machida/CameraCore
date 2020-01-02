//
//  ImageRenderView.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/15.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import GLKit
import CoreImage
import AVFoundation

public class ImageRenderView: GLKView {
	
	private var ciContext: CIContext? = nil
	private let rect: CGRect = CGRect(origin: CGPoint(x: 0, y: 0), size: UIScreen.main.nativeBounds.size)
	private var drawableBounds: CGRect?
	public var drawRect: CGRect?
	public var trimRect: CGRect?
	
	private var _mathScale: CGSize = CGSize(width: 0, height: 0)
	
	var isDrawable: Bool = true {
		willSet {
			if !newValue {
				//self.deleteDrawable()
			}
		}
	}
	
	func setup() {
		
		if let ctx: EAGLContext = EAGLContext.current() {
			self.context = EAGLContext(api: .openGLES2, sharegroup: ctx.sharegroup)!
		} else {
			self.context = EAGLContext(api: .openGLES2)!
		}
		//self.context = EAGLContext(api: .openGLES2, sharegroup: nil)
		//self.context = SharedContext.glContext
		self.ciContext = CIContext(eaglContext: self.context, options: [
			CIContextOption.workingColorSpace: Configuration.colorSpace,
			//CIContextOption.outputColorSpace: CGColorSpaceCreateDeviceRGB(),
			CIContextOption.useSoftwareRenderer: false,
			])
		self.enableSetNeedsDisplay = false
		self.drawableDepthFormat = GLKViewDrawableDepthFormat.format24
		
		self.bindDrawable()
	}
	
	deinit {
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		self.updateDrawableBounds()
		self._mathScale = CGSize(
			width: (self.drawableBounds?.width)! / (self.bounds.size.width),
			height: (self.drawableBounds?.height)! / (self.bounds.size.height)
		)
	}
	
	private func updateDrawableBounds() {
		self.bindDrawable()
		
		self.drawableBounds = self.bounds
		self.drawableBounds?.size.width = CGFloat(self.drawableWidth)
		self.drawableBounds?.size.height = CGFloat(self.drawableHeight)
	}
	
	func updateImage(image: CIImage?) {
		DispatchQueue.main.async { [weak self] in
			self?._updateImage(image: image)
		}
	}
	
	func updateSampleBuffer(sampleBuffer: CMSampleBuffer) {
		if let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
			let image: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
			DispatchQueue.main.async { [weak self] in
				self?._updateImage(image: image)
			}
		}
	}
	
	func updatePixelBuffer(pixelBuffer: CVPixelBuffer) {
		let image: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
		DispatchQueue.main.async { [weak self] in
			self?._updateImage(image: image)
		}
	}
	
	private func _updateImage(image: CIImage?) {
		if !self.isDrawable { return }
		guard let image: CIImage = image else { return }
		
		/*
		self.bindDrawable()
		
		if self.context != EAGLContext.current() {
		EAGLContext.setCurrent(self.context)
		}
		*/
		// clear eagl view to dg
		glClearColor(0.1568, 0.1568, 0.1568, 1.0)
		//glClearColor(0.0, 0.0, 0.0, 1.0)
		glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
		
		guard let ciContext: CIContext = self.ciContext else { return }
		let ex: CGRect = image.calcExtent()
		if let drawRect: CGRect = self.drawRect {
			// クリッピングあり
			let w: CGFloat = drawRect.size.width * self._mathScale.width
			let h: CGFloat = drawRect.size.height * self._mathScale.height
			let screenDiff: CGFloat = (drawableBounds?.size.height)! - h
			let rect: CGRect = CGRect(x: 0, y: screenDiff - (drawRect.origin.y * self._mathScale.height), width: w, height: h)
			ciContext.draw(image, in: rect, from: ex)
		} else {
			// クリッピングなし
			let drawRect: CGRect = CGRect(x: 0, y: 0, width: (self.drawableBounds?.size.width)!, height: (self.drawableBounds?.size.height)!)
			ciContext.draw(image, in: drawRect, from: ex)
		}
		self.display()
	}
}
