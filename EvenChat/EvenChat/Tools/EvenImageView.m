//
//  EvenImageView.m
//  EvenChat
//
//  Created by Even on 16/8/19.
//  Copyright © 2016年 Cube. All rights reserved.
//

#import "EvenImageView.h"

@implementation EvenImageView

//根据图片尺寸进行对应的缩放适应
- (CGSize)intrinsicContentSize
{
    CGSize systemSize = [super intrinsicContentSize];
    
    
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width * 0.7;
    if (self.image.size.width > maxWidth) {
        // 更改为图片的大小
        CGFloat maxHeight = (self.image.size.height / self.image.size.width) * maxWidth;
        
        systemSize = CGSizeMake(maxWidth, maxHeight);
        
    }
    return systemSize;
}

@end
