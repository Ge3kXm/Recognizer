#undef NO
#import "OCRProcessor.h"
#import <opencv2/opencv.hpp>


namespace scanner{

    class Scanner {
    public:
        int resizeThreshold = 500;//图片的宽高阈值，超过阈值缩小图片

        Scanner(cv::Mat& bitmap);
        virtual ~Scanner();
        std::vector<cv::Point> scanPoint();
    private:
        cv::Mat srcBitmap;
        float resizeScale = 1.0f;

        bool isHisEqual = false;

        cv::Mat resizeImage();

        cv::Mat preprocessedImage(cv::Mat &image, int cannyValue, int blurValue);

        cv::Point choosePoint(cv::Point center, std::vector<cv::Point> &points, int type);

        std::vector<cv::Point> selectPoints(std::vector<cv::Point> points);

        std::vector<cv::Point> sortPointClockwise(std::vector<cv::Point> vector);

        long long pointSideLine(cv::Point& lineP1, cv::Point& lineP2, cv::Point& point);
    };

}

using namespace scanner;
using namespace cv;

/**
 * 计算并比较两种轮廓的面积
 */
static bool sortByArea(const std::vector<cv::Point> &v1, const std::vector<cv::Point> &v2) {
    double v1Area = fabs(contourArea(Mat(v1)));
    double v2Area = fabs(contourArea(Mat(v2)));
    return v1Area > v2Area;
}

Scanner::Scanner(cv::Mat& bitmap) {
    srcBitmap = bitmap;
}

Scanner::~Scanner() {
}

/**
 * 识别顶点
 */
std::vector<cv::Point> Scanner::scanPoint() {
    std::vector<cv::Point> result;
    int cannyValue[] = {100, 150, 300};
    int blurValue[] = {3, 7, 11, 15};
    //缩小图片尺寸
    Mat image = resizeImage();
    for (int i = 0; i < 3; i++){
        for (int j = 0; j < 4; j++){
            //预处理图片
            Mat scanImage = preprocessedImage(image, cannyValue[i], blurValue[j]);
            std::vector<std::vector<cv::Point>> contours;
            //提取边框（发现图片的轮廓，参数依次为输入图像、轮廓对应的像素点集合、轮廓拓扑模式、描述轮廓的方法）
            //RETR_EXTERNAL表示只提取最外层的轮廓
            findContours(scanImage, contours, RETR_EXTERNAL, CHAIN_APPROX_NONE);
            //对所有轮廓按面积排序
            std::sort(contours.begin(), contours.end(), sortByArea);
            if (contours.size() > 0) {
                std::vector<cv::Point> contour = contours[0];
                //计算轮廓的周长,第二个参数表示是否为闭合曲线
                double arc = arcLength(contour, true);
                std::vector<cv::Point> outDP;
                //把连续光滑曲线折线化（参数为输入曲线、输出折线、判断点到相对应的线段的距离阈值，超过阈值舍弃，越小越解决曲线、曲线是否闭合）
                approxPolyDP(cv::Mat(contour), outDP, 0.01 * arc, true);
                //筛选去除相近的点
                std::vector<cv::Point> selectedPoints = selectPoints(outDP);
                if (selectedPoints.size() != 4) {
                    //如果筛选出来之后不是四边形
                    continue;
                } else {
                    int widthMin = selectedPoints[0].x;
                    int widthMax = selectedPoints[0].x;
                    int heightMin = selectedPoints[0].y;
                    int heightMax = selectedPoints[0].y;
                    for (int k = 0; k < 4; k++) {
                        if (selectedPoints[k].x < widthMin) {
                            widthMin = selectedPoints[k].x;
                        }
                        if (selectedPoints[k].x > widthMax) {
                            widthMax = selectedPoints[k].x;
                        }
                        if (selectedPoints[k].y < heightMin) {
                            heightMin = selectedPoints[k].y;
                        }
                        if (selectedPoints[k].y > heightMax) {
                            heightMax = selectedPoints[k].y;
                        }
                    }
                    //选择区域外围矩形面积
                    int selectArea = (widthMax - widthMin) * (heightMax - heightMin);
                    int imageArea = scanImage.cols * scanImage.rows;
                    //轮廓外围矩形的面积小于图片的1/8，重新计算
                    if (selectArea < (imageArea / 8)) {
                        result.clear();
                        //筛选出来的区域太小
                        continue;
                    } else {
                        //计算筛选区域的外接矩形坐标
                        result = selectedPoints;
                        if (result.size() != 4) {
                            Point2f p[4];
                            p[0] = Point2f(0, 0);
                            p[1] = Point2f(image.cols, 0);
                            p[2] = Point2f(image.cols, image.rows);
                            p[3] = Point2f(0, image.rows);
                            result.push_back(p[0]);
                            result.push_back(p[1]);
                            result.push_back(p[2]);
                            result.push_back(p[3]);
                        }
                        for (cv::Point &p : result) {
                            p.x *= resizeScale;
                            p.y *= resizeScale;
                        }
                        // 按左上，右上，右下，左下排序
                        return sortPointClockwise(result);
                    }
                }
            }
        }
    }
    //当没选出所需要区域时，如果还没做过直方图均衡化则尝试使用均衡化，但该操作只执行一次，若还无效，则判定为图片不能裁出有效区域，返回整张图
    if (!isHisEqual){
        isHisEqual = true;
        return scanPoint();
    }
    if (result.size() != 4) {
        Point2f p[4];
        p[0] = Point2f(0, 0);
        p[1] = Point2f(image.cols, 0);
        p[2] = Point2f(image.cols, image.rows);
        p[3] = Point2f(0, image.rows);
        result.push_back(p[0]);
        result.push_back(p[1]);
        result.push_back(p[2]);
        result.push_back(p[3]);
    }
    for (cv::Point &p : result) {
        p.x *= resizeScale;
        p.y *= resizeScale;
    }
    // 按左上，右上，右下，左下排序
    return sortPointClockwise(result);
}

