//
//  EmailViewController.m
//  BiznetCardsV2
//
//  Created by TheApp4U on 2/13/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "EmailViewController.h"

@interface EmailViewController ()

@end

@implementation EmailViewController
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
NSString *button;
UITextField *txtTo;
UITextField *txtCC;
UITextField *txtSubject;
UITextView *txtBody;
UIButton *addTo;
UIButton *addCC;
UIScrollView *sV;
UIView *uV;
NSString *base_url;
UIToolbar* keyboardDoneButtonView;
CGFloat keyHeight;
UIActivityIndicatorView *indicator;
UILabel* label;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
    [self configureIndicator];
    
     base_url = @"http://www.biznetcards.com/";
    
 
}
     

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doneClicked:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)AddToClicked:(id)sender {
    button = @"to";
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = (id<ABPeoplePickerNavigationControllerDelegate>)self;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)AddCCClicked:(id)sender {
    button = @"cc";
    ABPeoplePickerNavigationController *picker =
    [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = (id<ABPeoplePickerNavigationControllerDelegate>)self;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
{
    NSString *emailAddress = @"no email address";
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (emails)
    {
        if (ABMultiValueGetCount(emails) > 0)
        {
            CFIndex index = 0;
            emailAddress = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, index));
        }
        CFRelease(emails);
    }
    if ([emailAddress isEqualToString:@"no email address"]){
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: @"BiznetCards" message: @"No email address" delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
        [message show];
        return;
    }
    if ([button isEqualToString:@"to"]){
        if (![txtTo.text containsString:emailAddress])
          txtTo.text = [NSString stringWithFormat:@"%@%@,",txtTo.text,emailAddress];
        
    }else if ([button isEqualToString:@"cc"]){
        if (![txtCC.text containsString:emailAddress])
            txtCC.text = [NSString stringWithFormat:@"%@%@,",txtCC.text,emailAddress];
    }
    
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
#pragma clang diagnostic pop
{
    
    NSString *emailAddress = @"no email address";
    ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (emails)
    {
        if (ABMultiValueGetCount(emails) > 0)
        {
            CFIndex index = 0;
            emailAddress = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails, index));
        }
        CFRelease(emails);
    }
    
    if ([emailAddress isEqualToString:@"no email address"]){
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: @"BiznetCards" message: @"No email address" delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
        [message show];
        
    }
    if ([button isEqualToString:@"to"]){
        if ([txtTo.text rangeOfString:@"bla"].location == NSNotFound) {
              txtTo.text = [NSString stringWithFormat:@"%@%@,",txtTo.text,emailAddress];
        }
    }else if ([button isEqualToString:@"cc"]){
        
        if ([txtCC.text rangeOfString:emailAddress].location == NSNotFound)
            txtCC.text = [NSString stringWithFormat:@"%@%@,",txtCC.text,emailAddress];
        
    }
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
    return NO;
}

