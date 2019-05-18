//
//  Debug.swift
//  MystaVideoModule
//
//  Created by 町田 秀行 on 2018/01/21.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation

class Debug {
    static let ESCAPE = "\u{001b}["
    
    static let RESET_FG = ESCAPE + "fg;" // Clear any foreground color
    static let RESET_BG = ESCAPE + "bg;" // Clear any background color
    static let RESET = ESCAPE + ";"   // Clear any foreground or background color
    
    static func NetworkRequestLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg0,255,0;\(object)\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    static func SuccessLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg0,255,255;\(object)\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    static func ErrorLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg255,0,0;\(object)\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    static func ActionLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg255,165,0;\(object)\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    static func DeinitLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg0,255,255;deinit: \(type(of: object))\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    
    
}
