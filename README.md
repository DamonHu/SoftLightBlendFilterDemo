# SoftLightBlendFilterDemo
GPUImage录制加美颜、柔光的demo
# 说明文章
《[GPUImage录制加美颜、柔光](http://www.hudongdong.com/ios/539.html)》

## GPUImage录制加美颜、柔光

柔光就是加了一层滤镜，如果是图片上面加柔光，看这个文章就可以了《[IOS使用GPUImage滤镜初级试水](http://www.hudongdong.com/ios/395.html)》。如果是为了给录制的视频加柔光，也是使用的GPUImageSoftLightBlendFilter这个滤镜效果。

## 一、柔光滤镜

因为`GPUImageSoftLightBlendFilter`是`GPUImageTwoInputFilter`的子类，而`GPUImageTwoInputFilter`是`GPUImageFilter`的子类，对两个输入纹理进行通用的处理，需要继承它并准备自己的片元着色器。所以为了方便，就封装了一个柔光类，里面使用一个图片`blend.png`，专门对视频用。

<!--more-->

**DSoftLightBlendFilter.h文件**

```
#import "GPUImageFilterGroup.h"
#import "GPUImage.h"

@interface DSoftLightBlendFilter : GPUImageFilterGroup
{
    GPUImagePicture *imageSource ;
}
@end
```
**DSoftLightBlendFilter.m文件**

```
#import "DSoftLightBlendFilter.h"


@implementation DSoftLightBlendFilter
- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    UIImage *image = [UIImage imageNamed:@"blend.png"];
    
    imageSource = [[GPUImagePicture alloc] initWithImage:image];
    
    GPUImageSoftLightBlendFilter *filter = [[GPUImageSoftLightBlendFilter alloc] init];
    
    [self addFilter:filter];
    [imageSource addTarget:filter atTextureLocation:1];
    [imageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:filter, nil];
    self.terminalFilter = filter;
    
    return self;
}
@end
```

视频使用的时候就像使用一个普通的filter加到GPUImageVideoCamera、GPUImageMovieWriter上面即可。

## 二、美颜滤镜

美颜滤镜是使用的这个[GPUImageBeautifyFilter](https://github.com/Guikunzhi/BeautifyFaceDemo)，在这个基础上我调低了效果，加了一个美颜参数的设置。

```
//设置美化强度
- (id)initWithDegree:(float)degree;
```
这样就可以设置不同的美颜强度了。

## 三、使用
使用两个可以叠加使用，新建一个GPUImageFilterGroup *filterGroup;，然后叠加

```
filterGroup = [[GPUImageFilterGroup alloc] init];
[filterGroup addFilter:beautifyFilter];
[filterGroup addFilter:m_softLightBlendFilter];
[beautifyFilter addTarget:m_softLightBlendFilter];
[filterGroup setInitialFilters:[NSArray arrayWithObject: beautifyFilter]];
[filterGroup setTerminalFilter:m_softLightBlendFilter];

[filterGroup addTarget:m_filteredVideoView];
[m_videoCamera addTarget:filterGroup];

[m_videoCamera startCameraCapture];
```
记得录视频把moviewriter加上

```
//写入加上滤镜
[filterGroup addTarget:m_movieWriter];
```

## 四、Demo下载
这个demo同时加入了光度、曝光、对比度、饱和度、柔光、美颜的调节，可以看下效果。

Github下载：[https://github.com/DamonHu/SoftLightBlendFilterDemo](https://github.com/DamonHu/SoftLightBlendFilterDemo)

Gitosc下载：[http://git.oschina.net/DamonHoo/SoftLightBlendFilterDemo](http://git.oschina.net/DamonHoo/SoftLightBlendFilterDemo)

## 五、demo演示
![](http://cdn.hudongdong.com/2017042817141.gif)
