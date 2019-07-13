//
//  Network.swift
//  awesomeOCR
//
//  Created by maxiao on 2019/7/2.
//  Copyright © 2019 maRk. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class NetWorkService {
    class func updateAccessToken() {
        Alamofire.request("https://aip.baidubce.com/oauth/2.0/token",
                          method: .post,
                          parameters: ["grant_type": "client_credentials",
                                       "client_id": "bfcQWWaUx6ocvbLKHIm1d4x3",
                                       "client_secret": "7oOGF7UDxGSZGT4G4DM36O6vLQhaKV4T"],
                          headers: nil)
            .responseJSON { (response) in
                let result = JSON(response.data).dictionary
                let access_token = result?["access_token"]?.stringValue
                let expireLimit = result?["expires_in"]?.intValue ?? 0
                
                let expire_date = Int64(expireLimit) + Int64(Date().timeIntervalSince1970)
                UserDefaults.standard.set("\(expire_date)", forKey: "expire_date")
                UserDefaults.standard.set(access_token, forKey: "access_token")
        }
    }
    
    class func reconize(image: String, callback: @escaping (String?, Error?) -> Void) {
 
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            callback(nil, NSError(domain: "token不存在！",
                                  code: -1,
                                  userInfo: nil))
            return
        }
            
        Alamofire.request("https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic",
                          method: .post,
                          parameters: ["image": image,
                                       "access_token": token,
                                       "language_type": "CHN_ENG"],
                          headers: ["Content-Type": "application/x-www-form-urlencoded"])
            .responseJSON { (response) in
                
                let result = JSON(response.data).dictionary
                
                if result?["error_code"]?.stringValue != nil || result?["error_msg"]?.stringValue != nil {
                    callback(nil, NSError(domain: "识别服务器报错!",
                                          code: -1,
                                          userInfo: nil))
                    return
                }
                
                let dataArray = result?["words_result"]?.arrayValue
                
                var totalString: String = ""
                for line in dataArray ?? [] {
                    totalString += "\(line["words"].stringValue)\n"
                }
                
                callback(totalString, nil)
        }
    }
}
