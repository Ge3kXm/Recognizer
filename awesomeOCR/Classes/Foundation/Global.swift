//
//  Global.swift
//  awesomeOCR
//
//  Created by maxiao on 2019/7/2.
//  Copyright © 2019 maRk. All rights reserved.
//

import Foundation
import UIKit

protocol Construct {}

extension NSObject: Construct {}

extension Construct where Self: AnyObject {
    @discardableResult
    func construct(_ closure: (Self) throws -> Void) rethrows -> Self {
        try closure(self)
        return self
    }
}

public enum DisplayType {
    case unknown
    case iPhone4
    case iPhone5
    case iPhone6
    case iPhone6plus
    static let iPhone7 = iPhone6
    static let iPhone7plus = iPhone6plus
    case iPhoneX
    static let iPhoneXS = iPhoneX
    case iPhoneXR
    static let iPhoneXSMax = iPhoneXR
}

public final class Display {
    class var width: CGFloat { return UIScreen.main.bounds.size.width }
    class var height: CGFloat { return UIScreen.main.bounds.size.height }
    class var maxLength: CGFloat { return max(width, height) }
    class var minLength: CGFloat { return min(width, height) }
    class var zoomed: Bool { return UIScreen.main.nativeScale >= UIScreen.main.scale }
    class var retina: Bool { return UIScreen.main.scale >= 2.0 }
    class var phone: Bool { return UIDevice.current.userInterfaceIdiom == .phone }
    class var pad: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    class var carplay: Bool { return UIDevice.current.userInterfaceIdiom == .carPlay }
    class var tv: Bool { return UIDevice.current.userInterfaceIdiom == .tv }
    public class var typeIsLike: DisplayType {
        if phone == false { return .unknown }

        let screenHeight = maxLength
        if screenHeight < 568 {
            return .iPhone4
        } else if screenHeight == 568 {
            return .iPhone5
        } else if screenHeight == 667 {
            return .iPhone6
        } else if screenHeight == 736 {
            return .iPhone6plus
        } else if screenHeight == 812 {
            return .iPhoneX
        } else if screenHeight == 896 {
            return .iPhoneXR
        }
        return .unknown
    }

    public class func takeSnapShot(_ currentView: UIView, addViews: [UIView] = [], hideViews: [UIView] = []) -> UIImage {
        for hideView in hideViews {
            hideView.isHidden = true
        }
        UIGraphicsBeginImageContextWithOptions(currentView.frame.size, false, 0.0)
        currentView.drawHierarchy(in: currentView.bounds, afterScreenUpdates: true)
        for addView in addViews {
            addView.drawHierarchy(in: addView.frame, afterScreenUpdates: true)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        for hideView in hideViews {
            hideView.isHidden = false
        }
        return image!
    }

    public class func realTabbarHeight() -> CGFloat {
        if isXSeries() {
            return 83 - (49 - 44)
        }
        return 44
    }

    public class func realTopBarHeight() -> CGFloat {
        return realNavBarHeight() + realStatusBarHeight()
    }

    public class func realNavBarHeight() -> CGFloat {
        return 44
    }

    public class func realStatusBarHeight() -> CGFloat {
        if isXSeries() {
            return 44
        }
        return 20
    }

    static let topSafeAreaHeight: CGFloat = isXSeries() ? 44.0 : 20.0
    static let bottomSafeAreaHeight: CGFloat = isXSeries() ? 34.0 : 0.0

    class func isXSeries() -> Bool { // 是否是 X 系列
        return (
            Display.typeIsLike == .iPhoneX ||
                Display.typeIsLike == .iPhoneXR ||
                Display.typeIsLike == .iPhoneXS ||
                Display.typeIsLike == .iPhoneXSMax
        )
    }
}

public extension Double {
    var fitScreen: Double {
        return self/375.0 * Double(UIScreen.main.bounds.size.width)
    }
}

// https://bytedance.feishu.cn/space/sheet/shtcnFzwHy92neLshUmjns#BcM8BI
public final class FontDisplay {
    /// 大标题1
    static var title1: Double       = 38
    /// 大标题2
    static var title2: Double       = 28
    /// H1标题
    static var titleH1: Double      = 38
    /// H2标题
    static var titleH2: Double      = 38
    /// H3标题
    static var titleH3: Double      = 38
    /// 导航栏标题
    static var titleBar: Double     = 38
    /// 按钮文字
    static var btnFont: Double      = 38
    /// 正常内文1
    static var txt1: Double         = 38
    /// 正常内文2
    static var txt2: Double         = 38
    /// 内文辅助
    static var txtHelper: Double    = 38
    /// 标签/时间
    static var txtLabel: Double     = 38
    /// 分割线
    static var lenDivider: Double   = 38
}

extension UIImage {
    func fixOrientation() -> UIImage {
        let ot: UIImage.Orientation = self.imageOrientation
        guard ot != .up else { return self }
        var transform: CGAffineTransform = CGAffineTransform.identity
        // 处理方向
        switch ot {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -CGFloat.pi / 2)
        default:
            break
        }
        // 处理镜像
        switch ot {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        // 画图
        guard let cgImage = cgImage,
            let colorSpace = cgImage.colorSpace,
            let ctx = CGContext.init(data: nil, width: Int(size.width), height: Int(size.height),
                                     bitsPerComponent: cgImage.bitsPerComponent,
                                     bytesPerRow: 0,
                                     space: colorSpace,
                                     bitmapInfo: cgImage.bitmapInfo.rawValue) else { return self }
        ctx.concatenate(transform)
        switch ot {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        // Get Result
        guard let resCGImage = ctx.makeImage() else { return self }
        let resImage: UIImage = UIImage(cgImage: resCGImage)
        return resImage
    }

    public func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

