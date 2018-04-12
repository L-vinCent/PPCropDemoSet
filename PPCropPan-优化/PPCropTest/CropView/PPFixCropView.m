//
//  PPFixCropView.m
//  amezMall_New
//
//  Created by Liao PanPan on 2018/3/29.
//  Copyright © 2018年 Liao PanPan. All rights reserved.
//

#import "PPFixCropView.h"
#import "PPCropLineView.h"
#import "PPCropScrollView.h"
typedef NS_ENUM(NSUInteger, PPCropViewLineEdge) {
    PPCropViewLineEdgeNone,
    PPCropViewLineEdgeTopLeft,
    PPCropViewLineEdgeTop,
    PPCropViewLineEdgeTopRight,
    PPCropViewLineEdgeRight,
    PPCropViewLineEdgeBottomRight,
    PPCropViewLineEdgeBottom,
    PPCropViewLineEdgeBottomLeft,
    PPCropViewLineEdgeLeft
};

static const CGFloat kTOCropViewPadding = 10.0f;
static const NSTimeInterval kTOCropTimerDuration = 0.8f;
static const CGFloat kTOCropViewMinimumBoxSize = 42.0f;

@interface PPFixCropView()<UIScrollViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIImage *image;

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *backgroundContainerView;
@property (nonatomic, strong) PPCropScrollView *scrollView;

@property (nonatomic, strong) UIView *overlayView;
//@property (nonatomic, strong) CAShapeLayer *shaperLayer;


@property (nonatomic, readonly) CGSize imageSize;

@property (nonatomic, readonly) CGRect contentBounds; /*裁切框活动范围*/
@property (nonatomic, assign, readwrite) CGRect cropBoxFrame;
@property (nonatomic, assign) CGPoint panOriginPoint;     /* 裁切框拖动手势的起始点 */
@property (nonatomic, assign) CGRect cropOriginFrame;     /* 改变裁切框大小的时候   记录上一次裁切框Frame */
@property (nonatomic, assign) PPCropViewLineEdge tappedEdge; /* 点击的范围枚举 */

@property (nonatomic, strong) UIImageView *foregroundImageView;     /* 复制background image view，展示裁切框中的图片区域 */
@property (nonatomic, strong) UIView *foregroundContainerView;        /* foregroundImageView的父视图，超出裁切范围就不显示  clipsToBounds = YES */
@property (nonatomic, strong) UIView *translucencyView;  /*毛玻璃效果遮盖*/

@property (nonatomic, strong) NSTimer *resetTimer;
@property (nonatomic, assign) BOOL editing;

@property (nonatomic, strong) PPCropLineView *gridOverlayView;


@property (nonatomic, strong) UIPanGestureRecognizer *gridPanGestureRecognizer; /* 裁剪框拖动手势 */



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

#pragma mark - View Layout

-(void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self layoutInitialImage];
}

-(void)setup
{
    
    __weak typeof (self) weakSelf = self;
    self.backgroundColor = [UIColor colorWithWhite:0.12f alpha:1.0f];
    self.scrollView = [[PPCropScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.zoomScale = 1.0f;
    [self addSubview:self.scrollView];
    
    self.scrollView.touchesBegan = ^{ [weakSelf startEditing]; };
    self.scrollView.touchesEnded = ^{ [weakSelf startResetTimer]; };
    
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
    
    
    
    self.translucencyView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.translucencyView.frame = self.bounds;
    
    self.translucencyView.hidden = NO;
    self.translucencyView.userInteractionEnabled = NO;
    self.translucencyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.translucencyView];
    
    
    
    
    self.foregroundContainerView = [[UIView alloc] initWithFrame:(CGRect){0,0,200,200}];
    self.foregroundContainerView.clipsToBounds = YES;
    self.foregroundContainerView.userInteractionEnabled = NO;
    [self addSubview:self.foregroundContainerView];
    
    self.gridOverlayView = [[PPCropLineView alloc] initWithFrame:self.foregroundContainerView.frame];
    self.gridOverlayView.userInteractionEnabled = NO;
    [self addSubview:self.gridOverlayView];
    
    self.foregroundImageView = [[UIImageView alloc] initWithImage:self.image];
    [self.foregroundContainerView addSubview:self.foregroundImageView];
    
    
    
    self.gridPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gridPanGestureRecognized:)];
    self.gridPanGestureRecognizer.delegate = self;
    [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.gridPanGestureRecognizer];
    [self addGestureRecognizer:self.gridPanGestureRecognizer];
    
    
    self.editing = NO;

}


