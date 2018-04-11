//
//  PPCropScrollView.m
//  PPCropTest
//
//  Created by Liao PanPan on 2018/4/11.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPCropScrollView.h"

@implementation PPCropScrollView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touchesBegan)
        self.touchesBegan();
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touchesEnded)
        self.touchesEnded();
    
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touchesCancelled)
        self.touchesCancelled();
    
    [super touchesCancelled:touches withEvent:event];
}



@end
