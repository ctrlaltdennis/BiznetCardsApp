//
//  ImageResizer.h
//  BiznetCards
//
//  Created by TheApp4U on 4/12/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageResizer : UIImage
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height;

@end
