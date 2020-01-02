//
//  CompositionAVPlayerEvent.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/22.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

extension Renderer {
	public class CompositionAVPlayerEvent: NSObject, RenderEventProtocol {
		public let id: String = NSUUID().uuidString
		
		public var onStatusChange: ((_ status: CompositionAVPlayerStatus)->Void)?
		public var onFrameUpdate: ((_ time: Float64, _ duration: Float64)->Void)?
		public var onPreviewFinish: (()->Void)?
	}
}
