# iOS_AVModule
iOSのAVFoundationラッパー（映像・音声）

[AVFoundation プログラミングガイド](https://developer.apple.com/jp/documentation/AVFoundationPG.pdf)



## カメラ起動・Video撮影
### VideoCaptureView（GLKitView）

Class: [VideoCaptureView.swift](https://github.com/CChannel/iOS_AVModule/blob/master/iOS_AVModule/Render/VideoCapture/VideoCaptureView.swift)

Protocol: [VideoCaptureViewProtocol.swift](https://github.com/CChannel/iOS_AVModule/blob/master/iOS_AVModule/Render/VideoCapture/VideoCaptureViewProtocol.swift)

Example: [VideoCaptureViewExampleVC.swift](https://github.com/CChannel/iOS_AVModule/blob/master/Example/iOS_AVModule_Example/iOS_AVModule_Example/VideoCaptureViewExampleVC.swift)


## CompositionDataをセットし、Videoを再生
### VideoPlaybackView（GLKitView）

Class: [VideoPlaybackView.swift](https://github.com/CChannel/iOS_AVModule/blob/master/iOS_AVModule/Render/CompositionAVPlayer/VideoPlaybackView.swift)

Protocol: [CompositionAVPlayerProtocol.swift](https://github.com/CChannel/iOS_AVModule/blob/master/iOS_AVModule/Render/CompositionAVPlayer/CompositionAVPlayerProtocol.swift)

Example: [VideoPlaybackViewExampleVC.swift](https://github.com/CChannel/iOS_AVModule/blob/master/Example/iOS_AVModule_Example/iOS_AVModule_Example/VideoPlaybackViewExampleVC.swift)


## CompositionDataをセットし、Video・Audioを再生
### CompositionAVPlayer

Class: [CompositionAVPlayer.swift](https://github.com/CChannel/iOS_AVModule/blob/master/iOS_AVModule/Render/CompositionAVPlayer/CompositionAVPlayer.swift)

Protocol: [CompositionAVPlayerProtocol.swift](https://github.com/CChannel/iOS_AVModule/blob/master/iOS_AVModule/Render/CompositionAVPlayer/CompositionAVPlayerProtocol.swift)

Example: [CompositionAVPlayerExampleVC.swift](https://github.com/CChannel/iOS_AVModule/blob/master/Example/iOS_AVModule_Example/iOS_AVModule_Example/CompositionAVPlayerExampleVC.swift)


## ImageProcessing
### RenderLayer

ビデオのフレーム毎に画像処理をしたい場合に用いるレイヤー（PhotoShopの調整レイヤーのイメージ）

Protocol: [RenderLayerProtocol.swift](https://github.com/CChannel/iOS_AVModule/blob/master/iOS_AVModule/ImageProcessing/RenderLayerProtocol.swift)

Example: [RenderLayerExampleVC.swift](https://github.com/CChannel/iOS_AVModule/blob/master/Example/iOS_AVModule_Example/iOS_AVModule_Example/RenderLayerExampleVC.swift)


## コンポジションしたビデオをエンコード & 保存
### VideoEncoder

Protocol: [VideoBitRateEncoder.swift](https://github.com/CChannel/iOS_AVModule/blob/master/iOS_AVModule/Encoder/VideoBitRateEncoder.swift)

Example: [VideoBitRateEncoderExampleVC.swift](https://github.com/CChannel/iOS_AVModule/blob/master/Example/iOS_AVModule_Example/iOS_AVModule_Example/VideoBitRateEncoderExampleVC.swift)


## CompositionData

iOS_AVModuleの基本データModel

```
CompositionData
CompositionTrackProtocol (CompositionVideoTrack, CompositionAudioTrack)
CompositionAssetProtocol (CompositionVideoAsset, CompositionAudioAsset)
```