- (void)layoutInitialImage
{
    CGSize imageSize = self.imageSize;
    self.scrollView.contentSize = self.imageSize;
    CGRect bounds = self.contentBounds;
    
    CGFloat scale = MAX(CGRectGetWidth(bounds)/imageSize.width, CGRectGetHeight(bounds)/imageSize.height);
//    CGFloat scale = (CGRectGetWidth(bounds)/imageSize.width;
    CGSize scaledSize = (CGSize){floorf(imageSize.width * scale), floorf(imageSize.height * scale)};

    self.scrollView.minimumZoomScale = scale;
    self.scrollView.maximumZoomScale = 15.0f;
    //set the fully zoomed out state initially
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    self.scrollView.contentSize = scaledSize;
    
    
    CGRect frame = CGRectZero;
    frame.size = scaledSize;
    frame.origin.x = bounds.origin.x + floorf((CGRectGetWidth(bounds) - frame.size.width) * 0.5f);
    frame.origin.y = bounds.origin.y + floorf((CGRectGetHeight(bounds) - frame.size.height) * 0.5f);
    self.cropBoxFrame = frame;
    
    self.foregroundContainerView.frame = _cropBoxFrame;
    self.gridOverlayView.frame = self.cropBoxFrame;

    
    
//    [self.overlayView.layer setMask:self.shaperLayer];
    
    [self matchForegroundToBackground];
    
    
}
- (void)matchForegroundToBackground
{
    self.foregroundImageView.frame = [self.backgroundContainerView.superview convertRect:self.backgroundContainerView.frame toView:self.foregroundContainerView];
}

-(UIBezierPath *)beaPath:(CGRect)frame
{
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [path appendPath:[[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:1] bezierPathByReversingPath]];
    return path;
    
}

//-(CAShapeLayer *)shaperLayer
//{
//    if (!_shaperLayer) {
//
//        UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
//        [path appendPath:[[UIBezierPath bezierPathWithRoundedRect:self.cropBoxFrame cornerRadius:1] bezierPathByReversingPath]];
//        _shaperLayer = [CAShapeLayer layer];
//        _shaperLayer.path = path.CGPath;
//
//    }
//    return _shaperLayer;
//}




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
    
    frame.size.height = ceilf(cropBoxFrame.size.height * (imageSize.height / contentSize.height)                                  );
    frame.size.height = MIN(imageSize.height, frame.size.height);
    
    return frame;
}

- (CGSize)imageSize
{
    return (CGSize){self.image.size.width, self.image.size.height};
}

#pragma mark - Editing Mode -
- (void)startEditing
{
    [self cancelResetTimer];
    [self setEditing:YES animated:YES];
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}



- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (editing == _editing)
        return;
    
    _editing = editing;
    
    [self.gridOverlayView setGridHidden:!editing animated:animated];
    
    if (editing == NO) {
        
        [self moveCroppedContentToCenterAnimated:animated];

    }
    
    [UIView animateWithDuration:editing?0.2f:0.35f animations:^{
        self.translucencyView.alpha  = editing ? 0.0f : 1.0f;
    }];
    
}


#pragma mark - Scroll View Delegate -

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return self.backgroundContainerView; }
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView    { [self startEditing]; }
- (void)scrollViewDidScroll:(UIScrollView *)scrollView            {
    [self matchForegroundToBackground];
    
}
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view { [self startEditing]; }
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView   { [self startResetTimer]; }
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{[self startResetTimer]; };
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale { [self startResetTimer]; }
- (void)scrollViewDidZoom:(UIScrollView *)scrollView  { [self matchForegroundToBackground];}

