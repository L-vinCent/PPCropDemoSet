//
//  PPFixCropView.h
//  amezMall_New
//
//  Created by Liao PanPan on 2018/3/29.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPFixCropView : UIView

- (instancetype)initWithImage:(UIImage *)image;


@property (nonatomic, assign, readwrite) CGRect croppedImageFrame;


@end
