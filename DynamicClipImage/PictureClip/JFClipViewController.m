//
//  YasicClipPage.m
//  DynamicClipImage
//
//  Created by yasic on 2017/11/29.
//  Copyright © 2017年 yasic. All rights reserved.
//

#import "JFClipViewController.h"
#import "JFClipAreaLayer.h"
#import "JFPanGestureRecognizer.h"
#define HexColor(hexValue,alphaValue) [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 green:((float)((hexValue & 0xFF00) >> 8))/255.0 blue:((float)(hexValue & 0xFF))/255.0 alpha:alphaValue]

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

//模态边框颜色
#define kClipPic_MaskColor HexColor(0x292421,1.0)
//self.view 背景颜色
#define kClipPic_BackgroundColor HexColor(0x292421,1.0)
//工具栏 背景颜色
#define kToolBarColor HexColor(0xF5F5F5, 1.0)

CGFloat const kToolBarHeight = 44;
CGFloat const kMinWidth = 100;//
CGFloat const kClipMargin = 30;

typedef NS_ENUM(NSInteger, GestureLocationType) {
    ClipView_CENTER,
    ClipView_LEFT,
    ClipView_RIGHT,
    ClipView_TOP,
    ClipView_BOTTOM,
    
};

@interface JFClipViewController ()

@property(strong, nonatomic) UIImageView *bigImageView;
@property(strong, nonatomic) UIView *clipView;
@property(strong, nonatomic) UIToolbar *toolBar;

@property(assign, nonatomic) GestureLocationType gestureType;

// 图片 view 原始 frame
@property(assign, nonatomic) CGRect originalFrame;

// 裁剪区域属性
@property(assign, nonatomic) CGFloat clipAreaX;
@property(assign, nonatomic) CGFloat clipAreaY;
@property(assign, nonatomic) CGFloat clipAreaWidth;
@property(assign, nonatomic) CGFloat clipAreaHeight;

@property(nonatomic, assign) CGFloat clipHeight;
@property(nonatomic, assign) CGFloat clipWidth;
@property(nonatomic, assign) CGFloat heightWidthRatio;
@property(nonatomic, assign) CGFloat navbarHeight;

@end

@implementation JFClipViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.navigationController) {
        self.navigationController.navigationBar.translucent = NO;
        [self.navigationController setNavigationBarHidden:YES];
        self.navigationController.delegate = self;
    }
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.view.backgroundColor = kClipPic_BackgroundColor;
    self.view.clipsToBounds = YES;
    self.heightWidthRatio = 16.0/16;
    [self initDefaultData];
    [self setupBaseView];
    [self addAllGesture];
    [self setUpclipLayer];

}
//默认的值是黑色的
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
//禁止当前控制器旋转
- (BOOL)shouldAutorotate{
    
    return NO;
}

//禁止导航控制器旋转
- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //点击返回旋转到竖屏
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

}

#pragma mark - lazyLoading
- (UIImageView *)bigImageView{
    if (!_bigImageView) {
        _bigImageView = [[UIImageView alloc] init];
        _bigImageView.backgroundColor = kClipPic_BackgroundColor;
        _bigImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _bigImageView;
}

- (UIView *)clipView{
    if (!_clipView) {
        _clipView = [[UIView alloc] init];
        
        CGFloat height = CGRectGetHeight(self.view.bounds) - self.navbarHeight - kToolBarHeight;
        CGRect frame = CGRectMake(0, self.navbarHeight, SCREEN_WIDTH, height);
        _clipView.frame = frame;
        _clipView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    }
    return _clipView;
}
- (UIToolbar *)toolBar{
    if (!_toolBar) {
        //创建工具条
        _toolBar = [[UIToolbar alloc]init];
        //设置工具条的颜色
        _toolBar.barTintColor = kToolBarColor;
        //设置工具条的frame
        _toolBar.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds)-kToolBarHeight, self.view.frame.size.width, kToolBarHeight);
        //给工具条添加按钮
        UIBarButtonItem *item0 = [[UIBarButtonItem alloc]initWithTitle:@"16:9" style:UIBarButtonItemStylePlain target:self action:@selector(finishedCut:) ];
        item0.tag = 1;

        UIBarButtonItem *item1 = [[UIBarButtonItem alloc]initWithTitle:@"9:16" style:UIBarButtonItemStylePlain target:self action:@selector(finishedCut:)];
        item1.tag = 2;
//
        UIBarButtonItem *item2 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *item3 = [[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(finishedCut:)];
        item3.tag = 3;
        _toolBar.items = @[item0,item1,item2, item3];
        //设置文本输入框键盘的辅助视图
//        _textfield.inputAccessoryView = toolbar;
        
    }
    return _toolBar;
}
#pragma mark - Base UI