/**
 * 缩小图片尺寸
 */
cv::Mat Scanner::resizeImage() {
    int width = srcBitmap.cols;
    int height = srcBitmap.rows;
    int maxSize = width > height? width : height;
    //最大边超过阈值就按比例缩小图片
    if (maxSize > resizeThreshold) {
        //计算缩小比例
        resizeScale = 1.0f * maxSize / resizeThreshold;
        width = static_cast<int>(width / resizeScale);
        height = static_cast<int>(height / resizeScale);
        cv::Size size(width, height);
        cv::Mat resizedBitmap(size, CV_8UC3);
        //缩小图片
        resize(srcBitmap, resizedBitmap, size);
        return resizedBitmap;
    }
    return srcBitmap;
}

cv::Mat Scanner::preprocessedImage(cv::Mat &image, int cannyValue, int blurValue) {
    Mat grayMat;
    //将图片转为灰度图片
    cvtColor(image, grayMat, COLOR_BGR2GRAY);
    if (isHisEqual){
        //直方图均衡化，降噪
        equalizeHist(grayMat, grayMat);
    }
    cv::Mat blurMat;
    //高斯模糊降噪(参数依次为输入图像、输出图像、卷积核大小、X方向的模糊程度)
    GaussianBlur(grayMat, blurMat, cv::Size(blurValue, blurValue), 0);
    cv::Mat cannyMat;
    //Canny边缘检测(参数依次为输入图像，输出图像，高阈值，低阈值)
    Canny(blurMat, cannyMat, 50, cannyValue, 3);
    cv::Mat thresholdMat;
    //此时图片会变成黑底，白色细线描边界
    threshold(cannyMat, thresholdMat, 0, 255, THRESH_OTSU);
    return cannyMat;
}

std::vector<cv::Point> Scanner::selectPoints(std::vector<cv::Point> points) {
    if (points.size() > 4) {
        cv::Point &p = points[0];
        int minX = p.x;
        int maxX = p.x;
        int minY = p.y;
        int maxY = p.y;
        //得到一个矩形去包住所有点
        for (int i = 1; i < points.size(); i++) {
            if (points[i].x < minX) {
                minX = points[i].x;
            }
            if (points[i].x > maxX) {
                maxX = points[i].x;
            }
            if (points[i].y < minY) {
                minY = points[i].y;
            }
            if (points[i].y > maxY) {
                maxY = points[i].y;
            }
        }
        //矩形中心点
        cv::Point center = cv::Point((minX + maxX) / 2, (minY + maxY) / 2);
        //分别得出左上，左下，右上，右下四堆中的结果点
        cv::Point p0 = choosePoint(center, points, 0);
        cv::Point p1 = choosePoint(center, points, 1);
        cv::Point p2 = choosePoint(center, points, 2);
        cv::Point p3 = choosePoint(center, points, 3);
        points.clear();
        //如果得到的点不是０，即是得到的结果点
        if (!(p0.x == 0 && p0.y == 0)){
            points.push_back(p0);
        }
        if (!(p1.x == 0 && p1.y == 0)){
            points.push_back(p1);
        }
        if (!(p2.x == 0 && p2.y == 0)){
            points.push_back(p2);
        }
        if (!(p3.x == 0 && p3.y == 0)){
            points.push_back(p3);
        }
    }
    return points;
}

