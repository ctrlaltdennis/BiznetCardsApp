//
//  DetailViewController.m
//  BiznetCardsV2
//
//  Created by TheApp4U on 1/30/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "DetailViewController.h"
#import "MenuTableViewController.h"
#import "WYPopoverController.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, retain) UIBarButtonItem *defaultRightBarButtonItem;

@end

@implementation DetailViewController
NSString *base_url;
NSMutableData *qrData;
NSMutableData *vCardData;
UIActivityIndicatorView *activityView;
NSURLConnection *qrconnection;
NSURLConnection *vcardconnection;
NSString *base_url;
NSString *card_owner;
WYPopoverController *popover;

- (void)viewDidLoad {
    [super viewDidLoad];
    base_url = @"http://wwww.biznetcards.com/";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    base_url = @"http://www.biznetcards.com/";
    
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.navigationController.topViewController.view addSubview: activityView];
    activityView.frame = CGRectMake(0, 0, 120, 120);
    activityView.backgroundColor =  [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    activityView.center = self.view.center;
    activityView.layer.cornerRadius = 10.0;
    [activityView startAnimating];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",base_url,@"zappcards/",_card_id]]]];
    self.webView.delegate = self;
    
    NSString *qrurl =
    [NSString stringWithFormat:@"%@%@%@%@",base_url,@"zapp_photos/qrcodes/",_card_id,@".jpg"];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:qrurl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
    
    qrconnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    NSString *vcardurl =
    [NSString stringWithFormat:@"%@%@%@%@",base_url,@"zappcards/",_card_id,@"/vCard.vcf"];
    
    NSLog(@"VCARD URL = %@",vcardurl);
    
    NSURLRequest* request1 = [NSURLRequest requestWithURL:[NSURL URLWithString:vcardurl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
    
    vcardconnection = [[NSURLConnection alloc] initWithRequest:request1 delegate:self];
    ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, nil);
    ABAddressBookRequestAccessWithCompletion(book, ^(bool granted, CFErrorRef error) {
        if (granted){
            NSLog(@"Address Book Access Granted");
        }
    });
    if(book != nil)
      CFRelease(book);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
    if (theConnection == qrconnection){
        if (qrData==nil) { qrData = [[NSMutableData alloc] initWithCapacity:2048]; }
        [qrData appendData:incrementalData];
    }else if (theConnection == vcardconnection){
        if (vCardData==nil) { vCardData = [[NSMutableData alloc] initWithCapacity:2048]; }
        [vCardData appendData:incrementalData];
    }
}
- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
    if (theConnection == qrconnection)
        NSLog(@"QR Download Complete");
    else if (theConnection == vcardconnection){
        NSLog(@"VCard Download Complete");
    }
}
- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error{
    if (theConnection == qrconnection)
        NSLog(@"Error downloding logo.");
    else if (theConnection == vcardconnection){
        NSLog(@"Error downloading qr code");
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
   
    NSString *AppScheme = @"bizcard";
    
    if (![request.URL.scheme isEqualToString:AppScheme]) {
        return YES;
    }
    
    NSString *action = request.URL.host;
    //NSString *jsonDictString = [request.URL.fragment stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL s = NSSelectorFromString(action);
    [self performSelector: s];
#pragma clang diagnostic pop
    return NO;
   
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (webView.isLoading)
        return;
    NSString *script = @"$(document).off('click','.share-button');"
                        "$(document).on('click','.share-button',function(e){"
                            "e.preventDefault();e.stopPropagation();"
                            "$(this).find('.social').remove();"
                            "window.location='bizcard://share';"
                        "});"
                        "$(document).find('#save-qr').html('Share QR Code');"
                        "$(document).off('click','#save-qr');"
                        "$(document).on('click','#save-qr',function(e){"
                            "e.preventDefault();e.stopPropagation();"
                            "window.location='bizcard://share_qr_code';"
                        "});"
                        "$(document).off('click','a[href=\"vCard.vcf\"]');"
                        "$(document).on('click','a[href=\"vCard.vcf\"]',function(e){"
                            " e.preventDefault();e.stopPropagation();"
                            " window.location='bizcard://save_contact';"
                        "});";
    
    [webView stringByEvaluatingJavaScriptFromString:script];
    
    card_owner =
      [webView stringByEvaluatingJavaScriptFromString:@"$(document).find('#zapp_name').html()"];
    
    [activityView stopAnimating];

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Error Loading Card");
}

-(void)contactRoutine{

    ABAddressBookRef book = ABAddressBookCreateWithOptions(NULL, nil);
    NSString *vCardString = [[NSString alloc] initWithData:vCardData encoding:NSUTF8StringEncoding];
    
    CFDataRef vCardData = (__bridge CFDataRef)[vCardString dataUsingEncoding:NSUTF8StringEncoding];
    
    ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(book);
    CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
    if (CFArrayGetCount(vCardPeople) > -1){
        CFIndex index = 0;
        
        ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);
        NSString * last_name = (__bridge NSString *)ABRecordCopyValue( person,kABPersonLastNameProperty);
        NSString * firstName = (__bridge NSString *)ABRecordCopyValue( person,kABPersonFirstNameProperty);
        
        NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(book);
        BOOL found = NO;
        
        for (id record in allContacts){
            ABRecordRef thisContact = (__bridge ABRecordRef)record;
            NSString * lastname = (__bridge NSString *)ABRecordCopyValue( thisContact, kABPersonLastNameProperty );
            NSString * firstname = (__bridge NSString *)ABRecordCopyValue( thisContact, kABPersonFirstNameProperty);
            ABMultiValueRef phones = ABRecordCopyValue(thisContact,kABPersonPhoneProperty);
            NSMutableArray *phoneS = [[NSMutableArray alloc] init];
            
            for(CFIndex i=0;i<ABMultiValueGetCount(phones);++i) {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, i);
                NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
               [phoneS addObject:phoneNumber];
            }
            
            
            NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
            phones = ABRecordCopyValue(thisContact,kABPersonPhoneProperty);
            for(CFIndex i=0;i<ABMultiValueGetCount(phones);++i) {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, i);
                NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
                
                [phoneNumbers addObject:phoneNumber];
            }
            if (phoneNumbers.count > 0){
                if ([lastname isEqualToString:last_name] && [firstname isEqualToString:firstName] &&
                    ([phoneS[0] isEqualToString:[phoneNumbers objectAtIndex:0]] || [phoneS[0] isEqualToString: [phoneNumbers objectAtIndex:0]])){
                    NSLog(@"Found some shit");
                    found = YES;
                    break;
                    
                }
            }

        }
        if (!found){
            ABAddressBookAddRecord(book, person, NULL);
            CFErrorRef error=nil;
            ABAddressBookSave(book, &error);
            if (error == nil){
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"BiznetCards"
                                                                  message:@"Contact Successfuly Saved"
                                                                 delegate:nil
                                                        cancelButtonTitle:@"Ok"
                                                        otherButtonTitles:nil, nil];
                [message show];
            }
        }else{
            UIAlertView *message1 = [[UIAlertView alloc] initWithTitle:@"BiznetCards"
                                                              message:@"Contact Already Exists."
                                                             delegate:nil
                                                    cancelButtonTitle:@"Ok"
                                                    otherButtonTitles:nil, nil];
            [message1 show];
        }
    }
    
    CFRelease(vCardPeople);
    CFRelease(defaultSource);
    
    CFRelease(book);
    

}