#pragma mark - Timer -
- (void)startResetTimer
{
    if (self.resetTimer)
        return;
    
    self.resetTimer = [NSTimer scheduledTimerWithTimeInterval:kTOCropTimerDuration target:self selector:@selector(timerTriggered) userInfo:nil repeats:NO];
}

- (void)timerTriggered
{
    [self setEditing:NO animated:YES];
    [self.resetTimer invalidate];
    self.resetTimer = nil;
}

- (void)cancelResetTimer
{
    [self.resetTimer invalidate];
    self.resetTimer = nil;
}


#pragma mark - Calculta CropFrame


-(void)setCropBoxFrame:(CGRect)cropBoxFrame
{
    
    if (CGRectEqualToRect(cropBoxFrame, _cropBoxFrame))
        return;
    
    if (cropBoxFrame.size.width < FLT_EPSILON || cropBoxFrame.size.height < FLT_EPSILON)
        return;
    
    //控制裁剪框不超出设置的 contentBounds 范围
    CGRect contentFrame = self.contentBounds;
    CGFloat xOrigin = ceilf(contentFrame.origin.x);
    CGFloat xDelta = cropBoxFrame.origin.x - xOrigin;
    cropBoxFrame.origin.x = floorf(MAX(cropBoxFrame.origin.x, xOrigin));
        if (xDelta < -FLT_EPSILON) // 浮点数计算1.0 == 10.0/10.0 有时候不返回true， FLT_EPSILON 控制在能接受的误差范围
            cropBoxFrame.size.width += xDelta;
    
    CGFloat yOrigin = ceilf(contentFrame.origin.y);
    CGFloat yDelta = cropBoxFrame.origin.y - yOrigin;
    cropBoxFrame.origin.y = floorf(MAX(cropBoxFrame.origin.y, yOrigin));
        if (yDelta < -FLT_EPSILON)
            cropBoxFrame.size.height += yDelta;
    
    
    
    CGFloat maxWidth = (contentFrame.size.width + contentFrame.origin.x) - cropBoxFrame.origin.x;
    cropBoxFrame.size.width = floorf(MIN(cropBoxFrame.size.width, maxWidth));
    
    CGFloat maxHeight = (contentFrame.size.height + contentFrame.origin.y) - cropBoxFrame.origin.y;
    cropBoxFrame.size.height = floorf(MIN(cropBoxFrame.size.height, maxHeight));
    
    cropBoxFrame.size.width  = MAX(cropBoxFrame.size.width, kTOCropViewMinimumBoxSize);
    cropBoxFrame.size.height = MAX(cropBoxFrame.size.height, kTOCropViewMinimumBoxSize);
    
    
    _cropBoxFrame = cropBoxFrame;
    self.foregroundContainerView.frame = _cropBoxFrame; //set the clipping view to match the new rect
    self.gridOverlayView.frame = self.cropBoxFrame; //set the new overlay view to match the same region
    self.scrollView.contentInset = (UIEdgeInsets){CGRectGetMinY(_cropBoxFrame),
        CGRectGetMinX(_cropBoxFrame),
        CGRectGetMaxY(self.bounds) - CGRectGetMaxY(_cropBoxFrame),
        CGRectGetMaxX(self.bounds) - CGRectGetMaxX(_cropBoxFrame)};
    
//    self.shaperLayer.path = [self beaPath:self.cropBoxFrame].CGPath;
    
//    [self.overlayView.layer setMask:self.shaperLayer];

    CGSize size = self.scrollView.contentSize;
    size.width = floorf(size.width);
    size.height = floorf(size.height);
    //self.backgroundContainerView.frame = (CGRect){CGPointZero, size};
    self.scrollView.contentSize = size;
    
    
    
    self.scrollView.zoomScale = self.scrollView.zoomScale;
    [self matchForegroundToBackground]; //re-alig
    
}

