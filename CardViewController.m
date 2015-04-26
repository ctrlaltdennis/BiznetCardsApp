//
//  CardView.m
//  BiznetCardsV2
//
//  Created by TheApp4U on 1/24/15.
//  Copyright (c) 2015 dta. All rights reserved.
//
#import "CardViewController.h"
#import "AppDelegate.h"
#import "UIImage+ImageEffects.h"
#import "DTAUIActivity.h"
#import "WalletTableViewController.h"

@interface CardViewController() <UIGestureRecognizerDelegate>
  @property (nonatomic) CGFloat centerX;
@end

@implementation CardViewController
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

NSString *base_url = @"http://www.biznetcards.com/";
NSString *image = @"";
NSString *card_id = @"";
UILabel* label;
NSMutableData *imageData;
NSMutableData *qrData;
NSURLConnection * logoconnection;
NSURLConnection * qrconnection;
NSURL *url;
UIActivityIndicatorView *indicator = nil;
CLLocationManager *locationManager;
CLLocation *currentLocation;
UIView *modal;
UIImageView *vbg;
UIButton *button;
UIButton *buttonLogout;
UILabel *slogan;
UILabel *credits;
UIButton *biznetcards;
UIWebView *cardWebView;
UIImageView *logo;
UIViewController *vc;
NSString *lat,*lon;

