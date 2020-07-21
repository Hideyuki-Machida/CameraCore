//
//  Debugger.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/03/24.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import Foundation
import MetalCanvas
import UIKit
import ProcessLogger_Swift

public extension CCDebug {
    class ComponentDebugger: NSObject {
        public let outPut: CCDebug.ComponentDebugger.Output = CCDebug.ComponentDebugger.Output()
        public let fileWriter: CCDebug.ComponentDebugger.FileWriter = CCDebug.ComponentDebugger.FileWriter()

        fileprivate let debugLoopQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCDebug.ComponentDebugger.debugLoopQueue")
        fileprivate let writeQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCDebug.ComponentDebugger.writeQueue")

        public let setup: CCDebug.ComponentDebugger.Setup = CCDebug.ComponentDebugger.Setup()
        public let triger: CCDebug.ComponentDebugger.Triger = CCDebug.ComponentDebugger.Triger()

        fileprivate var list: [CCComponentProtocol] = []
        
        private var displayLink: CADisplayLink?
        private var isDubugLoop: Bool = false
        private var startTime: TimeInterval = Date().timeIntervalSince1970
        private var mainthredFPSDebugger: ProcessLogger.Framerate = ProcessLogger.Framerate()

        public override init() {
            super.init()
            self.setup.debugger = self
            self.triger.debugger = self
        }
        
        deinit {
            self.dispose()
            ProcessLogger.deinitLog(self)
        }
        
        fileprivate func start() {
            self.displayLink = CADisplayLink(target: self, selector: #selector(updateDisplay))
            self.displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
            
            self.startTime = Date().timeIntervalSince1970

            self.isDubugLoop = true
            self.debugLoopQueue.async { [weak self] in
                guard let self = self else { return }
                let timer: Timer? = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.debugLoop), userInfo: nil, repeats: true)
                guard let mytimer: Timer = timer else { return }
                RunLoop.current.add(mytimer, forMode: RunLoop.Mode.tracking)
                while self.isDubugLoop {
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.0))
                }
            }
        }

        fileprivate func stop() {
            self.displayLink?.invalidate()
            self.startTime = Date().timeIntervalSince1970
            self.isDubugLoop = false
        }

        @objc private func debugLoop() {
            let currentTime: TimeInterval = Date().timeIntervalSince1970
            let mainthredFPS: Int = self.mainthredFPSDebugger.fps()

            let usedCPU: Int = Int(ProcessLogger.Device.usedCPU())
            let usedMemory: Int = Int(ProcessLogger.Device.usedMemory() ?? 0)
            let thermalState: Int = ProcessInfo.processInfo.thermalState.rawValue
            
            var compornetFPSList: [CCDebug.ComponentDebugger.Output.Data.CompornetFPS] = []
            for i in self.list {
                let name: String = String(describing: type(of: i))
                let fps: Int = i.debug?.fps() ?? 0
                //i.debug?.cpu()
                compornetFPSList.append(CCDebug.ComponentDebugger.Output.Data.CompornetFPS(name: name, fps: fps))
            }

            self.outPut.data.value = CCDebug.ComponentDebugger.Output.Data(
                time: Int(currentTime - self.startTime),
                mainthredFPS: mainthredFPS,
                compornetFPSList: compornetFPSList,
                usedCPU: usedCPU,
                usedMemory: usedMemory,
                thermalState: thermalState
            )

            /*
            self.writeQueue.async { [weak self] in
                guard let self = self else { return }
            }
             */
            self.outPut.data.notice()
        }

        @objc private func updateDisplay() {
            self.mainthredFPSDebugger.update()
        }

    }
}

fileprivate extension CCDebug.ComponentDebugger {
    func dispose() {
        self.stop()
        self.list = []
        self.outPut._dispose()
        self.displayLink?.invalidate()
        self.setup._dispose()
        self.triger._dispose()
    }
}


extension CCDebug.ComponentDebugger {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var debugger: CCDebug.ComponentDebugger?

        public func set(component: CCComponentProtocol) throws {
            component.isDebugMode = true
            self.debugger?.list.append(component)
        }

        fileprivate func _dispose() {
            self.debugger = nil
        }
    }

    // MARK: - Triger
    public class Triger: CCComponentTrigerProtocol {
        fileprivate var debugger: CCDebug.ComponentDebugger?

        public func start() {
            self.debugger?.start()
        }

        public func stop() {
            self.debugger?.stop()
        }

        public func dispose() {
            self.debugger?.dispose()
        }

        fileprivate func _dispose() {
            self.debugger = nil
        }
    }
}

public extension CCDebug.ComponentDebugger {
    class Output: NSObject {
        public struct Data {
            public struct CompornetFPS {
                public let name: String
                public let fps: Int
            }
            
            public var time: Int = 0
            public var mainthredFPS: Int = 0
            public var compornetFPSList: [CCDebug.ComponentDebugger.Output.Data.CompornetFPS] = []
            public var usedCPU: Int = 0
            public var usedMemory: Int = 0
            public var thermalState: Int = 0

            fileprivate func toArray() -> [String] {
                return [
                    String(self.time),
                    String(self.mainthredFPS),
                    String(self.usedCPU),
                    String(self.usedMemory),
                    String(self.thermalState),
                ]
            }
        }

        public var data: CCVariable<CCDebug.ComponentDebugger.Output.Data> = CCVariable(Data())
        
        fileprivate func _dispose() {
            self.data.dispose()
        }
    }
}

public extension CCDebug.ComponentDebugger {
    class FileWriter: NSObject {
        let lebels: [String] = ["time", "mainthredFPS", "cameraFPS", "imageProcessFPS", "liveViewFPS", "usedCPU", "usedMemory", "thermalState"]
        let documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        private var dirName: String = "test"
        let fileName: String = "data.csv"

        func createDir() throws {
            self.dirName = "Debug/\(Date().timeIntervalSince1970)"
            let dirPath = self.documentsPath + "/" + self.dirName
            try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            let filePath = self.documentsPath + "/" + self.dirName + "/" + self.fileName
            if FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil) {
                if let file: FileHandle = FileHandle(forWritingAtPath: filePath) {
                    self.write(list: self.lebels)
                }
            }
        }

        func write(list: [String]) {
            let filePath = self.documentsPath + "/" + self.dirName + "/" + self.fileName
            let listString: String = list.joined(separator: ",") + "\n"
            let contentData: Data = listString.data(using: String.Encoding.utf8)!
            if let file: FileHandle = FileHandle(forWritingAtPath: filePath) {
                file.seekToEndOfFile()
                file.write(contentData)
                file.closeFile()
            }
        }
    }
}
