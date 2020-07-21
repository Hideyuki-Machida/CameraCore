//
//  CCVariable.swift
//  
//
//  Created by hideyuki machida on 2020/07/21.
//

import Foundation

public struct CCBindble<T> {
    fileprivate var id: String
    fileprivate var callback: (T) -> Void
    init(_ callback: @escaping (T) -> Void) {
        self.id = NSUUID().uuidString
        self.callback = callback
    }
}

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
        self.callbacks.forEach { $0.callback(self.value) }
    }
    
    // バインディング用のクロージャーを保持
    private var callbacks: [CCBindble<T>] = []

    init(_ value: T) {
        self._value = value
    }

    public func bind(dataDidChange: @escaping (T) -> Void) -> UnBindKey {
        let item: CCBindble = CCBindble(dataDidChange)
        self.callbacks.append(item)
        return UnBindKey.init(id: item.id)
    }

    public func unBind(key: UnBindKey ) {
        self.callbacks = self.callbacks.filter { $0.id != key.id }
    }
    
    func dispose() {
        self.callbacks.removeAll()
    }
}

public extension CCVariable {
    struct UnBindKey {
        let id: String
    }
}