BOOL CardLoaded = NO;
BOOL initialized = NO;

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    self.view.autoresizesSubviews = TRUE;
    cardWebView = [[UIWebView alloc] init ];
    cardWebView.frame = CGRectMake(0, 20,width,height-20);
    
    [self.view addSubview:cardWebView];
    modal = [[UIView alloc ] init];
    vbg = [[UIImageView alloc] init];
    slogan = [[UILabel alloc]init];
    credits = [[UILabel alloc]init];
    biznetcards  = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button  = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    buttonLogout = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    NSString * card = [[NSUserDefaults standardUserDefaults]
                   objectForKey:@"card"];
    
    //NSLog(@"%@",card);
    
    if (card != nil){
      
      [self configureIndicator];
      [self showIndicator];
        
       NSArray *cardJ = [NSJSONSerialization JSONObjectWithData:[card dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
       
       card_id  = [cardJ valueForKey:@"app_id"];
       AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        del.card_owner = [NSString stringWithFormat:@"%@ %@",[cardJ valueForKey:@"firstName"],[cardJ valueForKey:@"lastName"]];
       [cardWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",base_url,@"zappcards/",card_id]]]];
       [cardWebView setDelegate:(id<UIWebViewDelegate>)self];
        
       url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",base_url,@"zappcards/",card_id]];
        
       NSString *photo = [cardJ valueForKey:@"photo"];
        
       image = [NSString stringWithFormat:@"%@%@%@/%@",base_url,@"zapp_photos/",card_id,photo];
    
       image = [image stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
       
        NSLog(@"%@",image);
       NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:image] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
        logoconnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        NSString *qrurl =
                   [NSString stringWithFormat:@"%@%@%@%@",base_url,@"zapp_photos/qrcodes/",card_id,@".jpg"];
        
        NSURLRequest* request1 = [NSURLRequest requestWithURL:[NSURL URLWithString:qrurl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
       
        qrconnection = [[NSURLConnection alloc] initWithRequest:request1 delegate:self];

        //[self getLogoData];
        
        locationManager = [[CLLocationManager alloc] init];
        
        if(IS_OS_8_OR_LATER) {
            
            [locationManager requestWhenInUseAuthorization];
            
        }else{
            NSLog(@"was here");
            cardWebView.frame = CGRectMake(0, 18, width, height-18);
        }
        
        [locationManager setDistanceFilter:kCLDistanceFilterNone];
        [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [locationManager setDelegate:self];
        
        [locationManager startUpdatingLocation];
        
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted){
                NSLog(@"Granted Address Book Access");
            }
            
        });
        if (addressBookRef != nil)
          CFRelease(addressBookRef);
        UIScreenEdgePanGestureRecognizer * swipeEdge=[[UIScreenEdgePanGestureRecognizer alloc]initWithTarget:self action:@selector(swipeEdgeLeft:)];
        swipeEdge.edges = UIRectEdgeLeft;
        swipeEdge.delegate = self;
        [self.view addGestureRecognizer:swipeEdge];
        _centerX = self.view.bounds.size.width / 2;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
-(void)swipeEdgeLeft:(UIScreenEdgePanGestureRecognizer*)gesture
{
 //   UIView *view = [self.view hitTest:[gesture locationInView:gesture.view] withEvent:nil];
    
    if(UIGestureRecognizerStateBegan == gesture.state ||
       UIGestureRecognizerStateChanged == gesture.state) {
        CGPoint translation = [gesture translationInView:gesture.view];
        
        self.view.center = CGPointMake(_centerX + translation.x, self.view.center.y);
    } else {
        
        [UIView animateWithDuration:.3 animations:^{
            
            self.view.center = CGPointMake(_centerX, self.view.center.y);
        }];
    }
}

-(void)configureIndicator{
    
    indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    indicator.frame = CGRectMake(0, 0, 140, 120);
    indicator.backgroundColor =  [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    indicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    indicator.center = self.view.center;
    
    indicator.layer.cornerRadius = 10.0;
    [self.view addSubview:indicator];
    [indicator bringSubviewToFront:self.view];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0,85, 140, 20)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.font = [UIFont boldSystemFontOfSize:12.0f];
    
    label.numberOfLines = 1;
    
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.text = @"Loading...";
    label.textAlignment = NSTextAlignmentCenter;
    [indicator addSubview:label];
}
-(void)showIndicator{
    [indicator startAnimating];
    [label setHidden:NO];
}
-(void)hideIndicator{
    [indicator stopAnimating];
    [label setHidden:YES];
}

#pragma mark CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"location services not turned on");
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"didUpdateLocations %@", locations);
    currentLocation = [locations objectAtIndex:0];
    [locationManager stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLocation
          fromLocation:(CLLocation *)oldLocation
{
    currentLocation = newLocation;
    NSLog(@"new location %f, and old %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    [locationManager stopUpdatingLocation];
}

//Start Logo Pre Load


- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)incrementalData {
    if (theConnection == logoconnection){
      if (imageData==nil) { imageData = [[NSMutableData alloc] initWithCapacity:2048]; }
      [imageData appendData:incrementalData];
    }else if (theConnection == qrconnection){
       if (qrData==nil) { qrData = [[NSMutableData alloc] initWithCapacity:2048]; }
       [qrData appendData:incrementalData];
    }
}
- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
    if (theConnection == logoconnection){
       AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        del.logo = imageData;
       NSLog(@"Logo Download Complete");
    }
    else if (theConnection == qrconnection){
      NSLog(@"QR Download Complete");
      
    }
}
- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error{
    if (theConnection == logoconnection)
        NSLog(@"Error downloding logo.");
    else if (theConnection == qrconnection){
        NSLog(@"Error downloading qr code");
        
    }
}
//End Logo Pre Load

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *AppScheme = @"bizcard";
    
    if ([[request.URL absoluteString] isEqualToString:[NSString stringWithFormat:@"%@zappcards/%@/",base_url,card_id]]){
        return YES;
    }else if (CardLoaded &&
         ([request.URL.scheme isEqualToString:@"http"] ||
          [request.URL.scheme isEqualToString:@"https"])){
       
        
        if (IS_OS_8_OR_LATER){
            if ([[request.URL absoluteString] containsString:@"facebook.com/connect/"]){
                return YES;
            }else if([[request.URL absoluteString] containsString:[NSString stringWithFormat:@"%@zappcards/%@/",base_url,card_id]]){
                return YES;
            }else{
                [self inAppBrowser:[request.URL absoluteString]];
                return NO;
            }
        }else{
            if ([[request.URL absoluteString] rangeOfString:@"facebook.com/connect/"].length !=NSNotFound){
                return YES;
            }else if([[request.URL absoluteString] rangeOfString:[NSString stringWithFormat:@"%@zappcards/%@/",base_url,card_id]].length != NSNotFound){
                return YES;
            }else{
                [self inAppBrowser:[request.URL absoluteString]];
                return NO;
            }
        }
        
    }else if (![request.URL.scheme isEqualToString:AppScheme]) {
        return YES;
    }
    
    [self showIndicator];
    label.text = @"Please Wait...";
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
    [self hideIndicator];
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
                         "$(document).on('click','a[href=\"vCard.vcf\"]',function(e){"
                         " e.preventDefault();e.stopPropagation();"
                         " window.location='bizcard://save_contact';"
                         "});"
                         "$(document).find('.pageContainer').css('border-top','2px solid #ccc');"
                         "$(document).find('#credit-button').css({'top':'-5px'});"
                         "$(document).find('#credit-banner').remove();"
                         "$(document).off('click','#credit-button');"
                         "$(document).on('tap','#credit-button',function(e){"
                            "e.preventDefault();"
                            "e.stopPropagation();"
                            "$(document).find('#credit-button').show();"
                            "window.location='bizcard://system_menu';"
                        "});"
                        "$(document).off('click','#emailer');"
                        "$(document).on('click','#emailer',function(e){"
                           "e.preventDefault();"
                           "e.stopPropagation();"
                           "window.location='bizcard://emailer';"
                        "});"
                        "var btn = \"<a href='#' id='invoice' data-mini='true' class='ui-btn-left "
                        "           ui-link ui-btn ui-shadow ui-corner-all ui-mini' "
                        "data-role='button' role='button'>Invoice</a>\";"
                        "if ($(document).find('.nav-menu').find('a[href=\"#booking\"]').find('.menu-text').text() == 'JOB/QUOTE'){\n"
                        " $(document).find('#booking').find('.ui-title').html('QUOTE FORM');"
                        " $(document).find('#booking').find('.ui-header').prepend(btn);"
                        "}\n"
                        "$(document).off('click','#invoice');"
                        "$(document).on('tap','#invoice',function(e){"
                        "  e.preventDefault(); e.stopPropagation();"
                        "  window.location = 'bizcard://invoice';"
                        "});"
                        "$(document).off('click','#directions');"
                        "$(document).on('click','#directions',function(e){"
                            "e.preventDefault();"
                            "e.stopPropagation();"
                            "window.location = 'bizcard://directions';"       
                        "});"
                        "var sm = $(document).find('#sharing-menu');"
                        "var menu = sm.find('.ui-grid-b');"
                        "var lm = Math.floor($(window).width() / 2) - 145;"
                        "var sb = sm.find('.share-button');"
                        "sb.css({'margin-left':'-5px','width':'50px'});"
                        "sm.find('.ui-block-c').find('img').css({'margin-left':'-15px'});"
                        "if (sm.css('position') == 'absolute'){"
                        "  sm.css({'width':'290px',"
                        "  'left':'50%','margin-left':'-145px'});"
                        "}else if (sm.css('position')=='static'){"
                            "  sm.css({'width':'290px',"
                            "  'margin-left':lm + 'px'});"
                        "}"
                        "menu.removeClass('ui-grid-b').addClass('ui-grid-d');"
                        "menu.append('"
                        "<div class=\"ui-block-d\" style=\"text-align:center;\">"
                        "<span id=\"camera-btn\" class=\"icon camera\" "
                        "style=\"color:white;font-size:40px;margin-left:0px;margin-top:5px\">"
                        "</span></div>');"
                        "menu.append('"
                        "<div class=\"ui-block-e\" style=\"text-align:center;\">"
                        "<span id=\"wallet-btn\" class=\"icon credit-card\" "
                        "style=\"color:white;font-size:40px;margin-left:0px;margin-top:5px\">"
                        "</span></div>');"
                        "$(document).on('tap','#wallet-btn',function(){"
                        "   window.location = 'bizcard://wallet';"
                        "});"
                        "$(document).on('tap','#camera-btn',function(){"
                        "   window.location = 'bizcard://camera';"
                        "});";

    [webView stringByEvaluatingJavaScriptFromString:script];
    lat = [webView stringByEvaluatingJavaScriptFromString:@"window.lat;"];
    lon =[webView stringByEvaluatingJavaScriptFromString:@"window.lng;"];
    [self init_credits];
    CardLoaded = YES;
    NSLog(@"Card Loaded.");
    
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self hideIndicator];
}

-(void)inAppBrowser:(NSString*) url{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    del.strURL = url;
    UIViewController *vc1 = [sb instantiateViewControllerWithIdentifier:@"navInappBrowser"];
    [self showViewController:vc1 sender:self];
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:NO];
    [self becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:NO];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self resignFirstResponder];
    [super viewDidDisappear:NO];
}

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake )
    {
        [locationManager startUpdatingLocation];
        [vc dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake )
    {
        
        label.text = @"Fetching Shakers...";
        [self showIndicator];
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
        
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",base_url,@"shakers/save-shake"]];
        NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
        
        NSString *lng = [NSString stringWithFormat:@"%f",currentLocation.coordinate.longitude];
        NSString *lat = [NSString stringWithFormat:@"%f",currentLocation.coordinate.latitude];
        NSString * params = [NSString stringWithFormat:@"card_id=%@&lng=%@&lat=%@",
                             card_id,lng,lat];
        NSLog(@"params = %@",params);
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
          NSString *sData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                               
          if (error == nil){
            [self hideIndicator];
              
            NSArray *jData = [NSJSONSerialization JSONObjectWithData:[sData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
              
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            del.tableData = jData;
              NSLog(@"Before shakers");
            vc = [sb instantiateViewControllerWithIdentifier:@"shakersNavigator"];
            [self presentViewController:vc animated:YES completion:nil];
              
          }
                                                               
                                                               
          
         }];
        
        [dataTask resume];
        
        [locationManager startUpdatingLocation];
        NSLog(@"Shake Ended");
    }
}


