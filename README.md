# CameraCore

[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms iOS](https://img.shields.io/badge/Platforms-iOS-lightgray.svg?style=flat)](https://developer.apple.com/swift/)
[![Xcode 10.2+](https://img.shields.io/badge/Xcode-10.2+-blue.svg?style=flat)](https://developer.apple.com/swift/)


## 概要

このフレームワークは、映像や音声を少ない手続き・インターフェースで使えることを目指しています。

少ないコードで 動画の 撮影・再生・編集・エンコード を行うことができます。


#### 参考

* [AVFoundation プログラミングガイド](https://developer.apple.com/jp/documentation/AVFoundationPG.pdf)


#### 依存ライブラリ
CameraCoreは[MetalCanvas](https://github.com/Hideyuki-Machida/MetalCanvas)に依存しています。




## カメラ起動・Video撮影
### MetalVideoCaptureView（MTKView）

Class: [MetalVideoCaptureView.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/CameraCore/Renderer/VideoCapture/MetalVideoCaptureView.swift)

Protocol: [VideoCaptureViewProtocol.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/CameraCore/Renderer/VideoCapture/VideoCaptureViewProtocol.swift)

Example: [MetalVideoCaptureViewExampleVC.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/Example/CameraCoreExample/MetalVideoCaptureViewExampleVC.swift)




## CompositionDataをセットしVideoを再生
### MetalVideoPlaybackView（MTKView）

Class: [MetalVideoPlaybackView.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/CameraCore/Renderer/CompositionAVPlayer/MetalVideoPlaybackView.swift)

Protocol: [CompositionAVPlayerProtocol.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/CameraCore/Renderer/CompositionAVPlayer/CompositionAVPlayerProtocol.swift)

Example: [MetalVideoPlaybackViewExampleVC.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/Example/CameraCoreExample/MetalVideoPlaybackViewExampleVC.swift)

<br />
#### CompositionDataについて

MetalVideoPlaybackViewでは、セットされた CompositionData を基に動画を描画します。<br />
CompositionDataは、複数のTrack、さらに複数のAssetで構成されます。<br />
CompositionDataは、Track内でのAssetの再生開始位置・transformなどの編集情報をパラメータとして保持します。

CameraCoreの基本データModel

```
CompositionData
CompositionTrackProtocol (CompositionVideoTrack, CompositionAudioTrack)
CompositionAssetProtocol (CompositionVideoAsset, CompositionAudioAsset)
```

|Data|Track|Asset|
|:---|:---|:---|
|CompositionData|CompositionVideoTrack {n個}|CompositionVideoAsset {n個}|
||CompositionAudioTrack {n個}|CompositionAudioAsset {n個}|

* 下記の図のように、動画編集ソフトのタイムラインのように扱います。<br>
* 一つのTrackには、複数のAssetの配置が可能です。<br>
* TrackにAssetを配置するには、下記を指定します。<br>
	* atTime: Track内のAssetスタート時間<br>
	* TrimTimeRange: Assetの再生レンジ

![画像](./timeline.png)
Example: [CompositionAVPlayerExampleVC.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/Example/CameraCoreExample/CompositionAVPlayerExampleVC.swift)


## CompositionDataをセットしAudioを再生
### CompositionAVPlayer

Class: [MetalCompositionAVPlayer.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/CameraCore/Renderer/CompositionAVPlayer/MetalCompositionAVPlayer.swift)

Protocol: [CompositionAVPlayerProtocol.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/CameraCore/Renderer/CompositionAVPlayer/CompositionAVPlayerProtocol.swift)

Example: [CompositionAVPlayerExampleVC.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/Example/CameraCoreExample/CompositionAVPlayerExampleVC.swift)


## ImageProcessing

CompositionVideoAssetには、それぞれに PhotoShopの調整レイヤーのようなエフェクトレイヤー（RenderLayer）を加えることができます。

### RenderLayer

ビデオのフレーム毎に画像処理をしたい場合に用いるレイヤー

Protocol: [RenderLayerProtocol.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/CameraCore/ImageProcessing/RenderLayerProtocol.swift)

Example: [RenderLayerExampleVC.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/Example/CameraCoreExample/RenderLayerExampleVC.swift)


## コンポジションしたビデオをエンコード & 保存
### VideoEncoder

Protocol: [VideoBitRateEncoder.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/CameraCore/Encoder/VideoBitRateEncoder.swift)

Example: [VideoBitRateEncoderExampleVC.swift](https://github.com/Hideyuki-Machida/CameraCore/blob/master/Example/CameraCoreExample/VideoBitRateEncoderExampleVC.swift)
