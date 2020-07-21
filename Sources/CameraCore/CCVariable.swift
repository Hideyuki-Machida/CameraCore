//
//  CCVariable.swift
//  
//
//  Created by hideyuki machida on 2020/07/21.
//

import Foundation

public class CCVariable<T> {
    private var _value: T
    public var value: T {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return self._value
        }
        set {
            objc_sync_enter(self)
            self._value = newValue
            objc_sync_exit(self)
        }
    }
    
    func dispatch() {
        self.callbacks.forEach { $0(self.value) }
    }
    
    // バインディング用のクロージャーを保持
    private var callbacks: [((T) -> Void)] = []

    init(_ value: T) {
        self._value = value
    }

    func bind(dataDidChange: @escaping (T) -> Void) {
        self.callbacks.append(dataDidChange)
    }
    
    func dispose() {
        self.callbacks.removeAll()
    }
}
