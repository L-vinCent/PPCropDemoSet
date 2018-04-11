//
//  PPCropScrollView.h
//  PPCropTest
//
//  Created by Liao PanPan on 2018/4/11.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPCropScrollView : UIScrollView

@property (nonatomic, copy) void (^touchesBegan)(void);
@property (nonatomic, copy) void (^touchesCancelled)(void);
@property (nonatomic, copy) void (^touchesEnded)(void);

@end