-(void)share{
    NSString *textBody = @"Please click on the link below to open my business card details.\n";
    UIImage *imageToShare = [UIImage imageWithData:imageData];
    NSArray *itemsToShare = @[];
    
    DTAActivityItemMessage *message = [[DTAActivityItemMessage alloc] initWithPlaceholderItem:textBody];
    DTAActivityItemURL *surl = [[DTAActivityItemURL alloc] initWithPlaceholderItem:url];
    DTAActivityItemImage *img = [[DTAActivityItemImage alloc] initWithPlaceholderItem:imageToShare];
    
    message.message = textBody ;
    
    if (imageToShare != nil){
        itemsToShare = @[message,surl,img];
    }else{
        itemsToShare = @[message,surl];
    }

    dispatch_queue_t queue = dispatch_queue_create("openActivityIndicatorQueue", NULL);
    
    // send initialization of UIActivityViewController in background
    dispatch_async(queue, ^{
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare
            applicationActivities:nil];

        [activityVC setValue:@"Don't Print It - Phone It!" forKey:@"subject"];
        // when UIActivityViewController is finally initialized,
        // hide indicator and present it on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideIndicator];
            [self presentViewController:activityVC animated:YES completion:nil];
        });
    });
    
    
    //activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
    
    
    
}

