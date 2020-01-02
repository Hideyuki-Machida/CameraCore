//
//  VideoCapture.swift
//  CameraCore
//
//  Created by hideyuki machida on 2019/12/31.
//  Copyright © 2019 hideyuki machida. All rights reserved.
//

import Foundation

extension CCRenderer {
    public struct VideoCapture {
        private init() {} /* このstructはnamespace用途なのでインスタンス化防止 */
        
        public enum ErrorType: Error {
            case setupError
            case render
        }
    }
}