-(IBAction)btnSend:(id)sender{
    label.text = @"Sending ... ";
    [self showIndicator];
    
    NSString * card = [[NSUserDefaults standardUserDefaults]
                       objectForKey:@"card"];
    
    NSArray *cardJ = [NSJSONSerialization JSONObjectWithData:[card dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    NSString *card_id = [cardJ valueForKey:@"app_id"];
    
    NSString *body = [txtBody.text stringByReplacingOccurrencesOfString:@"\n"
                                               withString:@"<br />"];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",base_url,@"admin/send-email-app"]];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSString * params = [NSString stringWithFormat:@"card_id=%@&to=%@&cc=%@&subject=%@&body=%@",
                         card_id,txtTo.text,txtCC.text,txtSubject.text,body];
    NSLog(@"params = %@",params);
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask * dataTask =
     [defaultSession
        dataTaskWithRequest:urlRequest
        completionHandler:
        ^(NSData *data, NSURLResponse *response, NSError *error) {
           NSString *sData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self hideIndicator];
            if (error == nil){
                [self.view endEditing:YES];
                UIAlertView *message = [[UIAlertView alloc] initWithTitle: @"BiznetCards"
                                                                  message: sData
                                                                 delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
                 [message show];
            }
    }];
    
    [dataTask resume];
    
    
}

-(void)textViewDidBeginEditing:(UITextField *)textView {
    UIScrollView* v = (UIScrollView*) self.view ;
    CGPoint pt ;
    
    CGRect rc = [textView bounds];
    
    rc = [textView convertRect:rc toView:v];
    pt = rc.origin ;
    pt.x = 0 ;
    pt.y -= 100 ;
    [sV setContentOffset:pt animated:YES];
    
    return;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    /* scroll so that the field appears in the viewable portion of screen when the keyboard is out */
    
    UIScrollView* v = (UIScrollView*) self.view ;
    CGPoint pt ;
    
        CGRect rc = [textField bounds];
        rc = [textField convertRect:rc toView:v];
        pt = rc.origin ;
        pt.x = 0 ;
        pt.y -= 130 ;
        [sV setContentOffset:pt animated:YES];
    
    
    return;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    //This line dismisses the keyboard.
    [theTextField resignFirstResponder];
    //Your view manipulation here if you moved the view up due to the keyboard etc.
    return YES;
}

-(void)initView{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    if (IS_OS_8_OR_LATER)
      sV = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,width,height)];
    else
      sV = [[UIScrollView alloc] initWithFrame:CGRectMake(0,65,width,height)];
    [sV setContentSize:CGSizeMake(width, height)];
    txtTo = [[UITextField alloc] init];
    txtTo.frame = CGRectMake(8, 8,width-50, 44);
    txtTo.placeholder = @"To:";
    
    txtTo.borderStyle = UITextBorderStyleRoundedRect;
    txtTo.font = [UIFont systemFontOfSize:15];
    txtTo.autocorrectionType = UITextAutocorrectionTypeNo;
    txtTo.keyboardType = UIKeyboardTypeEmailAddress;
    txtTo.returnKeyType = UIReturnKeyDefault;
    txtTo.clearButtonMode = UITextFieldViewModeWhileEditing;
    txtTo.delegate = (id<UITextFieldDelegate>)self;
    txtTo.backgroundColor = [UIColor whiteColor];
    txtCC = [[UITextField alloc] init];
    txtCC.frame = CGRectMake(8, 60,width-50, 44);
    txtCC.placeholder = @"CC:";
    
    txtCC.borderStyle = UITextBorderStyleRoundedRect;
    txtCC.font = [UIFont systemFontOfSize:15];
    txtCC.autocorrectionType = UITextAutocorrectionTypeNo;
    txtCC.keyboardType = UIKeyboardTypeDefault;
    txtCC.returnKeyType = UIReturnKeyDefault;
    txtCC.clearButtonMode = UITextFieldViewModeWhileEditing;
    txtCC.delegate = (id<UITextFieldDelegate>)self;
    txtCC.backgroundColor = [UIColor whiteColor];
    txtSubject = [[UITextField alloc] init];
    txtSubject.frame = CGRectMake(8, 112,width-20, 44);
    txtSubject.placeholder = @"Subject";
    
    txtSubject.borderStyle = UITextBorderStyleRoundedRect;
    txtSubject.font = [UIFont systemFontOfSize:15];
    txtSubject.autocorrectionType = UITextAutocorrectionTypeNo;
    txtSubject.keyboardType = UIKeyboardTypeDefault;
    txtSubject.returnKeyType =UIReturnKeyDefault;
    txtSubject.clearButtonMode = UITextFieldViewModeWhileEditing;
    txtSubject.delegate = (id<UITextFieldDelegate>)self;
    txtSubject.backgroundColor = [UIColor whiteColor];
    addTo = [UIButton buttonWithType:UIButtonTypeContactAdd] ;
    addTo.frame =CGRectMake(width-40,8,40, 40);
    [addTo addTarget:self
               action:@selector(AddToClicked:)
     forControlEvents:UIControlEventTouchUpInside];
    
    addCC = [UIButton buttonWithType:UIButtonTypeContactAdd] ;
    addCC.frame =CGRectMake(width-40,60,40, 40);
    [addCC addTarget:self
              action:@selector(AddCCClicked:)
    forControlEvents:UIControlEventTouchUpInside];
    
    txtBody = [[UITextView alloc] initWithFrame:CGRectMake(8, 165,width-20, 250)];
    txtBody.layer.borderWidth = 0.5;
    txtBody.layer.borderColor = [[UIColor grayColor] CGColor];
    txtBody.layer.cornerRadius = 10;
    txtBody.delegate = (id<UITextViewDelegate>)self;
    txtBody.backgroundColor =  [UIColor whiteColor];
    [sV addSubview:txtTo];
    [sV addSubview:addTo];
    [sV addSubview:txtCC];
    [sV addSubview:addCC];
    [sV addSubview:txtSubject];
    [sV addSubview:txtBody];
    
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,width,40)];
    
    
    [keyboardDoneButtonView setItems: [NSArray arrayWithObjects:
                                       [[UIBarButtonItem alloc] initWithTitle:@"Prev" style:UIBarButtonItemStyleBordered target:self action:@selector(previousTextField:)],
                                
                                       [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextTextField:)],
                                       [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(keyDoneClicked:)],
                                nil]];
    //[keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, nil]];
    txtTo.inputAccessoryView = keyboardDoneButtonView;
    txtCC.inputAccessoryView = keyboardDoneButtonView;
    txtSubject.inputAccessoryView = keyboardDoneButtonView;
    txtBody.inputAccessoryView = keyboardDoneButtonView;
    [self.view addSubview:sV];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation duration:(NSTimeInterval)duration {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height= [UIScreen mainScreen].bounds.size.height;
    
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation ==
        UIInterfaceOrientationLandscapeRight) {
        if (IS_OS_8_OR_LATER){
            sV.frame = CGRectMake(0,0,width,height);
            NSLog(@"Testing");
            txtTo.frame = CGRectMake(8, 8,width-50, 44);
            txtCC.frame = CGRectMake(8, 60,width-50, 44);
            addTo.frame = CGRectMake(width-40,8,40, 40);
            addCC.frame = CGRectMake(width-40,60,40, 40);
            txtSubject.frame = CGRectMake(8, 112,width-20, 44);
            txtBody.frame = CGRectMake(8, 165,width-20, 250);
        }else{
            sV.frame = CGRectMake(0,65,width,height);
            NSLog(@"Testing");
            txtTo.frame = CGRectMake(8, 8,width-50, 44);
            txtCC.frame = CGRectMake(8, 60,width-50, 44);
            addTo.frame = CGRectMake(width-40,8,40, 40);
            addCC.frame = CGRectMake(width-40,60,40, 40);
            txtSubject.frame = CGRectMake(8, 112,width-20, 44);
            txtBody.frame = CGRectMake(8, 165,width-20, 250);
        
        }
    }
    
    
}
- (IBAction)nextTextField:(id)sender{
    if ([txtTo isFirstResponder]){
        [txtTo resignFirstResponder];
        [txtCC becomeFirstResponder];
    }else if ([txtCC isFirstResponder]){
        [txtCC resignFirstResponder];
        [txtSubject becomeFirstResponder];
    }else if ([txtSubject isFirstResponder]){
        [txtSubject resignFirstResponder];
        [txtBody becomeFirstResponder];
    }
}


-(IBAction)previousTextField:(id)sender
{
    if ([txtCC isFirstResponder]){
        [txtCC resignFirstResponder];
        [txtTo becomeFirstResponder];
    }else if ([txtSubject isFirstResponder]){
        [txtSubject resignFirstResponder];
        [txtCC becomeFirstResponder];
    }else if ([txtBody isFirstResponder]){
        [txtBody resignFirstResponder];
        [txtSubject becomeFirstResponder];
    }
}
-(IBAction)keyDoneClicked:(id)sender{
    [sV setContentOffset:
     CGPointMake(0, -sV.contentInset.top) animated:YES];
    
   [self.view endEditing:YES];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