-(void)share_qr_code{

    NSString *textBody = @"This QR Code contains my contact information.\n";
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
            [self hideIndicator];
            [self presentViewController:activityVC animated:YES completion:nil];
        });
    });
}


-(void)contactRoutine:(ABAddressBookRef)addressBookRef{
    NSString * card = [[NSUserDefaults standardUserDefaults]
                       objectForKey:@"card"];
    NSArray *cardj = [NSJSONSerialization JSONObjectWithData:[card dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    
    ABRecordRef contact = ABPersonCreate();
    NSString *first_name = [cardj valueForKey:@"first_name"];
    NSString *last_name = [cardj valueForKey:@"lastName"];
    NSString *middle_name = [cardj valueForKey:@"middleName"];
    NSString *mobile = [cardj valueForKey:@"mobile"];
    NSString *phone = [cardj valueForKey:@"phone"];
    NSString *street = [cardj valueForKey:@"street"];
    NSString *city = [cardj valueForKey:@"city"];
    NSString *state = [cardj valueForKey:@"state"];
    NSString *zipcode = [cardj valueForKey:@"zipcode"];
    NSString *website = [NSString stringWithFormat:@"%@zappcards/%@", base_url,card_id];
    NSString *email = [cardj valueForKey:@"email"];
    NSString *title = [cardj valueForKey:@"title"];
    NSString *org = [cardj valueForKey:@"org"];
    
    
    ABMutableMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABPersonPhoneProperty);
    ABMutableMultiValueRef address = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMutableMultiValueRef websites = ABMultiValueCreateMutable(kABPersonURLProperty);
    ABMutableMultiValueRef emails = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    
    ABRecordSetValue(contact, kABPersonFirstNameProperty, (__bridge CFStringRef)first_name, nil);
    ABRecordSetValue(contact, kABPersonLastNameProperty, (__bridge CFStringRef)last_name, nil);
    ABRecordSetValue(contact, kABPersonMiddleNameProperty, (__bridge CFStringRef)middle_name, nil);
    
    ABRecordSetValue(contact, kABPersonOrganizationProperty, (__bridge CFStringRef)org, nil);
    ABRecordSetValue(contact, kABPersonJobTitleProperty, (__bridge CFStringRef)title, nil);
    
    
    
    ABMultiValueAddValueAndLabel(phoneNumbers,(__bridge CFStringRef)phone,
                                 kABWorkLabel, nil);
    ABMultiValueAddValueAndLabel(phoneNumbers,(__bridge CFStringRef)mobile,
                                 kABPersonPhoneMobileLabel, nil);
    ABRecordSetValue(contact, kABPersonPhoneProperty, phoneNumbers, NULL);
    
    NSDictionary *values;
    
    values = [NSDictionary dictionaryWithObjectsAndKeys:
              street,(NSString *)kABPersonAddressStreetKey,
              city,(NSString *)kABPersonAddressCityKey,
              state,(NSString *)kABPersonAddressStateKey,
              zipcode,(NSString *)kABPersonAddressZIPKey,
              nil];
    ABMultiValueAddValueAndLabel(address,(__bridge CFDictionaryRef)values,
                                 kABWorkLabel, nil);
    ABRecordSetValue(contact, kABPersonAddressProperty, address, NULL);
    
    ABMultiValueAddValueAndLabel(emails,(__bridge CFStringRef)email,
                                 kABWorkLabel, nil);
    ABRecordSetValue(contact, kABPersonEmailProperty, emails, NULL);
    
    ABMultiValueAddValueAndLabel(websites,(__bridge CFStringRef)website, kABPersonHomePageLabel, NULL);
    ABRecordSetValue(contact, kABPersonURLProperty, websites, nil);
    
    NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    
    BOOL found = NO;
    
    for (id record in allContacts){
        
        ABRecordRef thisContact = (__bridge ABRecordRef)record;
        NSString * lastname = (__bridge NSString *)ABRecordCopyValue( thisContact, kABPersonLastNameProperty );
        NSString * first_name = (__bridge NSString *)ABRecordCopyValue( thisContact, kABPersonFirstNameProperty );
        
        NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
        ABMultiValueRef phones = ABRecordCopyValue(thisContact,kABPersonPhoneProperty);
        for(CFIndex i=0;i<ABMultiValueGetCount(phones);++i) {
            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, i);
            NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
            
            [phoneNumbers addObject:phoneNumber];
        }
        if (phoneNumbers.count > 0){
            NSLog(@"%@",phoneNumbers);
            NSLog(@"%@ %@ ",mobile,[phoneNumbers objectAtIndex:0]);
            if ([lastname isEqualToString:last_name] && [first_name isEqualToString:first_name] &&
                ([mobile isEqualToString:[phoneNumbers objectAtIndex:0]] || [phone isEqualToString: [phoneNumbers objectAtIndex:0]])){
                NSLog(@"Found some shit");
                found = YES;
                break;
                
            }
        }
        
    }
    
    if (!found){
        UIAlertView *alert1= [[UIAlertView alloc] initWithTitle: @"BiznetCards" message: @"Successfuly Saved Contact." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
        [alert1 show];
        ABAddressBookAddRecord(addressBookRef, contact, nil);
        ABAddressBookSave(addressBookRef, nil);
        [self hideIndicator];
    }else{
        NSLog(@"Now I'm Here.");
        UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle: @"BiznetCards" message: @"Contact Already Exists." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
        [alert1 show];
        [self hideIndicator];
    }
    CFRelease(contact);
}

-(void)save_contact{
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        
       [self contactRoutine:addressBookRef];
    }
    
    if (addressBookRef != nil){
       CFRelease(addressBookRef);
    }else{
        [self hideIndicator];
        UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle: @"BiznetCards"
                                                          message: @"Contacts access needed, please go to settings, select BiznetCards, and turn on the Contacts permission." delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
        [alert1 show];    }
       
    
}

