//
//  ViewController.m
//  DynamicClipImage
//
//  Created by yasic on 2017/11/29.
//  Copyright © 2017年 yasic. All rights reserved.
//

#import "ViewController.h"
#import "JFClipViewController.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *cuttedImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

}
- (IBAction)push:(UIButton *)sender {
    
    __weak typeof(self) weakself = self;
    JFClipViewController *vc = [[JFClipViewController alloc] init];
    vc.targetImage = [UIImage imageNamed:@"TARGET_IMG_0"];
    vc.canAdjustMask = YES;
    vc.finishedBlock = ^(UIImage *image, NSError *error) {
        weakself.cuttedImageView.image = image;

        [weakself.navigationController popViewControllerAnimated:YES];
    };

    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)present:(UIButton *)sender {
    __weak typeof(self) weakself = self;
    JFClipViewController *vc = [[JFClipViewController alloc] init];
    vc.targetImage = [UIImage imageNamed:@"TARGET_IMG_0"];
    vc.finishedBlock = ^(UIImage *image, NSError *error) {
        
        [weakself dismissViewControllerAnimated:YES completion:^{
            
        }];
        weakself.cuttedImageView.image = image;
    };
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

@end
