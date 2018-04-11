//
//  PPCropMainVC.h
//  amezMall_New
//
//  Created by Liao PanPan on 2018/3/29.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^cropImageBlock)(UIImage *image);

@interface PPCropMainVC : UIViewController

- (instancetype)initWithImage:(UIImage *)image;

@property(nonatomic,copy) cropImageBlock cropBlock;

@end
