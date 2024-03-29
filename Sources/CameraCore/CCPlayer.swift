//
//  CCPlayer.swift
//  CameraCore
//
//  Created by hideyuki machida on 2020/03/31.
//  Copyright © 2020 hideyuki machida. All rights reserved.
//

import AVFoundation
import Foundation
import MetalCanvas
import MetalKit
import ProcessLogger_Swift

public class CCPlayer: NSObject, CCComponentProtocol {
    fileprivate let queue: DispatchQueue = DispatchQueue(label: "CameraCore.CCPlayer.Queue")

    public let setup: CCPlayer.Setup = CCPlayer.Setup()
    public let trigger: CCPlayer.Trigger = CCPlayer.Trigger()
    public let pipe: CCPlayer.Pipe = CCPlayer.Pipe()
    public let event: CCPlayer.Event = CCPlayer.Event()
    public var debug: CCComponentDebug?

    private var timeObserverToken: Any?
    
    private var displayLink: CADisplayLink?
    private var isLoop: Bool = false
    private var player: AVPlayer = AVPlayer()
    private let output: AVPlayerItemVideoOutput = {
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
        return AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
    }()

    public override init() {
        super.init()

        if let timeObserverToken = self.timeObserverToken {
            self.player.removeTimeObserver(timeObserverToken)
        }

        self.setup.player = self
        self.trigger.player = self
        self.pipe.player = self
        self.event.player = self
    }
    
    deinit {
        self.dispose()
        ProcessLogger.deinitLog(self)
    }
    
    func update(url: URL) {
        let avAsset: AVURLAsset = AVURLAsset(url: url)
        let playerItem: AVPlayerItem = AVPlayerItem(asset: avAsset)
        self.player = AVPlayer(playerItem: playerItem)
        
        let time: CMTime = CMTime(seconds: 1.0 / 120.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.timeObserverToken = self.player.addPeriodicTimeObserver(forInterval: time, queue: self.queue) { [weak self] (time: CMTime) in
            self?.updatePlayerTime(time: time)
        }
        playerItem.observe(\.status, options: [.initial, .new], changeHandler: { [weak self](item: AVPlayerItem, status: NSKeyValueObservedChange<AVPlayerItem.Status>) in
            print("value", status)
            switch status.newValue {
            case .readyToPlay: print("readyToPlay")
            case .failed: print("failed")
            case .unknown:  print("unknown")
            case .some(_): print("some")
            case .none: print("none")
            }
        })


        //self.player.actionAtItemEnd = .none
        //playerItem.add(self.output)
        self.player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        self.player.currentItem?.add(self.output)

        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(avPlayerItemDidPlayToEndTime),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        self.event.status.value = CCPlayer.Status.ready
        self.event.status.notice()
    }

    fileprivate func play() {
        self.isLoop = true
        self.player.play()
        self.event.status.value = CCPlayer.Status.play
        self.event.status.notice()
    }
    
    fileprivate func pause() {
        self.player.pause()
        self.event.status.value = CCPlayer.Status.pause
        self.event.status.notice()
    }

    public func seek(progress: Float) {
        guard let totalDuration: CMTime = self.player.currentItem?.duration else { return }
        //self.event.status = CCPlayer.Status.seek.rawValue
        let s: Double = Double(totalDuration.value) / Double(totalDuration.timescale)
        let time: Double = s * Double(progress)
        let cmtime: CMTime = CMTime(seconds: time, preferredTimescale: totalDuration.timescale).convertScale(30, method: .roundHalfAwayFromZero)
        
        self.player.pause()
        self.player.seek(to: cmtime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        self.event.status.value = CCPlayer.Status.seek
        self.event.status.notice()
    }

    private func updatePlayerTime(time currentTime: CMTime) {
        guard
            let duration: CMTime = self.player.currentItem?.duration,
            self.output.hasNewPixelBuffer(forItemTime: currentTime),
            let pixelBuffer: CVPixelBuffer = self.output.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)
        else { return }
        do {
            var texture: CCTexture = try CCTexture.init(pixelBuffer: pixelBuffer, planeIndex: 0)
            texture.presentationTimeStamp = currentTime
            self.pipe.outUpdate(texture: texture)
            self.event.outPresentationTimeStamp.value = currentTime
            self.event.outProgress.value = currentTime.seconds / duration.seconds
            self.event.outPresentationTimeStamp.notice()
            self.event.outProgress.notice()

            // デバッグ
            self.debug?.update(thred: Thread.current, queue: CCCapture.videoOutputQueue)
            self.debug?.update()
        } catch {
            
        }
    }
        
    /// 再生が終了したときの処理
    @objc private func avPlayerItemDidPlayToEndTime(_ notification: Notification) {
        let item: AVPlayerItem = notification.object as! AVPlayerItem

        self.event.outProgress.value = 1.0
        self.event.outProgress.notice()
        self.event.status.value = CCPlayer.Status.endTime
        self.event.status.notice()

        // ループ
        item.seek(to: CMTime.zero, completionHandler: nil)
    }
}

fileprivate extension CCPlayer {
    func dispose() {
        //self.event.status = CCPlayer.Status.dispose.rawValue
        self.displayLink?.invalidate()
        self.player.pause()
        self.isLoop = false
        self.setup._dispose()
        self.trigger._dispose()
        self.pipe._dispose()
        self.event._dispose()
        NotificationCenter.default.removeObserver(self)
    }
}

extension CCPlayer {
    public enum Status: Int {
        case setup = 0
        case update
        case ready
        case play
        case pause
        case seek
        case dispose
        case endTime
    }
}

extension CCPlayer {
    // MARK: - Setup
    public class Setup: CCComponentSetupProtocol {
        fileprivate var player: CCPlayer?
        
        public func update(url: URL) {
            self.player?.update(url: url)
        }

        public func seek(url: URL) {
            self.player?.update(url: url)
        }

        fileprivate func _dispose() {
            self.player = nil
        }
    }

    // MARK: - Trigger
    public class Trigger: CCComponentTriggerProtocol {
        fileprivate var player: CCPlayer?

        public func play() {
            self.player?.play()
        }

        public func pause() {
            self.player?.pause()
        }

        public func seek(progress: Float) {
            self.player?.seek(progress: progress)
        }

        public func dispose() {
            self.player?.dispose()
        }

        fileprivate func _dispose() {
            self.player = nil
        }
    }

    // MARK: - Pipe
    public class Pipe: NSObject, CCComponentPipeProtocol {
        private let completeQueue: DispatchQueue = DispatchQueue(label: "CameraCore.CCPlayer.Complete")

        fileprivate var player: CCPlayer?

        public var outTexture: CCVariable<CCTexture?> = CCVariable(nil)

        fileprivate func outUpdate(texture: CCTexture) {
            self.outTexture.value = texture
            self.completeQueue.async { [weak self] in
                self?.outTexture.notice()
                self?.outTexture.value = nil
            }
        }

        fileprivate func _dispose() {
            self.player = nil
            self.outTexture.dispose()
        }
    }
    
    // MARK: - Event
    public class Event: NSObject, CCComponentEventProtocol {
        fileprivate var player: CCPlayer?
        public var outPresentationTimeStamp: CCVariable<CMTime> = CCVariable(CMTime.zero)
        public var outProgress: CCVariable<TimeInterval> = CCVariable(TimeInterval.zero)
        public var status: CCVariable<CCPlayer.Status> = CCVariable(CCPlayer.Status.setup)
        
        fileprivate func _dispose() {
            self.player = nil
            self.outPresentationTimeStamp.dispose()
            self.outProgress.dispose()
            self.status.dispose()
        }
    }
}
