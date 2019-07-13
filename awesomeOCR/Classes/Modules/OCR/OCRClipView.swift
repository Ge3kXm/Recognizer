//
//  OCRClipView.swift
//  OCRClipView
//
//  Created by maxiao on 2019/6/10.
//

/**
 ^  对应点坐标示意图
 |
 |  0   4   1
 |  7       5
 |  3   6   2
 |
 ------------------->
 */

import Foundation
import UIKit

class OCRClipView: UIView {

    private let buttonSize : CGFloat = 50 //默认20，为了扩大响应区域便于拖拽

    private var leftTop    : UIView!
    private var leftBottom : UIView!
    private var rightTop   : UIView!
    private var rightBottom: UIView!
    private var topMid     : UIView!
    private var rightMid   : UIView!
    private var bottomMid  : UIView!
    private var leftMid    : UIView!
    private var realLine = CAShapeLayer()
    private var isChanged = true

    private var points     : [CGPoint]!
    private var lastInRangePoints : [CGPoint]!

    var cornerPoints: [CGPoint]? {
        guard points.count == 8 else {
            return nil
        }
        return [points[0], points[1], points[2], points[3]]
    }

    init(imgFrame: CGRect, points: [CGPoint]?) {
        super.init(frame: imgFrame)

        if let pts = points, pts.count == 4, !checkHaveSamePoint(pts: pts) {
            self.points = caculatePoints(pts)
        } else {
            self.points = defaultPoints()
        }

        self.lastInRangePoints = self.points
        self.isUserInteractionEnabled = true
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func caculatePoints(_ points: [CGPoint]) -> [CGPoint] {
        return [points[0],
                points[1],
                points[2],
                points[3],
                caculateMidPoint(points[0], theOtherPoint: points[1]),
                caculateMidPoint(points[1], theOtherPoint: points[2]),
                caculateMidPoint(points[2], theOtherPoint: points[3]),
                caculateMidPoint(points[3], theOtherPoint: points[0])]
    }

    private func defaultPoints() -> [CGPoint] {
        return [CGPoint(x: 0, y: 0),
                CGPoint(x: bounds.size.width, y: 0),
                CGPoint(x: bounds.size.width, y: bounds.size.height),
                CGPoint(x: 0, y: bounds.size.height),
                CGPoint(x: bounds.size.width / 2, y: 0),
                CGPoint(x: bounds.size.width, y: bounds.size.height / 2),
                CGPoint(x: bounds.size.width / 2, y: bounds.size.height),
                CGPoint(x: 0, y: bounds.size.height / 2)]
    }

    private func setupUI() {
        backgroundColor = .clear

        guard points.count == 8 else {
            assertionFailure("坐标点数量不对！")
            return
        }
        leftTop = makeView(CGRect(x: points[0].x, y: points[0].y, width: buttonSize, height: buttonSize))
        rightTop = makeView(CGRect(x: points[1].x, y: points[1].y, width: buttonSize, height: buttonSize))
        rightBottom = makeView(CGRect(x: points[2].x, y: points[2].y, width: buttonSize, height: buttonSize))
        leftBottom = makeView(CGRect(x: points[3].x, y: points[3].y, width: buttonSize, height: buttonSize))
        topMid = makeView(CGRect(x: points[4].x, y: points[4].y, width: buttonSize, height: buttonSize))
        rightMid = makeView(CGRect(x: points[5].x, y: points[5].y, width: buttonSize, height: buttonSize))
        bottomMid = makeView(CGRect(x: points[6].x, y: points[6].y, width: buttonSize, height: buttonSize))
        leftMid = makeView(CGRect(x: points[7].x, y: points[7].y, width: buttonSize, height: buttonSize))

        addSubview(leftTop)
        addSubview(leftBottom)
        addSubview(rightTop)
        addSubview(rightBottom)
        addSubview(topMid)
        addSubview(rightMid)
        addSubview(bottomMid)
        addSubview(leftMid)
        makeLine()
    }

    private func makeLine() {
        realLine.removeFromSuperlayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: leftTop.center.x, y: leftTop.center.y))
        path.addLine(to: CGPoint(x: leftBottom.center.x, y: leftBottom.center.y))
        path.addLine(to: CGPoint(x: rightBottom.center.x, y: rightBottom.center.y))
        path.addLine(to: CGPoint(x: rightTop.center.x, y: rightTop.center.y))
        path.addLine(to: CGPoint(x: leftTop.center.x, y: leftTop.center.y))
        realLine.path = path.cgPath
        realLine.lineWidth = 2.0
        realLine.strokeColor = UIColor.white.cgColor
        realLine.fillColor = UIColor.clear.cgColor
        layer.addSublayer(realLine)

