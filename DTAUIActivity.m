//
//  DTAUIActivity.m
//  BiznetCards
//
//  Created by TheApp4U on 3/11/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "DTAUIActivity.h"

@implementation DTAActivityItemMessage
-(id)item{
    if ([self.activityType isEqualToString:UIActivityTypeAirDrop])
    {
        return nil;
    }else{
        return self.placeholderItem;
    }


}
@end


@implementation DTAActivityItemImage
-(id)item{
    if ([self.activityType isEqualToString:UIActivityTypeAirDrop])
    {
        return nil;
    }else{
        return self.placeholderItem;
    }

    
}
@end

@implementation DTAActivityItemURL
-(id)item{
    if ([self.activityType isEqualToString:UIActivityTypeAirDrop])
    {
        return self.placeholderItem;
    }else{
        return self.placeholderItem;
    }
    
}
@end


