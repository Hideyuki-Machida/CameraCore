//
//  VideoFileManager.swift
//  MystaVideoModule
//
//  Created by machidahideyuki on 2018/01/08.
//  Copyright © 2018年 tv.mysta. All rights reserved.
//

import Foundation
import AssetsLibrary
import Photos

extension CCCameraRoll {
    final public class Manager: NSObject {
        
        public enum ErrorType: Error {
            case authorizeError
            case move
            case createAlbum
            case save
        }

        public enum SaveType {
            case copy
            case move
        }

        fileprivate let queue: DispatchQueue = DispatchQueue(label: "AVModule.CameraRollManager.queue", attributes: .concurrent)

        public static var imageSize: CGSize = CGSize(width: 200, height: 200)
        public static var albumName: String = "CameraCore_Album" {
            didSet {
                self._setup { (result: Result<PHAssetCollection, Error>) in
                    do {
                        Debug.ActionLog(try result.get())
                    } catch {
                        
                    }
                }
            }
        }

        fileprivate static let udKey: String = "AVModule.CameraRollManager_album_localIdentifier"
        fileprivate static var album: PHAssetCollection?
        
        static public func preFetch() {
            //self._setup {_ in }
        }
        
        public static func save(videoFileURL: URL, type: SaveType = .copy, completion: @escaping (Result<URL, Error>) -> Void) {
            self.authorization { (result: Bool) in
                if result == true {
                    // アクセス許可有り
                    self._setup { (result: Result<PHAssetCollection, Error>) in
                        do {
                            CCCameraRoll.Manager.album = try result.get()
                        } catch {
                            completion(.failure(ErrorType.createAlbum))
                        }
                    }
                    //
                    guard let album = CCCameraRoll.Manager.album else { completion(.failure(ErrorType.createAlbum)); return }
                    var identifier: String? = nil
                    PHPhotoLibrary.shared().performChanges({
                        let assetRequest: PHAssetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoFileURL)!
                        let albumChangeRequest: PHAssetCollectionChangeRequest? = PHAssetCollectionChangeRequest(for: album)
                        let placeHolder: PHObjectPlaceholder = assetRequest.placeholderForCreatedAsset!
                        albumChangeRequest?.addAssets([placeHolder] as NSArray)
                        identifier = assetRequest.placeholderForCreatedAsset!.localIdentifier
                        
                    }, completionHandler: { (success, err) in
                        if success == true {
                            Debug.SuccessLog("保存成功！")
                            let assets  = PHAsset.fetchAssets(withLocalIdentifiers: [identifier!], options: nil)
                            let options: PHVideoRequestOptions = PHVideoRequestOptions()
                            PHImageManager.default().requestAVAsset(forVideo: assets.firstObject!, options: options, resultHandler: { (item: AVAsset?, audio: AVAudioMix?, AnyHashable: [AnyHashable : Any]?) in
                                let ass: AVURLAsset = item as! AVURLAsset

                                switch type {
                                case .copy:
                                    completion(.success(ass.url))
                                case .move:
                                    do {
                                        try FileManager.default.removeItem(at: videoFileURL)
                                        completion(.success(ass.url))
                                    } catch {
                                        completion(.failure(ErrorType.save))
                                    }
                                }
                            })
                        } else {
                            Debug.ErrorLog("保存失敗！ \(String(describing: err)) \(String(describing: err?.localizedDescription))")
                            completion(.failure(ErrorType.save))
                        }
                    })
                    //
                } else {
                    completion(.failure(ErrorType.authorizeError))
                }
                
            }
        }
        
