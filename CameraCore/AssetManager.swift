//
//  AssetManager.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/19.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation

final public class AssetManager {
	static public let shard = AssetManager()
	public var bundlr: Bundle!
	
	
	private init() {
		self.bundlr = Bundle(for: type(of: self))
	}

	public enum Shader {
		case mask
		case colorOverlay
		public func url() -> URL {
			switch self {
			case .mask: return AssetManager.shard.bundlr.url(forResource: "Shader/Mask", withExtension: "cikernel")!
			case .colorOverlay: return AssetManager.shard.bundlr.url(forResource: "Shader/ColorOverlay", withExtension: "cikernel")!
			}
		}
	}
}
