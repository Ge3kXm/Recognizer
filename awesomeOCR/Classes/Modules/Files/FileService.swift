//
//  FileManager.swift
//  awesomeOCR
//
//  Created by maRk'sTheme on 2019/7/6.
//  Copyright © 2019 maRk. All rights reserved.
//

import Foundation

fileprivate let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
fileprivate let fullPath = (filePath as NSString).appendingPathComponent("files.plist")

class FileService {
    
    class func save(files: [[String: String]]) {
        
        FileService.removeOldData()
        if files.isEmpty { return }
        NSKeyedArchiver.archiveRootObject(files, toFile: fullPath)
    }
    
    class func getFiles() -> [[String: String]]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: fullPath) as? [[String: String]]
    }
    
    class func update(title: String, content: String, index: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard var array = FileService.getFiles() else { return }
        array[index]["time"] = dateFormatter.string(from: Date())
        array[index]["content"] = content
        
        FileService.removeOldData()
        NSKeyedArchiver.archiveRootObject(array, toFile: fullPath)
    }
    
    class func removeOldData() {
        let fileManager = FileManager.default
        
        if fileManager.isDeletableFile(atPath: fullPath) {
            try? fileManager.removeItem(atPath: fullPath)
        }
    }
}