//type代表左上，左下，右上，右下等方位
cv::Point Scanner::choosePoint(cv::Point center, std::vector<cv::Point> &points, int type) {
    int index = -1;
    int minDis = 0;
    //四个堆都是选择距离中心点较远的点
    if (type == 0) {
        for (int i = 0; i < points.size(); i++) {
            if (points[i].x < center.x && points[i].y < center.y) {
                int dis = static_cast<int>(sqrt(pow((points[i].x - center.x), 2) + pow((points[i].y - center.y), 2)));
                if (dis > minDis){
                    index = i;
                    minDis = dis;
                }
            }
        }
    } else if (type == 1) {
        for (int i = 0; i < points.size(); i++) {
            if (points[i].x < center.x && points[i].y > center.y) {
                int dis = static_cast<int>(sqrt(pow((points[i].x - center.x), 2) + pow((points[i].y - center.y), 2)));
                if (dis > minDis){
                    index = i;
                    minDis = dis;
                }
            }
        }
    } else if (type == 2) {
        for (int i = 0; i < points.size(); i++) {
            if (points[i].x > center.x && points[i].y < center.y) {
                int dis = static_cast<int>(sqrt(pow((points[i].x - center.x), 2) + pow((points[i].y - center.y), 2)));
                if (dis > minDis){
                    index = i;
                    minDis = dis;
                }
            }
        }

    } else if (type == 3) {
        for (int i = 0; i < points.size(); i++) {
            if (points[i].x > center.x && points[i].y > center.y) {
                int dis = static_cast<int>(sqrt(pow((points[i].x - center.x), 2) + pow((points[i].y - center.y), 2)));
                if (dis > minDis){
                    index = i;
                    minDis = dis;
                }
            }
        }
    }

    if (index != -1){
        return cv::Point(points[index].x, points[index].y);
    }
    return cv::Point(0, 0);
}

/**
 * 将顶点按左上，右上，右下，左下排序
 */
std::vector<cv::Point> Scanner::sortPointClockwise(std::vector<cv::Point> points) {
    if (points.size() != 4) {
        return points;
    }

    cv::Point unFoundPoint;
    std::vector<cv::Point> result = {unFoundPoint, unFoundPoint, unFoundPoint, unFoundPoint};

    long minDistance = -1;
    for(cv::Point &point : points) {
        long distance = point.x * point.x + point.y * point.y;
        if(minDistance == -1 || distance < minDistance) {
            result[0] = point;
            minDistance = distance;
        }
    }
    if (result[0] != unFoundPoint) {
        cv::Point &leftTop = result[0];
        points.erase(std::remove(points.begin(), points.end(), leftTop));
        if ((pointSideLine(leftTop, points[0], points[1]) * pointSideLine(leftTop, points[0], points[2])) < 0) {
            result[2] = points[0];
        } else if ((pointSideLine(leftTop, points[1], points[0]) * pointSideLine(leftTop, points[1], points[2])) < 0) {
            result[2] = points[1];
        } else if ((pointSideLine(leftTop, points[2], points[0]) * pointSideLine(leftTop, points[2], points[1])) < 0) {
            result[2] = points[2];
        }
    }
    if (result[0] != unFoundPoint && result[2] != unFoundPoint) {
        cv::Point &leftTop = result[0];
        cv::Point &rightBottom = result[2];
        points.erase(std::remove(points.begin(), points.end(), rightBottom));
        if (pointSideLine(leftTop, rightBottom, points[0]) > 0) {
            result[1] = points[0];
            result[3] = points[1];
        } else {
            result[1] = points[1];
            result[3] = points[0];
        }
    }

    if (result[0] != unFoundPoint && result[1] != unFoundPoint && result[2] != unFoundPoint && result[3] != unFoundPoint) {
        return result;
    }

    return points;
}

long long Scanner::pointSideLine(cv::Point &lineP1, cv::Point &lineP2, cv::Point &point) {
    long x1 = lineP1.x;
    long y1 = lineP1.y;
    long x2 = lineP2.x;
    long y2 = lineP2.y;
    long x = point.x;
    long y = point.y;
    return (x - x1)*(y2 - y1) - (y - y1)*(x2 - x1);
}

UIImage* MatToUIImage(const cv::Mat& image) {

    NSData *data = [NSData dataWithBytes:image.data
                                  length:image.step.p[0] * image.rows];

    CGColorSpaceRef colorSpace;

    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

    // Preserve alpha transparency, if exists
    bool alpha = image.channels() == 4;
    CGBitmapInfo bitmapInfo = (alpha ? kCGImageAlphaLast : kCGImageAlphaNone) | kCGBitmapByteOrderDefault;

    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(image.cols,
                                        image.rows,
                                        8 * image.elemSize1(),
                                        8 * image.elemSize(),
                                        image.step.p[0],
                                        colorSpace,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault
                                        );


    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return finalImage;
}

