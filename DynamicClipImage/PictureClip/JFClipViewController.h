//
//  YasicClipPage.h
//  DynamicClipImage
//
//  Created by yasic on 2017/11/29.
//  Copyright © 2017年 yasic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JFClipViewController : UIViewController<UINavigationControllerDelegate>
@property (strong, nonatomic) UIImage *targetImage;

@property(copy, nonatomic) void (^finishedBlock)(UIImage *image,NSError *error);
@property(assign,nonatomic) BOOL canAdjustMask;//是否可以手势调整裁剪框的宽度
@end
