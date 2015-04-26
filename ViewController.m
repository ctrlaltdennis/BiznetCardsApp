//
//  ViewController.m
//  BiznetCardsV2
//
//  Created by TheApp4U on 1/14/15.
//  Copyright (c) 2015 dta. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *txtUsername;

@property (weak, nonatomic) IBOutlet UITextField *txtPassword;

@property(readwrite, retain) UIView *inputAccessoryView;

@property (weak, nonatomic) IBOutlet UIScrollView *sV;

@property (weak, nonatomic) IBOutlet UIView *contentView;


@end

@implementation ViewController
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

- (void)viewDidLoad {
    [super viewDidLoad];
    _txtUsername.delegate = (id<UITextFieldDelegate>)self;
    _txtPassword.delegate = (id<UITextFieldDelegate>)self;
    
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
     name:UIKeyboardWillShowNotification object:self.view.window];
     
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
     name:UIKeyboardWillHideNotification object:self.view.window];
    
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,40)];
    
    
    [keyboardDoneButtonView setItems: [NSArray arrayWithObjects:
                                       [[UIBarButtonItem alloc] initWithTitle:@"Prev" style:UIBarButtonItemStyleBordered target:self action:@selector(previousTextField:)],
                                       
                                       [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextTextField:)],
                                       [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(keyDoneClicked:)],
                                       nil]];
    _txtUsername.inputAccessoryView = keyboardDoneButtonView;
    _txtPassword.inputAccessoryView = keyboardDoneButtonView;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


 - (void)keyboardWillShow:(NSNotification *)note
 {
     
     NSDictionary *userInfo = note.userInfo;
     /*
     NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
     UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
     */
     CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
     keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];

     CGFloat height = [UIScreen mainScreen].bounds.size.height;
     
     if (height <= 480){
         [_sV setContentOffset:
          CGPointMake(0, 150) animated:YES];
     }else if (height > 480 && height <= 568){
         [_sV setContentOffset:
          CGPointMake(0, 100) animated:YES];
     }else if (height > 568 && height <= 667){
         [_sV setContentOffset:
          CGPointMake(0, 10) animated:YES];
     }
 }
 
 - (void)keyboardWillHide:(NSNotification *)notif
 {
     [_sV setContentOffset:
      CGPointMake(0, -_sV.contentInset.top) animated:YES];
 
 }
 

-(void)viewDidLayoutSubviews{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    
    if (IS_OS_8_OR_LATER){
        NSLog(@"w = %f h = %f",width,height);
        [_contentView setFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
        //[_sV setFrame:CGRectMake(0,0,width, height)];
        //[_sV setContentSize:CGSizeMake(width, height)];
        
    }else{
        [_contentView setFrame:CGRectMake(0,0,self.view.bounds.size.width, self.view.bounds.size.height)];
        
    }
    
}

- (IBAction)nextTextField:(id)sender{
    if ([_txtUsername isFirstResponder]){
        [_txtUsername resignFirstResponder];
        [_txtPassword becomeFirstResponder];
    }else if ([_txtPassword isFirstResponder]){
        [_txtPassword resignFirstResponder];
    }
}


-(IBAction)previousTextField:(id)sender
{
    if ([_txtPassword isFirstResponder]){
        [_txtPassword resignFirstResponder];
        [_txtUsername becomeFirstResponder];
    }
}
-(IBAction)keyDoneClicked:(id)sender{
    [_sV setContentOffset:
     CGPointMake(0, -_sV.contentInset.top) animated:YES];
    
    [self.view endEditing:YES];
}
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    //This line dismisses the keyboard.
    [_sV setContentOffset:
     CGPointMake(0, -_sV.contentInset.top) animated:YES];

    [theTextField resignFirstResponder];
    //Your view manipulation here if you moved the view up due to the keyboard etc.
    return YES;
}

- (IBAction)btnLoginTapped:(id)sender {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicator.frame = CGRectMake(0, 0, 80, 80);
    indicator.backgroundColor =  [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    indicator.center = self.view.center;
    indicator.layer.cornerRadius = 10.0;
    [self.view addSubview:indicator];
    [indicator bringSubviewToFront:self.view];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    
    [indicator startAnimating];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    NSURL * url = [NSURL URLWithString:@"http://www.biznetcards.com/admin/shelllogin"];
    NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSString * params = [NSString stringWithFormat:@"user_name=%@&password=%@",
                         _txtUsername.text,_txtPassword.text];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask * dataTask =
        [defaultSession dataTaskWithRequest:urlRequest
         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSString *sData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                           
               if (error == nil){
                   
                   NSRange rangeValue = [sData rangeOfString:@"error" options:NSCaseInsensitiveSearch];
                   if (rangeValue.length == 0){
                       NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                       
                       NSUserDefaults *cardData = [NSUserDefaults standardUserDefaults];
                       [cardData setObject:text forKey:@"card"];
                       [cardData synchronize];
                       
                       [self performSegueWithIdentifier: @"showCardView" sender: self];
                       
                   }else{
                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"BiznetCards" message:@"Invalid username or password." delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil, nil];
                       [alert show];
                   }
               }else{
                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"BiznetCards" message:@"Error Occured While Connecting" delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil, nil];
                   [alert show];
               }
               [indicator stopAnimating];
           }];
    
    [dataTask resume];
    
}


@end
