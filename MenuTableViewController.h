//
//  MenuTableViewController.h
//  BiznetCardsV2
//
//  Created by TheApp4U on 2/12/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuTableViewController : UITableViewController
@property (strong, nonatomic) NSString *base_url;
@property (strong, nonatomic) NSString *card_owner;
@property (strong, nonatomic) NSString *card_id;
@property (strong, nonatomic) NSMutableData *qrData;
@property (strong, nonatomic) NSMutableData *vCardData;
@end