        //
        public static func authorization(completion: @escaping ((_ result: Bool) -> Void) ) {
            let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                // アクセス許可あり
                Debug.SuccessLog("アクセス許可あり")
                completion(true)
            case .restricted:
                // ユーザー自身にカメラへのアクセスが許可されていない
                Debug.ErrorLog("ユーザー自身にカメラへのアクセスが許可されていない")
            case .notDetermined:
                // まだアクセス許可を聞いていない
                Debug.ErrorLog("まだアクセス許可を聞いていない")
                PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) in
                    if status == .authorized {
                        completion(true)
                    } else {
                        completion(false)
                    }
                })
            case .denied:
                // アクセス許可されていない
                Debug.ErrorLog("アクセス許可されていない")
                PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) in
                    if status == .authorized {
                        completion(true)
                    } else {
                        completion(false)
                    }
                })
            @unknown default:
                completion(false)
            }
        }
        
        fileprivate static func _setup(completion: @escaping (Result<PHAssetCollection, Error>) -> Void) {
            let albumLocalIdentifier: String? = UserDefaults.standard.string(forKey: self.udKey)
            if albumLocalIdentifier == nil {
                // アルバムIDが保存されていない
                self._createAlbum(completion: { (result: Result<String, Error>) in
                    do {
                        let albumLocalIdentifier = try result.get()
                        if let album: PHAssetCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumLocalIdentifier], options: nil).firstObject {
                            completion(.success(album))
                        } else {
                            completion(.failure(ErrorType.createAlbum))
                        }
                    } catch {
                        completion(.failure(ErrorType.createAlbum))
                    }
                })
            } else {
                // アルバムIDが保存されている
                if let album: PHAssetCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumLocalIdentifier!], options: nil).firstObject {
                    // アルバムが取得できた
                    completion(.success(album))
                } else {
                    self._createAlbum(completion: { (result: Result<String, Error>) in
                        do {
                            let albumLocalIdentifier = try result.get()
                            if let album: PHAssetCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumLocalIdentifier], options: nil).firstObject {
                                completion(.success(album))
                            } else {
                                UserDefaults.standard.removeObject(forKey: self.udKey)
                                completion(.failure(ErrorType.createAlbum))
                            }
                        } catch {
                            completion(.failure(ErrorType.createAlbum))
                        }
                    })
                }
            }
        }
        
        // albumLocalIdentifier
        fileprivate static func _createAlbum(completion: @escaping (Result<String, Error>) -> Void) {
            var albumLocalIdentifier: String? = nil
            let list: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.any, options:nil)
            list.enumerateObjects({ (album: PHAssetCollection, index, isStop) -> Void in
                if album.localizedTitle == self.albumName {
                    Debug.ActionLog("\(self.albumName) アルバムがすでに存在する")
                    albumLocalIdentifier = album.localIdentifier
                    UserDefaults.standard.set(albumLocalIdentifier, forKey: self.udKey)
                    if let id: String = albumLocalIdentifier {
                        completion(.success(id))
                    } else {
                        completion(.failure(ErrorType.createAlbum))
                    }

                    return
                }
            })
            guard albumLocalIdentifier == nil else { return }
            
            Debug.ActionLog("\(self.albumName) アルバムが存在しないので作成")
            PHPhotoLibrary.shared().performChanges({ () -> Void in
                let request: PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
                albumLocalIdentifier = request.placeholderForCreatedAssetCollection.localIdentifier
            }, completionHandler: { (isSuccess, error) -> Void in
                if isSuccess == true {
                    Debug.ActionLog("\(self.albumName) アルバム作成成功")
                    UserDefaults.standard.set(albumLocalIdentifier, forKey: self.udKey)
                    completion(.success(albumLocalIdentifier!))
                } else{
                    Debug.ActionLog("\(self.albumName) アルバム作成失敗")
                    completion(.failure(ErrorType.createAlbum))
                }
            })
        }
    }
}


extension CCCameraRoll.Manager {
	/// カメラロールからアセット一式を取得
    public static func fetchPHAssetData(completion: @escaping ((_ items: [CCCameraRoll.Item])->Void)) {
		
        var resultItem: [CCCameraRoll.Item] = []
        self._getAssetItem(mediaType: CCCameraRoll.AssetType.image) { (item: [CCCameraRoll.Item]) in
			resultItem += item
            self._getAssetItem(mediaType: CCCameraRoll.AssetType.video) { (item: [CCCameraRoll.Item]) in
				resultItem += item
                resultItem.sort { (lhs: CCCameraRoll.Item, rhs: CCCameraRoll.Item) -> Bool in
					return lhs.creationDate > rhs.creationDate
				}
				DispatchQueue.main.async {
					completion(resultItem)
				}
			}
		}
	}

	/// カメラロールからVideoアセット一式を取得
    public static func fetchPHAssetData(mediaType: CCCameraRoll.AssetType, completion: @escaping ((_ items: [CCCameraRoll.Item])->Void)) {
		
        var resultItem: [CCCameraRoll.Item] = []
        self._getAssetItem(mediaType: mediaType) { (item: [CCCameraRoll.Item]) in
			resultItem += item
            resultItem.sort { (lhs: CCCameraRoll.Item, rhs: CCCameraRoll.Item) -> Bool in
				return lhs.creationDate > rhs.creationDate
			}
			DispatchQueue.main.async {
				completion(resultItem)
			}
		}
	}
}

extension CCCameraRoll.Manager {
    private static func _getAssetItem(mediaType: CCCameraRoll.AssetType, completion: @escaping ((_ items: [CCCameraRoll.Item])->Void)) {
		DispatchQueue.global(qos: .utility).async {
            var items: [CCCameraRoll.Item] = []
			let options: PHFetchOptions = PHFetchOptions()
			options.sortDescriptors = [
				NSSortDescriptor(key: "creationDate", ascending: false)
			]
			
			let result: PHFetchResult = PHAsset.fetchAssets(with: mediaType.phAssetMediaType, options: options)
			var count: Int = 0
			result.enumerateObjects(options: []) { (phAsset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                items.append(CCCameraRoll.Item(asset: phAsset, mediaType: mediaType.phAssetMediaType, creationDate: phAsset.creationDate!))
				count += 1
				if count >= result.count {
					completion(items)
				}
			}
		}
	}
}
