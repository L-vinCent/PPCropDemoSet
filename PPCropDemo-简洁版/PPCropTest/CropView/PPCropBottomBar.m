//
//  PPCropBottomBar.m
//  amezMall_New
//
//  Created by Liao PanPan on 2018/3/29.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPCropBottomBar.h"

@interface PPCropBottomBar()

@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIButton *cancelButton;

@end

@implementation PPCropBottomBar


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setup];
    }
    return self;
}
- (void)setup {
    self.backgroundColor = [UIColor colorWithWhite:0.12f alpha:1.0f];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _doneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
    [_doneButton setTitleColor:[UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f] forState:UIControlStateNormal];
    [_doneButton.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [_doneButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_doneButton];
   
    
    _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
//    [_cancelButton setTitleColor:[UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f] forState:UIControlStateNormal];
    [_cancelButton.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [_cancelButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_cancelButton];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGSize boundsSize = self.bounds.size;
    
    _doneButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-44, 0, 44.0f, 44.0f);
    _cancelButton.frame = CGRectMake(0, 0, 44.0f, 44.0f);
    
    
}

- (void)buttonTapped:(id)button
{
    if (button == self.cancelButton ) {
        
        if (self.cancelButtonTapped)  self.cancelButtonTapped();
    }
    
    else {
        
        if (self.doneButtonTapped)  self.doneButtonTapped();
        
    }
    
}
@end