void UIImageToMat(const UIImage* image,
                  cv::Mat& m, bool alphaExist) {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = CGImageGetWidth(image.CGImage), rows = CGImageGetHeight(image.CGImage);
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome)
    {
        m.create(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
            kCGBitmapByteOrderDefault;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                       image.CGImage);
    CGContextRelease(contextRef);
}

@implementation OCRProcessor

// https://stackoverflow.com/questions/10544887/rotating-a-cgimage
// https://stackoverflow.com/questions/18659436/images-being-rotated-when-converted-from-matrix
+ (UIImage*)rotate:(UIImage*)src imageOrientation:(UIImageOrientation)imageOrientation{
    UIGraphicsBeginImageContext(src.size);
    UIImageOrientation orientation = imageOrientation;
    CGContextRef context=(UIGraphicsGetCurrentContext());

    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, 90/180*M_PI) ;
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, -90/180*M_PI);
    } else if (orientation == UIImageOrientationDown) {
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, 90/180*M_PI);
    }

    [src drawAtPoint:CGPointMake(0, 0)];
    UIImage *img=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
/**
 * 输入图片扫描边框顶点
 * @param image 扫描图片
 * @return 返回顶点数组，以 左上，右上，右下，左下排序
 */
+ (NSArray *)nativeScan:(UIImage *)image {

    cv::Mat srcBitmapMat;
    UIImageToMat([self.class rotate:image imageOrientation:image.imageOrientation], srcBitmapMat, false);
    cv::Mat bgrData(srcBitmapMat.cols, srcBitmapMat.rows, CV_8UC3);
    //把RGBA格式转换为BGR格式
    cvtColor(srcBitmapMat, bgrData, cv::COLOR_RGBA2BGR);
    //识别图片内容的四个顶点
    scanner::Scanner docScanner(bgrData);
    std::vector<cv::Point> scanPoints = docScanner.scanPoint();
    NSMutableArray *points = [NSMutableArray array];
    if (scanPoints.size() == 4) {
        for (int i = 0; i < 4; ++i) {
            CGPoint point = CGPointMake(scanPoints[i].x, scanPoints[i].y);
            NSValue *value = [NSValue valueWithCGPoint:point];
            [points addObject:value];
        }
    }
    return [points copy];
}

/**
 * 裁剪图片
 * @param source 待裁剪图片
 * @param points 裁剪区域顶点，顶点坐标以图片大小为准
 * @return 返回裁剪后的图片
 */
+ (UIImage *)cropWithImage:(UIImage *)source area:(NSArray *)points {
    if (source == nil || points == nil) {
        return nil;
    }
    if (points.count != 4) {
        return nil;
    }
    CGPoint leftTop = [points[0] CGPointValue];
    CGPoint rightTop = [points[1] CGPointValue];
    CGPoint rightBottom = [points[2] CGPointValue];
    CGPoint leftBottom = [points[3] CGPointValue];
    // 转化为 Mat 对象
    UIImage *image = [self.class rotate:source imageOrientation:source.imageOrientation];
    cv::Mat srcBitmapMat;
    UIImageToMat(image, srcBitmapMat, false);
    CGImage *cgImage = image.CGImage;
    CGFloat newWidth = CGImageGetWidth(cgImage);
    CGFloat newHeight = CGImageGetHeight(cgImage);
    // 初始化输出Mat对象
    cv::Mat dstBitmapMat = cv::Mat::zeros(newHeight, newWidth, srcBitmapMat.type());
    
    std::vector<cv::Point2f> srcTriangle;
    std::vector<cv::Point2f> dstTriangle;

    //待裁剪部分的区域顶点
    srcTriangle.push_back(cv::Point2f(leftTop.x, leftTop.y));
    srcTriangle.push_back(cv::Point2f(rightTop.x, rightTop.y));
    srcTriangle.push_back(cv::Point2f(leftBottom.x, leftBottom.y));
    srcTriangle.push_back(cv::Point2f(rightBottom.x, rightBottom.y));

    //输出Mat对象的四个顶点
    dstTriangle.push_back(cv::Point2f(0, 0));
    dstTriangle.push_back(cv::Point2f(newWidth, 0));
    dstTriangle.push_back(cv::Point2f(0, newHeight));
    dstTriangle.push_back(cv::Point2f(newWidth, newHeight));

    //计算透视变换矩阵
    cv::Mat transform = getPerspectiveTransform(srcTriangle, dstTriangle);
    //透视变换（参数为输入图像、输出图像、3*3变换矩阵、目标图像大小）
    warpPerspective(srcBitmapMat, dstBitmapMat, transform, dstBitmapMat.size());
    //将Mat转换为bitmap对象
    return MatToUIImage(dstBitmapMat);
}

@end
