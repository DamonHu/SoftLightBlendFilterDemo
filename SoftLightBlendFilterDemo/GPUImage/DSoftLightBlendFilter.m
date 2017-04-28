//
//  DSoftLightBlendFilter.m
//  JianLiXiu
//
//  Created by Damon on 2017/4/24.
//  Copyright © 2017年 damon. All rights reserved.
//

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
