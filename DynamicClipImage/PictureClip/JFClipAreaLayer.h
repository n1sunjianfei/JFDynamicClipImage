//
//  YasicClipAreaLayer.h
//  DynamicClipImage
//
//  Created by yasic on 2017/11/29.
//  Copyright © 2017年 yasic. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface JFClipAreaLayer : CAShapeLayer

@property(assign, nonatomic) NSInteger cropAreaLeft;
@property(assign, nonatomic) NSInteger cropAreaTop;
@property(assign, nonatomic) NSInteger cropAreaRight;
@property(assign, nonatomic) NSInteger cropAreaBottom;

- (void)setClipAreaLeft:(NSInteger)cropAreaLeft clipAreaTop:(NSInteger)cropAreaTop clipAreaRight:(NSInteger)cropAreaRight clipAreaBottom:(NSInteger)cropAreaBottom;


@end
