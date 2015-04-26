//
//  DetailViewController.h
//  BiznetCardsV2
//
//  Created by TheApp4U on 1/30/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface DetailViewController : UIViewController <UIWebViewDelegate>
@property (strong,nonatomic) NSString *card_id;
-(void)save_contact;
-(void)share;
-(void)dismissPopover;
@end