-(void)biznetcardsClick: (UIButton*)sender{
    NSString *url = [NSString stringWithFormat:@"%@",base_url];
    NSLog(@"%@",url);
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

-(void)init_credits{
    CGFloat width= [UIScreen mainScreen].bounds.size.width;
    CGFloat height= [UIScreen mainScreen].bounds.size.height;
    logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon.png"]];
    logo.frame = CGRectMake((width / 2)-50,(height /2) - 190,100,100);
    
    slogan.frame = CGRectMake((width/2)-125,(height/2)-50,250,100);
    
    slogan.text = @"Please save our forests\nDon't Print It - Phone It!";
    slogan.lineBreakMode =NSLineBreakByWordWrapping;
    slogan.numberOfLines = 0;
    slogan.textColor = [UIColor whiteColor];
    slogan.textAlignment = NSTextAlignmentCenter;
    slogan.font = [UIFont boldSystemFontOfSize:21.0f];


    credits.frame = CGRectMake((width/2)-125,(height/2)+20,250,100);
    
    credits.text = @"Fone2fone Technology Limited\nLynton House\n7-12 Tavistock Square\nLondon WC1H 9BQ";
    credits.lineBreakMode =NSLineBreakByWordWrapping;
    credits.numberOfLines = 0;
    
    credits.textAlignment = NSTextAlignmentCenter;
    credits.font = [UIFont boldSystemFontOfSize:14.0f];
    credits.textColor = [UIColor whiteColor];
    
    vbg = [[UIImageView alloc] init];
    vbg.frame= CGRectMake(0,0,width,height);
    
    
    biznetcards.frame =CGRectMake((width/2)-125, (height / 2)-60, 250, 20);
    biznetcards.titleLabel.shadowColor = [UIColor grayColor];
    [biznetcards setTitle:@"www.biznetcards.com" forState:UIControlStateNormal];
    biznetcards.titleLabel.textColor =[UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0];
    biznetcards.titleLabel.font = [UIFont boldSystemFontOfSize:21.0f];
    
    [button setTitle:@"Close" forState:UIControlStateNormal];
    [buttonLogout setTitle:@"Logout" forState:UIControlStateNormal];
    
    button.frame = CGRectMake(self.view.bounds.size.width-110,height-50,100,40);
    buttonLogout.frame = CGRectMake(10,height-50,100,40);
    
    //button.center= self.view.center;
    button.backgroundColor = [UIColor blackColor];
    //button.titleLabel.textColor = [UIColor whiteColor];
    button.layer.cornerRadius = 10;
    
    buttonLogout.backgroundColor = [UIColor blackColor];
    //buttonLogout.titleLabel.textColor = [UIColor whiteColor];
    buttonLogout.layer.cornerRadius = 10;

    [button addTarget:self
               action:@selector(closeClick:)
     forControlEvents:UIControlEventTouchUpInside];
    [buttonLogout addTarget:self
                     action:@selector(logoutClick:)
           forControlEvents:UIControlEventTouchUpInside];
    [biznetcards addTarget:self
                     action:@selector(biznetcardsClick:)
           forControlEvents:UIControlEventTouchUpInside];
    
    vbg.image = [vbg.image applyLightEffect];
    vbg.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    vbg.alpha = 1;
    [modal insertSubview:vbg atIndex:0];
    [modal insertSubview:logo atIndex:1];
    [modal insertSubview:slogan atIndex:1];
    [modal insertSubview:credits atIndex:1];
    [modal insertSubview:button atIndex:2];
    [modal insertSubview:buttonLogout atIndex:2];
    [modal insertSubview:biznetcards atIndex:2];
    
}

-(void)system_menu{
    
   if (!initialized){
        CGRect rect = [self.view bounds];
        UIGraphicsBeginImageContextWithOptions(rect.size,YES,0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [self.view.layer renderInContext:context];
        UIImage *bg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
       if (bg != nil){
         [vbg setImage:bg];
         vbg.image = [vbg.image applyDarkEffect];
         initialized = YES;
       }
    }
    [self.view addSubview:modal];
    [modal bringSubviewToFront:self.view];
    modal.frame = CGRectMake(0,0,self.view.bounds.size.width,-self.view.bounds.size.height);
    modal.userInteractionEnabled = YES;
    button.userInteractionEnabled=YES;
    [UIView animateWithDuration:0.25 animations:^{
       modal.frame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);
    }];
    
    modal.autoresizesSubviews = YES;
  
    [self hideIndicator];
}

-(void)logoutClick:(UIButton*)sender{
    NSLog(@"Fucking clicked logout");
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Do You want to logout?"
                                                             delegate:(id<UIActionSheetDelegate>)self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Logout"
                                                    otherButtonTitles:nil];
    [actionSheet showInView:modal];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0){
        CardLoaded = NO;
        initialized = NO;
        cardWebView.delegate = nil;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"card"];
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"loginView"];
        [[[[UIApplication sharedApplication] delegate] window] setRootViewController:vc];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation duration:(NSTimeInterval)duration {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height= [UIScreen mainScreen].bounds.size.height;
    CGFloat temp = 0;
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation ==
        UIInterfaceOrientationLandscapeRight) {
        if (!IS_OS_8_OR_LATER){
          temp = width;
          width = height;
          height = temp;
        }
    }
    vbg.frame = CGRectMake(0,0,width,height);
    button.frame = CGRectMake(width-110,height-50,100,40);
    buttonLogout.frame = CGRectMake(10,height-50,100,40);
    
    if (width < height){
        biznetcards.frame =CGRectMake((width/2)-125, (height/2)-55, 250, 20);
        slogan.frame = CGRectMake((width/2)-125,(height/2)-50,250,100);
        credits.frame = CGRectMake((width/2)-125,(height/2)+20,250,100);
        logo.frame = CGRectMake((width / 2)-50,(height /2) - 185,100,100);
        cardWebView.frame = CGRectMake(0,18,width,height-18);
    }else{
        biznetcards.frame =CGRectMake((width/2)-125, (height/2)-15, 250, 20);
        slogan.frame = CGRectMake((width/2)-125,(height/2)-10,250,100);
        credits.frame = CGRectMake((width/2)-125,(height/2)+55,250,100);
        logo.frame = CGRectMake((width / 2)-50,(height /2) - 135,100,100);
        cardWebView.frame = CGRectMake(0,0,width,height);
    }
}