-(PPCropViewLineEdge)cropEdgeForPoint:(CGPoint)point
{
    
    CGRect frame = self.cropBoxFrame;
    frame = CGRectInset(frame, -22, -22);
    
    CGRect topLeftRect = (CGRect){frame.origin, {44,44}};
    if (CGRectContainsPoint(topLeftRect, point))
        return PPCropViewLineEdgeTopLeft;
    
    CGRect topRightRect = topLeftRect;
    topRightRect.origin.x = CGRectGetMaxX(frame) - 44.0f;
    if (CGRectContainsPoint(topRightRect, point))
        return PPCropViewLineEdgeTopRight;
    
    CGRect bottomLeftRect = topLeftRect;
    bottomLeftRect.origin.y = CGRectGetMaxY(frame) - 44.0f;
    if (CGRectContainsPoint(bottomLeftRect, point))
        return PPCropViewLineEdgeBottomLeft;
    
    CGRect bottomRightRect = topRightRect;
    bottomRightRect.origin.y = bottomLeftRect.origin.y;
    if (CGRectContainsPoint(bottomRightRect, point))
        return PPCropViewLineEdgeBottomRight;
    
    //Check for edges
    CGRect topRect = (CGRect){frame.origin, {CGRectGetWidth(frame), 44.0f}};
    if (CGRectContainsPoint(topRect, point))
        return PPCropViewLineEdgeTop;
    
    CGRect bottomRect = topRect;
    bottomRect.origin.y = CGRectGetMaxY(frame) - 44.0f;
    if (CGRectContainsPoint(bottomRect, point))
        return PPCropViewLineEdgeBottom;
    
    CGRect leftRect = (CGRect){frame.origin, {44.0f, CGRectGetHeight(frame)}};
    if (CGRectContainsPoint(leftRect, point))
        return PPCropViewLineEdgeLeft;
    
    CGRect rightRect = leftRect;
    rightRect.origin.x = CGRectGetMaxX(frame) - 44.0f;
    if (CGRectContainsPoint(rightRect, point))
        return PPCropViewLineEdgeRight;
    
    return PPCropViewLineEdgeNone;
    
}

- (void)updateCropBoxFrameWithGesturePoint:(CGPoint)point
{
    
    CGRect frame = self.cropBoxFrame;
    CGRect originFrame = self.cropOriginFrame;
    CGRect contentFrame = self.contentBounds;
    
    point.x = MAX(contentFrame.origin.x, point.x);
    point.y = MAX(contentFrame.origin.y, point.y);
    
    CGFloat xDelta = ceilf(point.x - self.panOriginPoint.x);
    CGFloat yDelta = ceilf(point.y - self.panOriginPoint.y);
    
    switch (self.tappedEdge) {
        case PPCropViewLineEdgeLeft:
          
            frame.origin.x   = originFrame.origin.x + xDelta;
            frame.size.width = originFrame.size.width - xDelta;
            break;
        case PPCropViewLineEdgeRight:
           
                frame.size.width = originFrame.size.width + xDelta;
            
            break;
        case PPCropViewLineEdgeBottom:
           
                frame.size.height = originFrame.size.height + yDelta;
            
            break;
        case PPCropViewLineEdgeTop:
          
                frame.origin.y    = originFrame.origin.y + yDelta;
                frame.size.height = originFrame.size.height - yDelta;
            
            break;
        case PPCropViewLineEdgeTopLeft:
           
                frame.origin.x   = originFrame.origin.x + xDelta;
                frame.size.width = originFrame.size.width - xDelta;
                frame.origin.y   = originFrame.origin.y + yDelta;
                frame.size.height = originFrame.size.height - yDelta;
       
            break;
        case PPCropViewLineEdgeTopRight:
           
                frame.size.width  = originFrame.size.width + xDelta;
                frame.origin.y    = originFrame.origin.y + yDelta;
                frame.size.height = originFrame.size.height - yDelta;
          
            break;
        case PPCropViewLineEdgeBottomLeft:
 
                frame.size.height = originFrame.size.height + yDelta;
                frame.origin.x    = originFrame.origin.x + xDelta;
                frame.size.width  = originFrame.size.width - xDelta;
           
            break;
        case PPCropViewLineEdgeBottomRight:
          
                frame.size.height = originFrame.size.height + yDelta;
                frame.size.width = originFrame.size.width + xDelta;
            
            break;
            
        case PPCropViewLineEdgeNone: break;
    }
    
    
    self.cropBoxFrame = frame;

    
    
}

