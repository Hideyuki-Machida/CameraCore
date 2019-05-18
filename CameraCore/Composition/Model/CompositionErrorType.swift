//
//  CompositionErrorType.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/09/24.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import Foundation

public enum CompositionErrorType: Error {
	case dataError
}

public enum CompositionAssetErrorType: Error {
	case isPlayableError
	case isExportableError
	case isReadableError
	case isComposableError
	case hasProtectedContentError
	case trackError
	case dataError
}
