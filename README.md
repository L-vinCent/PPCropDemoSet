
##高仿 iOS 原生图片裁切

----
* 简洁版 -- 固定裁切框大小，图片可拖动缩放，精准裁切 
* 进阶版 -- 裁切框可拖动，动态显示交互图    
* 优化版 -- 增加毛玻璃效果，去掉 ShaperLayer     

版本分开，便于理解，循环渐进

----

### 简洁版.  2018.4.10
尝试用STAR法则写一篇小白Demo，关于自定义图片切割功能


-----

> STAR法则是情境(situation)、任务(task)、行动(action)、结果(result)

### 情境(situation)
需要一个裁切固定尺寸图片的功能，类似这样

###任务(task)
封装一个View，需要以下功能

* 可以接受选择的图片显示

* 图片编辑完成后给出图片的裁切范围

* 图片可以放大，缩小，拖动，且活动范围在给定的裁切框范围内


###行动(action)

从任务预期来看
首先需要给出一个参数 image 用来接收外界传过来的参数

在image做完交互后传出对应到原始image 的Frame，切割用

因为图片需要有放大缩小拖动的交互，所以自然想到可以把图片放到 UIScrollView 容器内,为了方便说明，整个裁切的结构层级如下
* 1  是用UIScrollView做容器
* 2 是添加一个UIImageView用来展示图片
* 3 是一个UIView，作为一个遮罩
* 4 是一个自定义的UIView，裁切框，这个Frame很关键


![](https://upload-images.jianshu.io/upload_images/904629-d5338e03ba8ed85f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/300)

-----
* 比较关键的一些点


```bash
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.backgroundContainerView;
//这里 backgroundContainerView 是imageView的容器，实现这个代理保证图片的放大拖动交互
}
```

```bash
 self.scrollView.contentInset = (UIEdgeInsets){CGRectGetMinY(contentRect),
        CGRectGetMinX(contentRect),
        CGRectGetMaxY(self.bounds) - CGRectGetMaxY(contentRect),
        CGRectGetMaxX(self.bounds) - CGRectGetMaxX(contentRect)};

contentRect 是裁切框Frame
这里的偏移量 scrollView.contentInset 用来保证图片不滑出 裁切框外

```

```bash
  self.scrollView.minimumZoomScale = scale;
  self.scrollView.maximumZoomScale = 15.0f;
self.scrollView.zoomScale = self.scrollView.minimumZoomScale;

这里设置  scrollView 最大和最小缩放范围，这里的scale获取以屏幕宽为主
比如.    一个原始大小为  750*1330 的图片，scale 为 375/750


```



```bash

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

cropBoxFrame 是裁切框的Frame，这里返回的是遮罩的镂空层,添加到遮罩层上
```



* 获取到交互后的图片 对应到 原始图片坐标点和大小

```bash
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

 要知道图片的原始尺寸 与 scrollView.contentSize 的比例，
然后通过 contentOffset 算出 在对应比例下图片的移动位置，得到要切割的起始坐标



```



###结果(result)

* 使用

```bash
PPMainCropVC *vc = [[PPMainCropVC alloc]initWithImage:[UIImage imageNamed:@"1.png"]];
    
    vc.cropBlock = ^(UIImage *image) {
    
        [self.mainImageView setImage:image];
        
    };
    [self.navigationController pushViewController:vc animated:YES];

```


* 在裁切页面隐藏了导航栏和状态栏，如果图片拖动与裁切框有偏移，看看Info.plist 中 ， 设置 View controller-based status bar appearance 为NO，该参数决定我们项目状态栏的显隐藏是否以各控制器的设置为准。


--------

### 进阶版  2018.4.10
* 在原基础上裁切框可拖动选择大小

一开始手势考虑加在 PPCropLineView 内，相对坐标不好计算。这里直接在 PPFixCropView 添加一个拖动手势，为避免与scrollView的拖动手势冲突,需要设置 

```bash
    [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.gridPanGestureRecognizer];
    
//优先触发 gridPanGestureRecognizer 手势，当 gridPanGestureRecognizer 手势失效之后再触发 scrollView 的自带手势
```



在这个代理方法里通过 手指的点击范围判断 Point 是否在 裁切框的触摸范围内，区分开 是移动 scrollow 的图片( scrollow 的内置手势方法)  还是拖动裁切框 (自定义的手势方法)


``` bash
 - (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
 
```
 
 在交互手势结束，重新计算CropFrame大小和起始点。  这里关键是 计算出 交互后的CropFrame 与 contentBounds 的scale, 等比例计算出 contentOffset的偏移量. 
 
 额外讲一点，scrollow在往右下拖动的时候都是负值变小,从坐标轴看,这个图比较好看明白
 
 ![](https://images2015.cnblogs.com/blog/912458/201603/912458-20160329130454379-1161572982.png)
 
 ---
 
 
 
### 优化版 2018.4.12

* 上个版本中 通过 shapeLayer 将遮罩层切割了CropFrame，用于显示切割范围，在裁切框拖动结束后有延迟的情况,这里做一次修改

```bash

--- 去掉shapeLayer，新增
//foregroundImageView， 复制background image view，展示裁切框中的图片区域

//foregroundContainerView foregroundImageView的父视图，超出裁切范围就不显示  clipsToBounds = YES
 用来代替 shapeLayer 的显示切割范围的效果
 
 
 self.foregroundImageView.frame = [self.backgroundContainerView.superview convertRect:self.backgroundContainerView.frame toView:self.foregroundContainerView];
 // 将 backgroundContainerView 在 所在父视图的坐标 映射到  foregroundContainerView 上
```
 
* 添加一层毛玻璃View 层 ，在  backgroundContainerView 和 foregroundContainerView 之间 ，在交互收拾开始和结束时候做 alpha 透明度操作
* 新的整体结构图差不多是这样
![](https://upload-images.jianshu.io/upload_images/904629-23a7d1bded918c36.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)