- (void)initDefaultData{
    self.navbarHeight = 0;
    if (self.navigationController) {
      self.navbarHeight = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    }
    
    self.clipWidth = ((SCREEN_WIDTH - 2*kClipMargin)  *self.heightWidthRatio >SCREEN_HEIGHT - kToolBarHeight - kClipMargin*2)?(SCREEN_HEIGHT -kToolBarHeight - kClipMargin*2)/self.heightWidthRatio:(SCREEN_WIDTH - 2*kClipMargin);
    self.clipHeight = self.clipWidth * self.heightWidthRatio;
    
    self.clipAreaX = (SCREEN_WIDTH - self.clipWidth)/2;
    self.clipAreaY = (SCREEN_HEIGHT - self.clipHeight - self.navbarHeight - kToolBarHeight)/2;
    self.clipAreaWidth = self.clipWidth;
    self.clipAreaHeight = self.clipHeight;
    
    self.bigImageView.image = self.targetImage;
    
}
- (void)setupBaseView{
    
    [self.view addSubview:self.clipView];
    [self.view addSubview:self.bigImageView];
    [self.view addSubview:self.toolBar];
    

    CGFloat centerY = (SCREEN_HEIGHT - self.navbarHeight - kToolBarHeight)/2;
    CGFloat tempWidth = 0.0;
    CGFloat tempHeight = 0.0;

    //根据宽高比调整bigImageView的frame的宽高
    if (self.targetImage.size.width/self.clipAreaWidth <= self.targetImage.size.height/self.clipAreaHeight) {
        tempWidth = self.clipAreaWidth;
        tempHeight = (tempWidth/self.targetImage.size.width) * self.targetImage.size.height;
    } else if (self.targetImage.size.width/self.clipAreaWidth > self.targetImage.size.height/self.clipAreaHeight) {
        tempHeight = self.clipAreaHeight;
        tempWidth = (tempHeight/self.targetImage.size.height) * self.targetImage.size.width;
    }
    self.bigImageView.frame = CGRectMake(self.clipAreaX - (tempWidth - self.clipAreaWidth)/2,centerY - tempHeight/2 + self.navbarHeight, tempWidth, tempHeight);
    self.originalFrame = CGRectMake(self.clipAreaX - (tempWidth - self.clipAreaWidth)/2,centerY - tempHeight/2 + self.navbarHeight, tempWidth, tempHeight);

}

#pragma mark - Gesture
-(void)addAllGesture{
    // 捏合手势
    UIPinchGestureRecognizer *pinGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPinGesture:)];
    [self.view addGestureRecognizer:pinGesture];
    
    // 拖动手势
    JFPanGestureRecognizer *panGesture = [[JFPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDynamicPanGesture:) inview:self.clipView];
    [self.clipView addGestureRecognizer:panGesture];
}