-(void)closeClick:(UIButton*)sender{
    CGFloat width= [UIScreen mainScreen].bounds.size.width;
    CGFloat height= [UIScreen mainScreen].bounds.size.height;
    [UIView  animateWithDuration:0.25 animations:^{
        if (width > height)
            modal.frame = CGRectMake(0,0,height,-width);
        else
            modal.frame = CGRectMake(0,0,width,-height);
    }];
}

-(void)emailer{
    [self hideIndicator];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *emailer = [sb instantiateViewControllerWithIdentifier:@"emailNavigator"];
    
    [self presentViewController:emailer animated:YES completion:nil];
    
}
-(void)directions{

    NSString *from = [NSString stringWithFormat:@"%f,%f",currentLocation.coordinate.latitude,currentLocation.coordinate.longitude];
    NSString *to = [NSString stringWithFormat:@"%@,%@",lat,lon];
    NSLog(@" to %@",to);
    NSString *url = [NSString stringWithFormat: @"http://maps.apple.com/?daddr=%@&saddr=%@",
                    [from stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [to stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    [self hideIndicator];
}
-(void)invoice{
    [self hideIndicator];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *invoices = [sb instantiateViewControllerWithIdentifier:@"showInvoices"];
    
    [self presentViewController:invoices animated:YES completion:nil];
    
}

-(void)wallet{
    [self hideIndicator];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"navWallet"];
    [self presentViewController:vc animated:YES completion:nil];
    
}
-(void)camera{
    [self hideIndicator];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"cameraView"];
    [self presentViewController:vc animated:YES completion:nil];
    
}

@end