- (void)moveCroppedContentToCenterAnimated:(BOOL)animated
{
    
    CGRect contentRect = self.contentBounds;
    CGRect cropFrame = self.cropBoxFrame;
    
    CGPoint focusPoint = (CGPoint){CGRectGetMidX(cropFrame), CGRectGetMidY(cropFrame)};
    CGPoint midPoint = (CGPoint){CGRectGetMidX(contentRect), CGRectGetMidY(contentRect)};
    
    CGFloat scale = MIN(CGRectGetWidth(contentRect)/CGRectGetWidth(cropFrame), CGRectGetHeight(contentRect)/CGRectGetHeight(cropFrame));
    
//    CGRect NewFrame = (CGRect){cropFrame.origin,CGRectGetWidth(cropFrame)*scale,CGRectGetHeight(cropFrame)*scale};
    
    cropFrame.size.width = floorf(cropFrame.size.width * scale);
    cropFrame.size.height = floorf(cropFrame.size.height * scale);
    cropFrame.origin.x = contentRect.origin.x + floorf((contentRect.size.width - cropFrame.size.width) * 0.5f);
    cropFrame.origin.y = contentRect.origin.y + floorf((contentRect.size.height - cropFrame.size.height) * 0.5f);
    
    //Work out the point on the scroll content that the focusPoint is aiming at
    CGPoint contentTargetPoint = CGPointZero;
    contentTargetPoint.x = ((focusPoint.x + self.scrollView.contentOffset.x) * scale);
    contentTargetPoint.y = ((focusPoint.y + self.scrollView.contentOffset.y) * scale);
    
    NSLog(@"---%f", self.scrollView.contentOffset.x);
    NSLog(@"++++++=%@", NSStringFromUIEdgeInsets(self.scrollView.contentInset));
    
    //Work out where the crop box is focusing, so we can re-align to center that point
    __block CGPoint offset = CGPointZero;
    offset.x = -midPoint.x + contentTargetPoint.x;
    offset.y = -midPoint.y + contentTargetPoint.y;
    
    //clamp the content so it doesn't create any seams around the grid
    offset.x = MAX(-cropFrame.origin.x, offset.x);
    offset.y = MAX(-cropFrame.origin.y, offset.y);
    
    __weak typeof(self) weakSelf = self;

    [UIView animateWithDuration:0.5f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:1.0f options:0 animations:^{
        
        typeof(self) strongSelf = weakSelf;
        strongSelf.scrollView.zoomScale *= scale;
        offset.x = MIN(-CGRectGetMaxX(cropFrame)+strongSelf.scrollView.contentSize.width, offset.x);
        offset.y = MIN(-CGRectGetMaxY(cropFrame)+strongSelf.scrollView.contentSize.height, offset.y);
        strongSelf.scrollView.contentOffset = offset;
        
        strongSelf.cropBoxFrame = cropFrame;
        [self matchForegroundToBackground];
        
    }  completion:nil];
    
}


#pragma mark - Gesture Recognizer
- (void)gridPanGestureRecognized:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self startEditing];
        self.panOriginPoint = point;
        self.cropOriginFrame = self.cropBoxFrame;
        self.tappedEdge = [self cropEdgeForPoint:self.panOriginPoint];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
        [self startResetTimer];
    
    [self updateCropBoxFrameWithGesturePoint:point];
    
}

- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
        [self.gridOverlayView setGridHidden:NO animated:YES];
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
        [self.gridOverlayView setGridHidden:YES animated:YES];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    
    if (gestureRecognizer != self.gridPanGestureRecognizer)
        return YES;
    //
    CGPoint tapPoint = [gestureRecognizer locationInView:self];
    
    CGRect frame = self.gridOverlayView.frame;
    CGRect innerFrame = CGRectInset(frame, 22.0f, 22.0f);
    CGRect outerFrame = CGRectInset(frame, -22.0f, -22.0f);
    
    if (CGRectContainsPoint(innerFrame, tapPoint) || !CGRectContainsPoint(outerFrame, tapPoint))
        return NO;
    
    return YES;
}


@end
