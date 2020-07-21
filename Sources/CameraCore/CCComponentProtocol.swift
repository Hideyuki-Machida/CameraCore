//
//  CCComponentProtocol.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/03/15.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import MetalCanvas
import ProcessLogger_Swift

public protocol CCComponentSetupProtocol {
}

public protocol CCComponentTrigerProtocol {
}

public protocol CCComponentPipeProtocol: NSObjectProtocol {
}

public protocol CCComponentEventProtocol: NSObjectProtocol {
}


public protocol CCComponentProtocol: NSObjectProtocol {
    //var setup: CCComponentSetupProtocol { get }
    //var triger: CCComponentTrigerProtocol { get }
    //var pipe: CCComponentPipeProtocol { get }
    
    var debug: CCComponentDebug? { get set }
    var isDebugMode: Bool { get set }
}

extension CCComponentProtocol {
    public var isDebugMode: Bool {
        get {
            return self.debug != nil
        }
        set {
            self.debug = newValue ? CCComponentDebug() : nil
        }
    }
}

public class CCComponentDebug {
    private var deviceDebugger: ProcessLogger.Device = ProcessLogger.Device()
    private var framerateDebugger: ProcessLogger.Framerate = ProcessLogger.Framerate()

    private var d: [thread_basic_info] = []
    private var dooo: thread_basic_info = thread_basic_info()
    
    init() {}

    func update() {
        self.framerateDebugger.update()
    }

    func update(thred: Thread, queue: DispatchQueue) {
        guard let queueLabel: String = String(validatingUTF8: __dispatch_queue_get_label(queue)) else { return }
        let machTID: mach_port_t = pthread_mach_thread_np(pthread_self())
        guard let thredBasicInfo: thread_basic_info = self.deviceDebugger.thredBasicInfo(machTID: machTID) else { return }
        //self.dooo = thredBasicInfo
    }

    public func fps() -> Int {
        return self.framerateDebugger.fps()
    }

    public func cpu() {
        /*
        let count: Float = Float(self.d.count)
        let cpu_usage: Float = self.d.map { Float($0.cpu_usage) }.reduce(0, +)
        let microseconds: Float = self.d.map { Float($0.user_time.microseconds) }.reduce(0, +)
        //print(self.d)
        print((cpu_usage / Float(TH_USAGE_SCALE) * 100) / count, microseconds / count / 1000)
        print("thredIndex", self.dooo.thredIndex, Float(self.dooo.threadInfo.cpu_usage) / Float(TH_USAGE_SCALE) * 100, Float(self.dooo.threadInfo.user_time.microseconds) / Float(1000.0))
        self.d.removeAll()
 */
    }

}
