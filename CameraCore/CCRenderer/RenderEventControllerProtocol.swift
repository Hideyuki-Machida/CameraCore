//
//  RenderEventControllerProtocol.swift
//  CameraCore
//
//  Created by 町田 秀行 on 2018/08/24.
//  Copyright © 2018年 町田 秀行. All rights reserved.
//

import Foundation

protocol RenderEventControllerProtocol {
	var events: [RenderEventProtocol] { get set }
	mutating func add(event: RenderEventProtocol)
	mutating func remove(event: RenderEventProtocol)
}

extension RenderEventControllerProtocol {
	mutating func add(event: RenderEventProtocol) {
		self.events.append(event)
	}

	mutating func remove(event: RenderEventProtocol) {
		for (index, _) in self.events.enumerated() {
			if self.events[index].id == event.id {
				self.events.remove(at: index)
				return
			}
		}
	}
}
