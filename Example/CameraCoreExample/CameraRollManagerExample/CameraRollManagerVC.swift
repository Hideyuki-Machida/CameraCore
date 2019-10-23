//
//  CameraRollManagerVC.swift
//  CameraCore_Example
//
//  Created by hideyuki machida on 2018/08/27.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import UIKit
import AVFoundation
import CameraCore
import iOS_DummyAVAssets

class CameraRollManagerVC: UIViewController {
    
    fileprivate var datas: [CameraRollItem] = []
    fileprivate let refreshControl: UIRefreshControl = UIRefreshControl()
    @IBOutlet fileprivate(set) weak var collectionView: UICollectionView!
    
    deinit {
        Debug.DeinitLog(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CameraRollManager.albumName = "Test Album"
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.collectionViewLayout = self.flowLayout()
        self.refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        self.collectionView.addSubview(self.refreshControl)
		self.collectionView.sendSubviewToBack(self.refreshControl)

        self.setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        self.setup()
    }
    
    func setup() {
        CameraRollManager.authorization { [weak self] (success: Bool) in
            guard let `self` = self else { return }
            guard success == true else {
                return
            }
            CameraRollManager.fetchPHAssetData() { [weak self] (items: [CameraRollItem]) in
                self?.datas = items
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.endRefreshing()
                    self?.collectionView.reloadData()
                }
                
            }
        }

    }

}

// MARK: - Layout

extension CameraRollManagerVC {
    
    private func flowLayout() -> UICollectionViewFlowLayout {
        let cellCountPerRow: CGFloat = 3
        let flow: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
		flow.sectionInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flow.minimumLineSpacing = 0.0
        flow.minimumInteritemSpacing = 0
        
        let screenWidth: CGFloat = UIScreen.main.bounds.size.width
        let inset: CGFloat = flow.sectionInset.left + flow.sectionInset.right
        let availableFullSide: CGFloat = screenWidth - inset - (0.0 * (cellCountPerRow - 1))
        let width : CGFloat = floor(availableFullSide / cellCountPerRow)
        flow.itemSize = CGSize(width: width, height: width)
        
        return flow
    }
    
}


// MARK: - UICollectionViewDataSource

extension CameraRollManagerVC: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datas.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CameraRollManagerVCCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CameraRollManagerVCCell
        let data: CameraRollItem = self.datas[indexPath.row]
        cell.setData(data: data)
        return cell
    }
}


// MARK: - UICollectionViewDelegate

extension CameraRollManagerVC: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cameraRollItem: CameraRollItem = self.datas[indexPath.row]
        switch cameraRollItem.mediaType {
        case .video:
            cameraRollItem.getVideoURL(
                exportPreset: Settings.PresetSize.p1920x1080,
                progressUpdate: { [weak self] (progress) in
					DispatchQueue.main.async { [weak self] in
						// クラウド上にある場合のダウンロードプログレス
						self?.progress(progress: progress)
					}
			}) { [weak self] (result) in
                guard let self = self else { return }
				do {
					let urlAsset: AVURLAsset = try result.get()
					self.performSegue(withIdentifier: SegueId.openVideoPreview.rawValue, sender: urlAsset)
					/*
					/////////////////////////////////////////////////
					// Create: CompositionData
					let compositionVideoAsset001: CompositionVideoAsset = CompositionVideoAsset.init(
						avAsset: urlAsset,
						layers: [
							try LutLayer.init(lutImageURL: iOS_DummyAVAssets.AssetManager.LutAsset.vivid.url, dimension: 64)
						],
						atTime: CMTime.init(value: 0, timescale: 44100),
						contentMode: .scaleAspectFill
					)
					/////////////////////////////////////////////////

					/////////////////////////////////////////////////
					// Setup
					let compositionData = CompositionData(
						videoTracks: [
							try CompositionVideoTrack.init(assets: [compositionVideoAsset001])
						],
						audioTracks: [],
						property: self.videoCompositionProperty
					)
					self.performSegue(withIdentifier: SegueId.openVideoPreview.rawValue, sender: compositionData)
					/////////////////////////////////////////////////
*/
				} catch {
					// エラー
					print(error)
				}
            }
        case .image:
            cameraRollItem.getImageData(
				progressUpdate: { [weak self] (progress: Double) in
                    guard let self = self else { return }
                    // クラウド上にある場合のダウンロードプログレス
					DispatchQueue.main.async { [weak self] in
						// クラウド上にある場合のダウンロードプログレス
						self?.progress(progress: progress)
					}
			}) { [weak self] (result) in
                guard let self = self else { return }
				do {
					let data: Data = try result.get()
					guard let image: UIImage = UIImage.init(data: data) else { print("UIImage 変換エラー"); return }
					self.performSegue(withIdentifier: SegueId.openImagePreview.rawValue, sender: image)
					/////////////////////////////////////////////////
				} catch {
					// エラー
					print(error)
				}

            }

        default: break
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell: CameraRollManagerVCCell = collectionView.cellForItem(at: indexPath) as? CameraRollManagerVCCell else { return }
        cell.tapInAnimation()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell: CameraRollManagerVCCell = collectionView.cellForItem(at: indexPath) as? CameraRollManagerVCCell else { return }
        cell.tapOutAnimation()
    }
}

