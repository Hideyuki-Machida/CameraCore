//
//  CodableAVAsset.swift
//  CameraCore
//
//  Created by hideyuki machida on 2018/08/27.
//  Copyright © 2018 町田 秀行. All rights reserved.
//

import AVFoundation

public enum CodableURLType: Int {
    case userFile = 0
    case bundleFile = 1
    case other = 2

    public func path(url: URL) -> String {
        switch self {
        case .userFile:
            let documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let range: NSRange = (documentsPath as NSString).range(of: "Documents")
            let str: String = (url.relativePath as NSString).replacingCharacters(in: NSRange.init(location: 0, length: range.location - 1), with: "")
            return str
        case .bundleFile:
            let bundlePath: String = Bundle.main.bundlePath
            let range: NSRange = (bundlePath as NSString).range(of: Bundle.main.bundlePath)
            return (url.relativePath as NSString).replacingCharacters(in: range, with: "")
        case .other:
            return url.absoluteString
        }
    }
    public func url(path: String) -> URL {
        switch self {
        case .userFile:
            var documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            documentsPath = (documentsPath as NSString).replacingOccurrences(of: "Documents", with: "") as String
            return URL.init(fileURLWithPath: documentsPath + path)
        case .bundleFile:
            let bundlePath: String = Bundle.main.bundlePath
            return URL.init(fileURLWithPath: bundlePath + path)
        case .other:
            return URL.init(string: path)!
        }
    }
}

public struct CodableURL {
    public var type: CodableURLType {
        guard self.url.absoluteString.hasPrefix("file://") else { return .other}
        if self.url.relativePath.hasPrefix(Bundle.main.bundlePath) {
            return .bundleFile
        } else if self.url.relativePath.hasPrefix("/var/mobile/Media/") {
            return .other
        } else {
            return .userFile
        }
    }

    public var url: URL
    public init(url: URL) {
        self.url = url
    }
}


extension CodableURL {
    enum CodingKeys: String, CodingKey {
        case type
        case url
    }
}

extension CodableURL: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let type: CodableURLType = self.type
        try container.encode(type.rawValue, forKey: .type)
        switch type {
        case .userFile:
            try container.encode(type.path(url: self.url), forKey: .url)
        case .bundleFile:
            try container.encode(type.path(url: self.url), forKey: .url)
        case .other:
            try container.encode(self.url.absoluteString, forKey: .url)
        }
    }
}

extension CodableURL: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type: CodableURLType = CodableURLType.init(rawValue: try values.decode(Int.self, forKey: .type))!
        let path: String = try values.decode(String.self, forKey: .url)
        self.url = type.url(path: path)
    }
}
