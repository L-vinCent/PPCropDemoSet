//
//  PPCropMainVC.m
//  amezMall_New
//
//  Created by Liao PanPan on 2018/3/29.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPCropMainVC.h"
#import "PPCropBottomBar.h"
#import "PPFixCropView.h"
#import "UIImage+compressIMG.h"
@interface PPCropMainVC ()

@property(nonatomic,strong)PPFixCropView *fixView;

@property (nonatomic, readwrite,strong) UIImage *image;

@end

@implementation PPCropMainVC

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
      
        _image = image;
        
    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setHidden:YES];
    CGFloat SCREEN_WIDTH = [UIScreen mainScreen].bounds.size.width;
    CGFloat SCREEN_HEIGHT = [UIScreen mainScreen].bounds.size.height;

    self.fixView = [[PPFixCropView alloc]initWithImage:self.image];
    self.fixView.frame  = CGRectMake(0, 0, SCREEN_WIDTH,SCREEN_HEIGHT-44);
    [self.view addSubview:_fixView];
    
    PPCropBottomBar *bar = [[PPCropBottomBar alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-44, [UIScreen mainScreen].bounds.size.width, 44)];
    
    bar.cancelButtonTapped = ^{
        
        
        [self.navigationController popViewControllerAnimated:YES];
        
        
    };
    
    bar.doneButtonTapped = ^{
        
        [self buttonEventClick];
        
    };
    
    [self.view addSubview:bar];
    
    
}

-(void)buttonEventClick
{
    CGRect cropFrame = self.fixView.croppedImageFrame;

    UIImage *image = nil;

    if(CGRectEqualToRect(cropFrame, (CGRect){CGPointZero,self.image.size})){
        image = self.image;
        
    }else
    {
        
        image = [self.image croppedImageWithFrame:cropFrame angle:0];
        
    }
    
    if (self.cropBlock) {
        
        self.cropBlock(image);
        
        [self.navigationController popViewControllerAnimated:YES];

    }
    
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
}

@end
