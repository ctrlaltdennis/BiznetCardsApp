//
//  ImageCache.h
//  BiznetCards
//
//  Created by TheApp4U on 3/13/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ImageCache : NSObject

@property (nonatomic, retain) NSCache *imgCache;
#pragma mark - Methods
+ (ImageCache*)sharedImageCache;
-(void)AddImage:(NSString *)imageURL :(UIImage *)image;
-(UIImage*) GetImage:(NSString *)imageURL;
-(BOOL) DoesExist:(NSString *)imageURL;

@end