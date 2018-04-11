//
//  PPFixCropView.m
//  amezMall_New
//
//  Created by Liao PanPan on 2018/3/29.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPFixCropView.h"
#import "PPCropLineView.h"


static const CGFloat kTOCropViewPadding = 5.0f;
static const NSTimeInterval kTOCropTimerDuration = 0.8f;
static const CGFloat kTOCropViewMinimumBoxSize = 42.0f;

@interface PPFixCropView()<UIScrollViewDelegate>

@property (nonatomic, strong, readwrite) UIImage *image;

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *backgroundContainerView;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) CAShapeLayer *shaperLayer;


@property (nonatomic, readonly) CGSize imageSize;
@property (nonatomic, readonly) CGRect contentBounds;

@property (nonatomic, assign, readwrite) CGRect cropBoxFrame;

@property (nonatomic, strong) PPCropLineView *gridOverlayView;
@property (nonatomic, strong) UIView *foregroundContainerView;


-(void)setup;




@end


@implementation PPFixCropView

- (instancetype)initWithImage:(UIImage *)image
{
    
    if (self = [super init]) {
        _image = image;
        [self setup];
    }
    return self;
}

-(void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self layoutInitialImage];
}

-(void)setup
{
    self.backgroundColor = [UIColor colorWithWhite:0.12f alpha:1.0f];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.zoomScale = 1.0f;
    [self addSubview:self.scrollView];
    
    
    //Grey transparent overlay view
    self.overlayView = [[UIView alloc] initWithFrame:self.bounds];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.overlayView.backgroundColor = [self.backgroundColor colorWithAlphaComponent:0.35f];
    self.overlayView.hidden = NO;
    self.overlayView.userInteractionEnabled = NO;
    [self addSubview:self.overlayView];
    
    
    
    
    self.backgroundImageView = [[UIImageView alloc] initWithImage:self.image];
    self.backgroundContainerView = [[UIView alloc] initWithFrame:self.backgroundImageView.frame];
    [self.backgroundContainerView addSubview:self.backgroundImageView];
    [self.scrollView addSubview:self.backgroundContainerView];
    
//
//    self.foregroundContainerView = [[UIView alloc] initWithFrame:(CGRect){0,0,200,200}];
//    self.foregroundContainerView.clipsToBounds = YES;
//    self.foregroundContainerView.userInteractionEnabled = NO;
    
//    [self addSubview:self.foregroundContainerView];
    
    self.gridOverlayView = [[PPCropLineView alloc] initWithFrame:(CGRect){0,0,200,200}];
    self.gridOverlayView.userInteractionEnabled = NO;
    
    [self addSubview:self.gridOverlayView];
    
    
    
}



-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.backgroundContainerView;
}

- (void)layoutInitialImage
{
    self.scrollView.contentSize = self.imageSize;
    CGRect bounds = self.bounds;
    CGSize imageSize = self.imageSize;
//    CGFloat scale = MIN((CGRectGetWidth(bounds)-kTOCropViewPadding*2)/imageSize.width, CGRectGetHeight(bounds)/imageSize.height);
    CGFloat scale = (CGRectGetWidth(bounds)-kTOCropViewPadding*2)/imageSize.width;
    CGSize scaledSize = (CGSize){floorf(imageSize.width * scale), floorf(imageSize.height * scale)};

    self.scrollView.minimumZoomScale = scale;
    self.scrollView.maximumZoomScale = 15.0f;
    //set the fully zoomed out state initially
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    self.scrollView.contentSize = scaledSize;
    
   
    
//    self.foregroundContainerView.frame = self.cropBoxFrame;
    self.gridOverlayView.frame = self.cropBoxFrame;

    
    
    [self.overlayView.layer setMask:self.shaperLayer];
    
    
    
}

-(CAShapeLayer *)shaperLayer
{
    if (!_shaperLayer) {
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        [path appendPath:[[UIBezierPath bezierPathWithRoundedRect:self.cropBoxFrame cornerRadius:1] bezierPathByReversingPath]];
        _shaperLayer = [CAShapeLayer layer];
        _shaperLayer.path = path.CGPath;
        

    }
    return _shaperLayer;
}

-(CGRect)cropBoxFrame
{
    CGFloat scale  = 0.67f;
    CGRect contentRect = CGRectZero;
   
    
    contentRect.size.width = CGRectGetWidth(self.bounds) - (kTOCropViewPadding * 2);
    contentRect.size.height = contentRect.size.width * scale;
    
    contentRect.origin.x = self.center.x-(contentRect.size.width/2);
    contentRect.origin.y = self.center.y-((contentRect.size.height)/2);
    
    
    self.scrollView.contentInset = (UIEdgeInsets){CGRectGetMinY(contentRect),
        CGRectGetMinX(contentRect),
        CGRectGetMaxY(self.bounds) - CGRectGetMaxY(contentRect),
        CGRectGetMaxX(self.bounds) - CGRectGetMaxX(contentRect)};
    
    return contentRect;
}

- (CGRect)contentBounds
{
    CGRect contentRect = CGRectZero;
    contentRect.origin.x = kTOCropViewPadding;
    contentRect.origin.y = kTOCropViewPadding;
    contentRect.size.width = CGRectGetWidth(self.bounds) - (kTOCropViewPadding * 2);
    contentRect.size.height = CGRectGetHeight(self.bounds) - (kTOCropViewPadding * 2);
    return contentRect;
}


- (CGRect)croppedImageFrame
{
    CGSize imageSize = self.imageSize;
    CGSize contentSize = self.scrollView.contentSize;
    CGRect cropBoxFrame = self.cropBoxFrame;
    CGPoint contentOffset = self.scrollView.contentOffset;
    UIEdgeInsets edgeInsets = self.scrollView.contentInset;
    
    CGRect frame = CGRectZero;
    frame.origin.x = floorf((contentOffset.x + edgeInsets.left) * (imageSize.width / contentSize.width));
    frame.origin.x = MAX(0, frame.origin.x);
    
    frame.origin.y = floorf((contentOffset.y + edgeInsets.top) * (imageSize.height / contentSize.height));
    frame.origin.y = MAX(0, frame.origin.y);
    
    frame.size.width = ceilf(cropBoxFrame.size.width * (imageSize.width / contentSize.width));
    frame.size.width = MIN(imageSize.width, frame.size.width);
    
    frame.size.height = ceilf(cropBoxFrame.size.height * (imageSize.height / contentSize.height));
    frame.size.height = MIN(imageSize.height, frame.size.height);
    
    return frame;
}

- (CGSize)imageSize
{
    return (CGSize){self.image.size.width, self.image.size.height};
}





@end