-(void)handleDynamicPanGesture:(JFPanGestureRecognizer *)panGesture{
    UIView * view = self.bigImageView;
    CGPoint translation = [panGesture translationInView:view.superview];
    
    CGPoint beginPoint = panGesture.beginPoint;
    CGPoint movePoint = panGesture.movePoint;
    CGFloat judgeWidth = 20;
    if (self.canAdjustMask) {//可以调整Mask边框的时候才执行下面代码
        // 开始滑动时判断滑动对象是 ImageView 还是 Layer 上的 Line
        if (panGesture.state == UIGestureRecognizerStateBegan) {
            
            if (beginPoint.x >= self.clipAreaX - judgeWidth && beginPoint.x <= self.clipAreaX + judgeWidth && beginPoint.y >= self.clipAreaY && beginPoint.y <= self.clipAreaY + self.clipAreaHeight && self.clipAreaWidth >= kMinWidth) {
                self.gestureType = ClipView_LEFT;
            } else if (beginPoint.x >= self.clipAreaX + self.clipAreaWidth - judgeWidth && beginPoint.x <= self.clipAreaX + self.clipAreaWidth + judgeWidth && beginPoint.y >= self.clipAreaY && beginPoint.y <= self.clipAreaY + self.clipAreaHeight &&  self.clipAreaWidth >= kMinWidth) {
                self.gestureType = ClipView_RIGHT;
            } else if (beginPoint.y >= self.clipAreaY - judgeWidth && beginPoint.y <= self.clipAreaY + judgeWidth && beginPoint.x >= self.clipAreaX && beginPoint.x <= self.clipAreaX + self.clipAreaWidth && self.clipAreaHeight >= kMinWidth) {
                self.gestureType = ClipView_TOP;
            } else if (beginPoint.y >= self.clipAreaY + self.clipAreaHeight - judgeWidth && beginPoint.y <= self.clipAreaY + self.clipAreaHeight + judgeWidth && beginPoint.x >= self.clipAreaX && beginPoint.x <= self.clipAreaX + self.clipAreaWidth && self.clipAreaHeight >= kMinWidth) {
                self.gestureType = ClipView_BOTTOM;
            } else {
                self.gestureType = ClipView_CENTER;
                [view setCenter:CGPointMake(view.center.x + translation.x, view.center.y + translation.y)];
                [panGesture setTranslation:CGPointZero inView:view.superview];
            }
        }
    }

    // 滑动过程中进行位置改变
    if (panGesture.state == UIGestureRecognizerStateChanged) {
        CGFloat diff = 0;
        
        
        switch (self.gestureType) {
            case ClipView_LEFT: {
                diff = movePoint.x - self.clipAreaX;
                if (diff >= 0 && self.clipAreaWidth > kMinWidth) {
                    self.clipAreaWidth -= diff;
                    self.clipAreaX += diff;
                } else if (diff < 0 && self.clipAreaX > self.bigImageView.frame.origin.x && self.clipAreaX >= 0) {
                    self.clipAreaWidth -= diff;
                    self.clipAreaX += diff;
                }
                [self setUpclipLayer];
                break;
            }
            case ClipView_RIGHT: {
                diff = movePoint.x - self.clipAreaX - self.clipAreaWidth;
                if (diff >= 0 && (self.clipAreaX + self.clipAreaWidth) < MIN(self.bigImageView.frame.origin.x + self.bigImageView.frame.size.width, self.clipView.frame.origin.x + self.clipView.frame.size.width - kClipMargin)){
                    self.clipAreaWidth += diff;
                } else if (diff < 0 && self.clipAreaWidth >= kMinWidth) {
                    self.clipAreaWidth += diff;
                }
                [self setUpclipLayer];
                break;
            }
            case ClipView_TOP: {
                diff = movePoint.y - self.clipAreaY;
                if (diff >= 0 && self.clipAreaHeight > kMinWidth) {
                    self.clipAreaHeight -= diff;
                    self.clipAreaY += diff;
                } else if (diff < 0 && self.clipAreaY > self.bigImageView.frame.origin.y && self.clipAreaY >= kClipMargin) {
                    self.clipAreaHeight -= diff;
                    self.clipAreaY += diff;
                }
                [self setUpclipLayer];
                break;
            }
            case ClipView_BOTTOM: {
                diff = movePoint.y - self.clipAreaY - self.clipAreaHeight;
                if (diff >= 0 && (self.clipAreaY + self.clipAreaHeight) < MIN(self.bigImageView.frame.origin.y + self.bigImageView.frame.size.height, self.clipView.frame.origin.y + self.clipView.frame.size.height - kClipMargin)){
                    self.clipAreaHeight += diff;
                } else if (diff < 0 && self.clipAreaHeight >= kMinWidth) {
                    self.clipAreaHeight += diff;
                }
                [self setUpclipLayer];
                break;
            }
            case ClipView_CENTER: {
                [view setCenter:CGPointMake(view.center.x + translation.x, view.center.y + translation.y)];
                [panGesture setTranslation:CGPointZero inView:view.superview];
                break;
            }
            default:
                break;
        }
    }
    
    // 滑动结束后进行位置修正
    if (panGesture.state == UIGestureRecognizerStateEnded) {
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        switch (self.gestureType) {
            case ClipView_LEFT: {
                if (self.clipAreaWidth < kMinWidth) {
                    self.clipAreaX -= kMinWidth - self.clipAreaWidth;
                    self.clipAreaWidth = kMinWidth;
                }
                if (self.clipAreaX < MAX(self.bigImageView.frame.origin.x, kClipMargin)) {
                    CGFloat temp = self.clipAreaX + self.clipAreaWidth;
                    self.clipAreaX = MAX(self.bigImageView.frame.origin.x, kClipMargin);
                    self.clipAreaWidth = temp - self.clipAreaX;
                }
                [self setUpclipLayer];
                break;
            }
            case ClipView_RIGHT: {
                if (self.clipAreaWidth < kMinWidth) {
                    self.clipAreaWidth = kMinWidth;
                }
                if (self.clipAreaX + self.clipAreaWidth > MIN(self.bigImageView.frame.origin.x + self.bigImageView.frame.size.width, self.clipView.frame.origin.x + self.clipView.frame.size.width - kClipMargin)) {
                    self.clipAreaWidth = MIN(self.bigImageView.frame.origin.x + self.bigImageView.frame.size.width, self.clipView.frame.origin.x + self.clipView.frame.size.width - kClipMargin) - self.clipAreaX;
                }
                [self setUpclipLayer];
                break;
            }
            case ClipView_TOP: {
                if (self.clipAreaHeight < kMinWidth) {
                    self.clipAreaY -= kMinWidth - self.clipAreaHeight;
                    self.clipAreaHeight = kMinWidth;
                }
                if (self.clipAreaY < MAX(self.bigImageView.frame.origin.y+statusBarHeight, kClipMargin)) {
                    CGFloat temp = self.clipAreaY + self.clipAreaHeight;
                    self.clipAreaY = MAX(self.bigImageView.frame.origin.y, kClipMargin);
                    self.clipAreaHeight = temp - self.clipAreaY;
                }
                if (self.clipAreaY < 20) {
                    self.clipAreaY = 20;
                    self.clipAreaHeight -= self.clipAreaY;
                }
                [self setUpclipLayer];
                break;
            }
            case ClipView_BOTTOM: {
                if (self.clipAreaHeight < kMinWidth) {
                    self.clipAreaHeight = kMinWidth;
                }
                if (self.clipAreaY + self.clipAreaHeight > MIN(self.bigImageView.frame.origin.y + self.bigImageView.frame.size.height, self.clipView.frame.origin.y + self.clipView.frame.size.height - kClipMargin)) {
                    self.clipAreaHeight = MIN(self.bigImageView.frame.origin.y + self.bigImageView.frame.size.height, self.clipView.frame.origin.y + self.clipView.frame.size.height - kClipMargin) - self.clipAreaY;
                }
                [self setUpclipLayer];
                break;
            }
                
                //self.bigImageView.frame = CGRectMake(self.clipAreaX - (tempWidth - self.clipAreaWidth)/2,centerY - tempHeight/2 + self.navbarHeight, tempWidth, tempHeight);
            case ClipView_CENTER: {
                CGRect currentFrame = view.frame;
//                CGFloat topHeight = (SCREEN_HEIGHT - self.navbarHeight - kToolBarHeight - self.clipAreaHeight)/2;

                if (currentFrame.origin.x >= self.clipAreaX) {
                    currentFrame.origin.x = self.clipAreaX;

                }
                if (currentFrame.origin.y - self.navbarHeight >= self.clipAreaY) {
                    currentFrame.origin.y = self.clipAreaY + self.navbarHeight;
                }
                if (currentFrame.size.width + currentFrame.origin.x < self.clipAreaX + self.clipAreaWidth) {
                    CGFloat movedLeftX = fabs(currentFrame.size.width + currentFrame.origin.x - (self.clipAreaX + self.clipAreaWidth));
                    currentFrame.origin.x += movedLeftX;
                }
                if (currentFrame.size.height + currentFrame.origin.y - self.navbarHeight < self.clipAreaY + self.clipAreaHeight) {
                    CGFloat moveUpY = fabs(currentFrame.size.height + currentFrame.origin.y - (self.clipAreaY + self.clipAreaHeight) - self.navbarHeight);
                    currentFrame.origin.y += moveUpY;
                }
                [UIView animateWithDuration:0.3 animations:^{

                    [view setFrame:currentFrame];
                }];
                break;
            }
            default:
                break;
        }
    }
}

