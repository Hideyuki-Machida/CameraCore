//
//  SharedContext.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/08.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

public final class GLContext {
	
	public let egleContext: EAGLContext
	public let ciContext: CIContext
	
	init(_ egleContext : EAGLContext) {
		self.egleContext = egleContext
		self.ciContext = CIContext(eaglContext: egleContext, options: SharedContext.options)
	}
}


public final class SharedContext {
	
	public static let glContext = GLContext(EAGLContext(api: .openGLES2)!)
	public static let ciContext = CIContext(eaglContext: EAGLContext(api: EAGLRenderingAPI.openGLES2, sharegroup: EAGLSharegroup())!, options: SharedContext.options)
	
	static var options: [CIContextOption : Any] {
		return [
			CIContextOption.workingColorSpace : Configuration.colorSpace,
			CIContextOption.useSoftwareRenderer : NSNumber(value: false),
		]
	}
}