-(void)real_contact_save{
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self contactRoutine];
    }

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){
        [self real_contact_save ];
    }
}
-(void)save_contact{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"BiznetCards"
                                                      message:@"Do you want to save this contact?"
                                                     delegate:(id<UIAlertViewDelegate>)self
                                            cancelButtonTitle:@"No"
                                            otherButtonTitles:@"Yes", nil];
    [message show];
    
}
-(void)testView:(UIBarButtonItem *)sender{
    NSLog(@"Test Done");
}

-(void)share{
    [activityView startAnimating];
    NSString *textBody = [NSString stringWithFormat:@"Please click on the link below to open %@  business card details.\n",card_owner];
    NSURL *url =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",base_url,@"zappcards/",_card_id]];
    UIImage *imageToShare = nil;
    NSArray *itemsToShare = @[];
    if (imageToShare != nil){
        itemsToShare = @[textBody,url,imageToShare];
    }else{
        itemsToShare = @[textBody,url];
    }
    
    dispatch_queue_t queue = dispatch_queue_create("openActivityIndicatorQueue", NULL);
    
    // send initialization of UIActivityViewController in background
    dispatch_async(queue, ^{
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        
        [activityVC setValue:@"Don't Print It - Phone It!" forKey:@"subject"];
        // when UIActivityViewController is finally initialized,
        // hide indicator and present it on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityView stopAnimating];
            [self presentViewController:activityVC animated:YES completion:nil];
        });
    });
    

}

-(void)share_qr_code{
    NSLog(@"share qr code clicked");
    [activityView startAnimating];
    NSString *textBody = [NSString stringWithFormat:@"This QR Code contains the business card details. of %@ \n",card_owner];
    NSURL *url =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",base_url,@"zappcards/",_card_id]];
    UIImage *imageToShare = [UIImage imageWithData:qrData];
    NSArray *itemsToShare = @[];
    if (imageToShare != nil){
        itemsToShare = @[textBody,url,imageToShare];
    }else{
        itemsToShare = @[textBody,url];
    }
    
    dispatch_queue_t queue = dispatch_queue_create("openActivityIndicatorQueue", NULL);
    
    // send initialization of UIActivityViewController in background
    dispatch_async(queue, ^{
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        
        [activityVC setValue:@"Don't Print It - Phone It!" forKey:@"subject"];
        // when UIActivityViewController is finally initialized,
        // hide indicator and present it on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [activityView stopAnimating];
            [self presentViewController:activityVC animated:YES completion:nil];
        });
    });
}
-(void)dismissPopover{
  [popover dismissPopoverAnimated:YES];
}

-(IBAction)ActionClicked:(UIBarButtonItem *) sender{
   
    MenuTableViewController *contentViewController = [[MenuTableViewController alloc] init];
    contentViewController.card_id = _card_id;
    contentViewController.card_owner = card_owner;
    contentViewController.base_url = base_url;
    contentViewController.preferredContentSize = CGSizeMake(280, 100);
    popover = [[WYPopoverController alloc] initWithContentViewController:contentViewController];
    popover.delegate = (id<WYPopoverControllerDelegate>)self;
    
    [popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:WYPopoverArrowDirectionUp animated:YES];
}

@end
