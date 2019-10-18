//
//  Debug.swift
//  MystaVideoModule
//
//  Created by 町田 秀行 on 2018/01/21.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation

public class Debug {
    public static func NetworkRequestLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("🍏 NetworkRequestLog: \(object)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    public static func SuccessLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("🍏 SuccessLog: \(object)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    public static func ErrorLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("🍎 ErrorLog: \(object)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    public static func ActionLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("📔 ActionLog: \(object)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    public static func DeinitLog<T>(_ object: T) {
        func log<T>(_ object: T) {
            print("🗑 DeinitLog: \(object)")
        }
        #if RELEASE
        #else
            log(object)
        #endif
    }
    
    
}
