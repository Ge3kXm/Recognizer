//
//  ImageUtil.swift
//  awesomeOCR
//
//  Created by maRk'sTheme on 2019/7/6.
//  Copyright © 2019 maRk. All rights reserved.
//

import Foundation

class ImageUtil {
    class func scaleImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
