//
//  ImageCacheManager.swift
//  DocsSDK
//
//  Created by maxiao on 2019/6/13.
//

import UIKit

class CacheManager {

    static let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                               .userDomainMask, true).last!
    static let imageFileDir = (cachePath as NSString).appendingPathComponent("CacheManager")

    class func save(data: Data, with fileName: String) -> String? {
        let filePath = (imageFileDir as NSString).appendingPathComponent(fileName)
        let fileManager = FileManager.default
        let isDir = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        let isFileExist = fileManager.fileExists(atPath: imageFileDir,
                                                 isDirectory: isDir)
        if isFileExist {
            if isDir.pointee.boolValue {
                do {
                    try data.write(to: URL(fileURLWithPath: filePath),
                                        options: .atomicWrite)
                } catch {
                    return nil
                }
            }
            return filePath
        } else {
            do {
                try fileManager.createDirectory(atPath: imageFileDir,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
                try data.write(to: URL(fileURLWithPath: filePath),
                                    options: .atomicWrite)
            } catch {
                return nil
            }
        }
        return filePath
    }

    class func data(with fileName: String) -> Data? {
        let filePath = (imageFileDir as NSString).appendingPathComponent(fileName)

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            return data
        } catch {
            return nil
        }
    }

    class func removeAllCacheFile() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(atPath: imageFileDir)
    }

    class func removeItem(at filePath: String) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(atPath: filePath)
    }
}
