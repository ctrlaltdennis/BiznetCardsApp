//
//  DTAUIActivity.h
//  BiznetCards (Dennis Arguelles)
//
//  Created by TheApp4U on 3/11/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DTAActivityItemMessage : UIActivityItemProvider <UIActivityItemSource>
    @property (strong,nonatomic) NSString *message;
@end

@interface DTAActivityItemURL : UIActivityItemProvider <UIActivityItemSource>
@property (strong,nonatomic) NSURL *url;
@end

@interface DTAActivityItemImage : UIActivityItemProvider <UIActivityItemSource>
  @property (strong,nonatomic) NSString *message;
  @property (strong, nonatomic) NSURL *url;
@end

