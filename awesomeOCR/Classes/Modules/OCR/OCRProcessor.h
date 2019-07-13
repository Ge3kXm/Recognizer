#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCRProcessor : NSObject

/**
 * 输入图片扫描边框顶点
 * @param image 扫描图片
 * @return 返回顶点数组，以 左上，右上，右下，左下排序
 */
+ (NSArray *)nativeScan:(UIImage *)image;
/**
 * 裁剪图片
 * @param source 待裁剪图片
 * @param points 裁剪区域顶点，顶点坐标以图片大小为准
 * @return 返回裁剪后的图片
 */
+ (UIImage *)cropWithImage:(UIImage *)source area:(NSArray *)points;
@end

NS_ASSUME_NONNULL_END