extension CameraRollManagerVC {
	func progress(progress: Double) {
		guard let indicatorVC: ProgressViewVC = self.presentedViewController as? ProgressViewVC else {
			self.performSegue(withIdentifier: SegueId.openProgressView.rawValue, sender: nil)
			return
		}
		indicatorVC.progressLabel.text = String(progress)
		if progress >= 1.0 {
			indicatorVC.dismiss(animated: true, completion: nil)
		}
	}
}


// MARK: - Segue

extension CameraRollManagerVC {
    
    public enum SegueId: String {
        case openVideoPreview = "openVideoPreview"
        case openImagePreview = "openImagePreview"
        case openProgressView = "openProgressView"
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier: String = segue.identifier else { return }
        guard let segueId: SegueId = SegueId(rawValue: identifier) else { return }
        
        switch segueId {
        case .openVideoPreview:
			guard let urlAsset: AVURLAsset = sender as? AVURLAsset else { return }
            guard let vc: CameraRollManagerVideoPreviewVC = segue.destination as? CameraRollManagerVideoPreviewVC else { return }
			vc.playerItem = AVPlayerItem.init(asset: urlAsset)
			case .openImagePreview:
				guard let image: UIImage = sender as? UIImage else { return }
				guard let vc: CameraRollManagerImagePreviewVC = segue.destination as? CameraRollManagerImagePreviewVC else { return }
				vc.image = image

		case .openProgressView: break
        }
    }
}


// MARK: - CameraRollManagerVCCell

final class CameraRollManagerVCCell: UICollectionViewCell {
    
    @IBOutlet fileprivate(set) weak var thumbnailView: UIImageView!
    @IBOutlet fileprivate(set) weak var durationLabel: UILabel!
    @IBOutlet fileprivate(set) weak var tapEffect: UIView!
    
    private var gradientLayer: CAGradientLayer?
    private var data: CameraRollItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tapEffect.alpha = 0
    }
    
    deinit {
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.thumbnailView.image = nil
        self.data = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setData(data: CameraRollItem) {
        self.data = data
        switch data.mediaType {
        case .video:
            self.durationLabel.isHidden = false
        default:
            self.durationLabel.isHidden = true
        }
        
        self.durationLabel.text = data.asset.duration.mssString
        self.data?.onThumbnailLoadCompletion = { [weak self] (image: UIImage?) in
            DispatchQueue.main.async {
                self?.thumbnailView.image = image
            }
        }
        self.data?.requestThumbnail()
    }
    
    func tapInAnimation() {
		UIView.animate(withDuration: 0.1, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.tapEffect.alpha = 1
            //self.thumbnailView.layer.transform = CATransform3DMakeScale(0.94, 0.94, 1.0)
        }) { (val: Bool) in
			UIView.animate(withDuration: 0.1, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.tapEffect.alpha = 0
                //self.thumbnailView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
            }) { (val: Bool) in
                
            }
        }
        
    }
    func tapOutAnimation() {
		UIView.animate(withDuration: 0.1, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.tapEffect.alpha = 1
            //self.thumbnailView.layer.transform = CATransform3DMakeScale(0.94, 0.94, 1.0)
        }) { (val: Bool) in
			UIView.animate(withDuration: 0.1, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.tapEffect.alpha = 0
                //self.thumbnailView.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
            }) { (val: Bool) in
                
            }
        }
    }
}
