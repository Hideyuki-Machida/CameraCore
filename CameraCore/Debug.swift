//
//  Debug.swift
//  MystaVideoModule
//
//  Created by 町田 秀行 on 2018/01/21.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation

public class Debug {
    public static let ESCAPE = "\u{001b}["
    
    public static let RESET_FG = ESCAPE + "fg;" // Clear any foreground color
    public static let RESET_BG = ESCAPE + "bg;" // Clear any background color
    public static let RESET = ESCAPE + ";"   // Clear any foreground or background color
    
    public static func NetworkRequestLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg0,255,0;\(object)\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    public static func SuccessLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg0,255,255;\(object)\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    public static func ErrorLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg255,0,0;\(object)\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    public static func ActionLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg255,165,0;\(object)\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    public static func DeinitLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("\(ESCAPE)fg0,255,255;deinit: \(type(of: object))\(RESET)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    
    
}