-(void)handleCenterPinGesture:(UIPinchGestureRecognizer *)pinGesture
{
    CGFloat scaleRation = 3;
    UIView * view = self.bigImageView;
    
    // 缩放开始与缩放中
    if (pinGesture.state == UIGestureRecognizerStateBegan || pinGesture.state == UIGestureRecognizerStateChanged) {
        // 移动缩放中心到手指中心
        CGPoint pinchCenter = [pinGesture locationInView:view.superview];
        CGFloat distanceX = view.frame.origin.x - pinchCenter.x;
        CGFloat distanceY = view.frame.origin.y - pinchCenter.y;
        CGFloat scaledDistanceX = distanceX * pinGesture.scale;
        CGFloat scaledDistanceY = distanceY * pinGesture.scale;
        CGRect newFrame = CGRectMake(view.frame.origin.x + scaledDistanceX - distanceX, view.frame.origin.y + scaledDistanceY - distanceY, view.frame.size.width * pinGesture.scale, view.frame.size.height * pinGesture.scale);
        view.frame = newFrame;
        pinGesture.scale = 1;
    }
    
    // 缩放结束
    if (pinGesture.state == UIGestureRecognizerStateEnded) {
        CGFloat ration =  view.frame.size.width / self.originalFrame.size.width;
        
        // 缩放过大
        if (ration > 5) {
            CGRect newFrame = CGRectMake(0, 0, self.originalFrame.size.width * scaleRation, self.originalFrame.size.height * scaleRation);
            view.frame = newFrame;
        }
        
        // 缩放过小
        if (ration < 0.25) {
            view.frame = self.originalFrame;
        }
        // 对图片进行位置修正
        CGRect resetPosition = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
        
        if (resetPosition.origin.x >= self.clipAreaX) {
            resetPosition.origin.x = self.clipAreaX;
        }
        if (resetPosition.origin.y >= self.clipAreaY) {
            resetPosition.origin.y = self.clipAreaY;
        }
        if (resetPosition.size.width + resetPosition.origin.x < self.clipAreaX + self.clipAreaWidth) {
            CGFloat movedLeftX = fabs(resetPosition.size.width + resetPosition.origin.x - (self.clipAreaX + self.clipAreaWidth));
            resetPosition.origin.x += movedLeftX;
        }
        if (resetPosition.size.height + resetPosition.origin.y < self.clipAreaY + self.clipAreaHeight) {
            CGFloat moveUpY = fabs(resetPosition.size.height + resetPosition.origin.y - (self.clipAreaY + self.clipAreaHeight));
            resetPosition.origin.y += moveUpY;
        }
        view.frame = resetPosition;
        
        // 对图片缩放进行比例修正，防止过小
        if (self.clipAreaX < self.bigImageView.frame.origin.x
            || ((self.clipAreaX + self.clipAreaWidth) > self.bigImageView.frame.origin.x + self.bigImageView.frame.size.width)
            || self.clipAreaY < self.bigImageView.frame.origin.y
            || ((self.clipAreaY + self.clipAreaHeight) > self.bigImageView.frame.origin.y + self.bigImageView.frame.size.height)) {
            view.frame = self.originalFrame;
        }
    }
}
#pragma mark - Cut Image
// 裁剪图片并调用返回Block
- (UIImage *)clipImage{
    //
    
    CGFloat imageScale = self.bigImageView.frame.size.width/self.targetImage.size.width;
    CGFloat clipX = (self.clipAreaX - self.bigImageView.frame.origin.x)/imageScale;
    CGFloat clipY = (self.clipAreaY - self.bigImageView.frame.origin.y + self.navbarHeight)/imageScale;
    CGFloat clipWidth = self.clipAreaWidth/imageScale;
    CGFloat clipHeight = self.clipAreaHeight/imageScale;
    CGRect clipRect = CGRectMake(clipX, clipY, clipWidth, clipHeight);
    
    CGImageRef sourceImageRef = [self.targetImage CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, clipRect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    return newImage;
}
#pragma mark - Mask
- (void)setUpclipLayer{
    

    self.clipView.layer.sublayers = nil;
    JFClipAreaLayer * layer = [[JFClipAreaLayer alloc] init];

    CGRect clipframe = CGRectMake(self.clipAreaX, self.clipAreaY, self.clipAreaWidth, self.clipAreaHeight);
    UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:self.clipView.bounds cornerRadius:0];
    UIBezierPath * clipPath = [UIBezierPath bezierPathWithRect:clipframe];
    [path appendPath:clipPath];
    layer.path = path.CGPath;
    
    layer.fillRule = kCAFillRuleEvenOdd;
    layer.fillColor = [kClipPic_MaskColor CGColor];
    layer.opacity = 0.5;
    
    layer.frame = self.clipView.bounds;
    [layer setClipAreaLeft:self.clipAreaX clipAreaTop:self.clipAreaY clipAreaRight:self.clipAreaX + self.clipAreaWidth clipAreaBottom:self.clipAreaY + self.clipAreaHeight];
    [self.clipView.layer addSublayer:layer];
    [self.view bringSubviewToFront:self.clipView];
}

- (void)finishedCut:(UIBarButtonItem*)item{
    switch (item.tag) {
        case 1:
            self.heightWidthRatio = 16.0/9;
            [self initDefaultData];
            [self setupBaseView];
            [self addAllGesture];
            [self setUpclipLayer];
            break;
        case 2:
            self.heightWidthRatio = 9.0/16;
            [self initDefaultData];
            [self setupBaseView];
            [self addAllGesture];
            [self setUpclipLayer];
            break;
        case 3:
            if (self.finishedBlock) {
                self.finishedBlock([self clipImage], nil);
            }
            break;
        default:
            break;
    }
    
}

@end