        //让圆点盖住线
        bringSubviewToFront(leftTop)
        bringSubviewToFront(leftBottom)
        bringSubviewToFront(rightTop)
        bringSubviewToFront(rightBottom)
        bringSubviewToFront(rightMid)
        bringSubviewToFront(leftMid)
        bringSubviewToFront(bottomMid)
        bringSubviewToFront(topMid)
    }

    private func makeView(_ frame: CGRect) -> UIView {
        let view = UIImageView(image: UIImage(named: "ocr_dot"))
        view.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        view.center = frame.origin
        view.contentMode = .center
        view.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self,
                                         action: #selector(panGestureSelector(pan:)))
        view.addGestureRecognizer(pan)
        return view
    }

    @objc private func panGestureSelector(pan: UIPanGestureRecognizer) {
        if pan.view == leftTop {
            handlePan(with: pan, view: leftTop, index: 0)
        }
        if pan.view == rightTop {
            handlePan(with: pan, view: rightTop, index: 1)
        }
        if pan.view == rightBottom {
            handlePan(with: pan, view: rightBottom, index: 2)
        }
        if pan.view == leftBottom {
            handlePan(with: pan, view: leftBottom, index: 3)
        }
        if pan.view == topMid {
            handlePan(with: pan, view: topMid, index: 4)
        }
        if pan.view == rightMid {
            handlePan(with: pan, view: rightMid, index: 5)
        }
        if pan.view == bottomMid {
            handlePan(with: pan, view: bottomMid, index: 6)
        }
        if pan.view == leftMid {
            handlePan(with: pan, view: leftMid, index: 7)
        }
    }

    private func handlePan(with pan: UIPanGestureRecognizer, view: UIView, index: Int) {
        var pts: [CGPoint] = self.points
        let pt = pan.translation(in: self)
        var newPoint = pts[index]

        if index == 5 || index == 7 { //左右动
            newPoint.x += pt.x
        } else if index == 4 || index == 6 { //上下动
            newPoint.y += pt.y
        } else { //上下左右动
            newPoint.x += pt.x
            newPoint.y += pt.y
        }

        //防止超出边界
        if newPoint.x < 0 { newPoint.x = 0 }
        if newPoint.y < 0 { newPoint.y = 0 }
        if newPoint.x > frame.size.width { newPoint.x = frame.size.width }
        if newPoint.y > frame.size.height { newPoint.y = frame.size.height }

        if index == 0 { //左上顶点
            let topRight = pts[1]
            let bottomLeft = pts[3]
            pts[4] = caculateMidPoint(topRight, theOtherPoint: newPoint)
            pts[7] = caculateMidPoint(bottomLeft, theOtherPoint: newPoint)
            topMid.center = pts[4]
            leftMid.center = pts[7]
        } else if index == 1 {//右上顶点
            let topLeft = pts[0]
            let bottomRight = pts[2]
            pts[4] = caculateMidPoint(topLeft, theOtherPoint: newPoint)
            pts[5] = caculateMidPoint(bottomRight, theOtherPoint: newPoint)
            topMid.center = pts[4]
            rightMid.center = pts[5]
        } else if index == 2 {//右下顶点
            let topRight = pts[1]
            let bottomLeft = pts[3]
            pts[5] = caculateMidPoint(topRight, theOtherPoint: newPoint)
            pts[6] = caculateMidPoint(bottomLeft, theOtherPoint: newPoint)
            rightMid.center = pts[5]
            bottomMid.center = pts[6]
        } else if index == 3 {//左下顶点
            let topLeft = pts[0]
            let bottomRight = pts[2]
            pts[7] = caculateMidPoint(topLeft, theOtherPoint: newPoint)
            pts[6] = caculateMidPoint(bottomRight, theOtherPoint: newPoint)
            leftMid.center = pts[7]
            bottomMid.center = pts[6]
        } else if index == 4 {//上中
            pts[0].y += pt.y
            pts[1].y += pt.y
            if checkOutOfRange(pts: pts[0], pts[1]) {
                if pan.state == .ended || pan.state == .cancelled {
                    self.points = lastInRangePoints
                }
                return
            }
            pts[5].y += pt.y/2
            pts[7].y += pt.y/2
            leftTop.center = pts[0]
            rightTop.center = pts[1]
            leftMid.center = pts[7]
            rightMid.center = pts[5]
        } else if index == 5 {//右中
            pts[1].x += pt.x
            pts[2].x += pt.x
            if checkOutOfRange(pts: pts[1], pts[2]) {
                if pan.state == .ended || pan.state == .cancelled {
                    self.points = lastInRangePoints
                }
                return
            }
            pts[4].x += pt.x/2
            pts[6].x += pt.x/2
            rightTop.center = pts[1]
            rightBottom.center = pts[2]
            topMid.center = pts[4]
            bottomMid.center = pts[6]
        } else if index == 6 {//下中
            pts[3].y += pt.y
            pts[2].y += pt.y
            if checkOutOfRange(pts: pts[3], pts[2]) {
                if pan.state == .ended || pan.state == .cancelled {
                    self.points = lastInRangePoints
                }
                return
            }
            pts[5].y += pt.y/2
            pts[7].y += pt.y/2
            leftBottom.center = pts[3]
            rightBottom.center = pts[2]
            leftMid.center = pts[7]
            rightMid.center = pts[5]
        } else if index == 7 {//左中
            pts[0].x += pt.x
            pts[3].x += pt.x
            if checkOutOfRange(pts: pts[0], pts[3]) {
                if pan.state == .ended || pan.state == .cancelled {
                    self.points = lastInRangePoints
                }
                return
            }
            pts[4].x += pt.x/2
            pts[6].x += pt.x/2
            leftTop.center = pts[0]
            leftBottom.center = pts[3]
            topMid.center = pts[4]
            bottomMid.center = pts[6]
        }

        view.center = newPoint

        //记录最后一个边界
        lastInRangePoints = pts
        lastInRangePoints[index] = newPoint

        if pan.state == .ended || pan.state == .cancelled {
            pts[index] = newPoint
            self.points = pts
        }

        makeLine()
    }

    //检测是否含有相同的点，opencv有时候会让点重复，重复的时候默认全屏
    private func checkHaveSamePoint(pts: [CGPoint]) -> Bool {
        var map : [Int: CGPoint] = [:]
        for i in 0..<pts.count {
            if !map.values.contains(pts[i]) {
                map[i] = pts[i]
            }
        }
        if map.values.count != 4 {
            return true
        }
        return false
    }

    //检查是否超出边界
    private func checkOutOfRange(pts: CGPoint...) -> Bool {
        for pt in pts {
            if pt.x < 0 ||
                pt.x > frame.size.width ||
                pt.y < 0 ||
                pt.y > frame.size.height {
                return true
            }
        }
        return false
    }

    //根据两个点，计算出中点坐标
    private func caculateMidPoint(_ onePoint: CGPoint, theOtherPoint: CGPoint) -> CGPoint {

        let shorterX = onePoint.x > theOtherPoint.x ? theOtherPoint.x : onePoint.x
        let shorterY = onePoint.y > theOtherPoint.y ? theOtherPoint.y : onePoint.y

        return CGPoint(x: CGFloat(fabsf(Float(onePoint.x - theOtherPoint.x)) / 2) + shorterX,
                       y: CGFloat(fabsf(Float(onePoint.y - theOtherPoint.y)) / 2) + shorterY)

    }
}
