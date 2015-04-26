//
//  NewInvoiceViewController.m
//  BiznetCards
//
//  Created by TheApp4U on 2/28/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "NewInvoiceViewController.h"

@interface NewInvoiceViewController ()

@end

@implementation NewInvoiceViewController
UIImageView *signatureImage;
UIImageView *tempSignatureImage;
UITextField *txtTrxNo;
UITextView *txtJobDescription;
UITextField *txtAmount;
UITextField *txtTotal;
UITextField *txtCustomerName;
UITextField *txtEmail;
UIView *contentView;
UIScrollView *sV;
UIButton *btnReset;
CGPoint lastPoint;
CGFloat red;
CGFloat green;
CGFloat blue;
CGFloat brush;
CGFloat opacity;
CGFloat kbHeight;
UIActivityIndicatorView *indicator;
UILabel *label;
BOOL mouseSwiped;
BOOL bottom;

- (void)viewDidLoad {
    red = 0.0/255.0;
    green = 0.0/255.0;
    blue = 0.0/255.0;
    brush = 1.0;
    opacity = 1.0;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [self prepareUI];
    [super viewDidLoad];
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)prepareUI{
    CGFloat y = 70;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height= [UIScreen mainScreen].bounds.size.height;
    if (height > 568){
        y = 90;
    }
    txtTrxNo = [[UITextField alloc] initWithFrame:CGRectMake(8,y,width-16,35)];
    txtTrxNo.backgroundColor = [UIColor whiteColor];
    txtTrxNo.layer.cornerRadius=5;
    txtTrxNo.placeholder = @"Invoice/Transaction No : ";
    txtTrxNo.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    y += 35;
    UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(8, y, width-16,28)];
    lbl.text = @"Job Description";
    lbl.textColor=[UIColor whiteColor];
    lbl.textAlignment = NSTextAlignmentLeft;
    lbl.font =[lbl.font fontWithSize:12];
    y += 28;
    if (height <= 480){
      txtJobDescription = [[UITextView alloc] initWithFrame:CGRectMake(8, y, width-16,80)];
        y += 90;
    }else{
      txtJobDescription = [[UITextView alloc] initWithFrame:CGRectMake(8, y, width-16,150)];
        y += 160;
    }
    txtJobDescription.backgroundColor = [UIColor whiteColor];
    txtJobDescription.layer.cornerRadius=5;
    txtJobDescription.font =[txtJobDescription.font fontWithSize:18];
    
    UILabel *lbl1 = [[UILabel alloc]initWithFrame:CGRectMake(8, y, 100,28)];
    lbl1.text = @"Amount Paid";
    lbl1.textColor=[UIColor whiteColor];
    lbl1.textAlignment = NSTextAlignmentLeft;
    lbl1.font =[lbl.font fontWithSize:14];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    paddingView.backgroundColor = [UIColor clearColor];
    
    
    txtAmount = [[UITextField alloc] initWithFrame:CGRectMake(105,y,width-116,30)];
    txtAmount.backgroundColor = [UIColor whiteColor];
    txtAmount.layer.cornerRadius=5;
    txtAmount.placeholder = @"0.00";
    txtAmount.textAlignment = NSTextAlignmentRight;
    txtAmount.rightView = paddingView;
    txtAmount.rightViewMode = UITextFieldViewModeAlways;
    txtAmount.keyboardType = UIKeyboardTypeDecimalPad;
    
    UIView *paddingView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    paddingView1.backgroundColor = [UIColor clearColor];
    y += 35;
    UILabel *lbl2 = [[UILabel alloc]initWithFrame:CGRectMake(8, y, 100,28)];
    lbl2.text = @"Total Inc. VAT";
    lbl2.textColor=[UIColor whiteColor];
    lbl2.textAlignment = NSTextAlignmentLeft;
    lbl2.font =[lbl.font fontWithSize:14];
    
    txtTotal = [[UITextField alloc] initWithFrame:CGRectMake(105,y,width-116,30)];
    txtTotal.backgroundColor = [UIColor whiteColor];
    txtTotal.layer.cornerRadius=5;
    txtTotal.placeholder = @"0.00";
    txtTotal.textAlignment = NSTextAlignmentRight;
    txtTotal.rightView = paddingView1;
    txtTotal.rightViewMode = UITextFieldViewModeAlways;
    txtTotal.enabled = NO;

    y+= 40;
    txtCustomerName = [[UITextField alloc] initWithFrame:CGRectMake(8,y,width-16,30)];
    txtCustomerName.backgroundColor = [UIColor whiteColor];
    txtCustomerName.layer.cornerRadius=5;
    txtCustomerName.placeholder = @"Customer Name";
    txtCustomerName.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    y+=35;
    txtEmail = [[UITextField alloc] initWithFrame:CGRectMake(8,y,width-16,30)];
    txtEmail.backgroundColor = [UIColor whiteColor];
    txtEmail.layer.cornerRadius=5;
    txtEmail.placeholder = @"Email Address";
    txtEmail.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0);
    txtEmail.keyboardType = UIKeyboardTypeEmailAddress;
    if (height > 568){
        y+=40;
        signatureImage = [[UIImageView alloc] initWithFrame:CGRectMake(8, y, width-16, height-(y+50))];
        signatureImage.backgroundColor = [UIColor whiteColor];
        tempSignatureImage =
        [[UIImageView alloc] initWithFrame:CGRectMake(8, y, width-16, height-(y+50))];
        tempSignatureImage.backgroundColor = [UIColor clearColor];
    }else{
        y+=40;
        signatureImage = [[UIImageView alloc] initWithFrame:CGRectMake(8, y, width-16, height-(y+10))];
        signatureImage.backgroundColor = [UIColor whiteColor];
        tempSignatureImage =
            [[UIImageView alloc] initWithFrame:CGRectMake(8, y, width-16, height-(y+10))];
        tempSignatureImage.backgroundColor = [UIColor clearColor];
    }

    UILabel *lbl3 = [[UILabel alloc]initWithFrame:CGRectMake(16, y, 100,28)];
    lbl3.text = @"Sign here : ";
    lbl3.textColor=[UIColor grayColor];
    lbl3.textAlignment = NSTextAlignmentLeft;
    lbl3.font =[lbl3.font fontWithSize:14];
    btnReset = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnReset.frame = CGRectMake(width-80, y-2, 100, 30);
    [btnReset setTitle:@"Clear" forState:UIControlStateNormal];
    [btnReset addTarget:self
               action:@selector(clickedReset:)
     forControlEvents:UIControlEventTouchUpInside];
    
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,width,40)];
    
    
    [keyboardDoneButtonView setItems: [NSArray arrayWithObjects:
                                       [[UIBarButtonItem alloc] initWithTitle:@"Prev" style:UIBarButtonItemStyleBordered target:self action:@selector(previousTextField:)],
                                       
                                       [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextTextField:)],
                                       [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(keyDoneClicked:)],
                                       nil]];
    txtTrxNo.inputAccessoryView = keyboardDoneButtonView;
    txtJobDescription.inputAccessoryView = keyboardDoneButtonView;
    txtAmount.inputAccessoryView = keyboardDoneButtonView;
    txtCustomerName.inputAccessoryView = keyboardDoneButtonView;
    txtEmail.inputAccessoryView = keyboardDoneButtonView;
    txtTrxNo.delegate = (id<UITextFieldDelegate>)self;
    txtAmount.delegate = (id<UITextFieldDelegate>)self;
    txtCustomerName.delegate = (id<UITextFieldDelegate>)self;
    txtEmail.delegate = (id<UITextFieldDelegate>)self;
    txtJobDescription.delegate = (id<UITextViewDelegate>)self;
    
    [txtAmount addTarget:self
                  action:@selector(txtAmountDidChange:)
        forControlEvents:UIControlEventEditingChanged];
    sV = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, y)];
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, y)];
    sV.scrollEnabled = NO;

    CGSize gsize = CGSizeMake(width, y);
    sV.contentSize = gsize;
    [contentView addSubview:txtTrxNo];
    [contentView addSubview:lbl];
    [contentView addSubview:txtJobDescription];
    [contentView addSubview:lbl1];
    [contentView addSubview:txtAmount];
    [contentView addSubview:lbl2];
    [contentView addSubview:txtTotal];
    [contentView addSubview:txtCustomerName];
    [contentView addSubview:txtEmail];
    [sV addSubview:contentView];
    [self.view addSubview:sV];
    [self.view addSubview:signatureImage];
    [self.view addSubview:tempSignatureImage];
    [self.view addSubview:lbl3];
    [self.view addSubview:btnReset];
    [sV setContentOffset:CGPointMake(0,60)];
    [self configureIndicator];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:tempSignatureImage];

}
-(void)keyboardWillShow:(NSNotification*)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    kbHeight = keyboardSize.height;
    
    [sV setFrame:CGRectMake(0, 0,
                            self.view.frame.size.width,
                            self.view.frame.size.height - kbHeight)];
    sV.scrollEnabled = YES;
    //[sV setContentOffset:CGPointMake(0,0)];
}
-(void)keyboardWillHide:(NSNotification*)notification {
    [sV setFrame:CGRectMake(0, 0, self.view.frame.size.width, contentView.frame.size.height)];
    [sV setContentOffset:CGPointMake(0,0)];
     sV.scrollEnabled = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:tempSignatureImage];
    
    UIGraphicsBeginImageContext(tempSignatureImage.frame.size);
    [tempSignatureImage.image drawInRect:CGRectMake(0,0,
                                                         tempSignatureImage.frame.size.width,
                                                         tempSignatureImage.frame.size.height)];
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush );
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, 1.0);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
    
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    tempSignatureImage.image = UIGraphicsGetImageFromCurrentImageContext();
    [tempSignatureImage setAlpha:opacity];
    UIGraphicsEndImageContext();
    
    lastPoint = currentPoint;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if(!mouseSwiped) {
        UIGraphicsBeginImageContext(tempSignatureImage.frame.size);
        [tempSignatureImage.image drawInRect:CGRectMake(0,0,
                                                            tempSignatureImage.frame.size.width,
                                                            tempSignatureImage.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, opacity);
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        CGContextFlush(UIGraphicsGetCurrentContext());
        tempSignatureImage.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContext(signatureImage.frame.size);
    [signatureImage.image drawInRect:CGRectMake(0,0,
                                                     signatureImage.frame.size.width,
                                                     signatureImage.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    [tempSignatureImage.image drawInRect:CGRectMake(0,0,
                                                         signatureImage.frame.size.width,
                                                         signatureImage.frame.size.height) blendMode:kCGBlendModeNormal alpha:opacity];
    signatureImage.image = UIGraphicsGetImageFromCurrentImageContext();
    tempSignatureImage.image = nil;
    UIGraphicsEndImageContext();
}

- (IBAction)clickedReset:(id)sender {
    signatureImage.image = nil;
}

-(IBAction)btnDone:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)nextTextField:(id)sender{
    if ([txtTrxNo isFirstResponder]){
        [txtTrxNo resignFirstResponder];
        [txtJobDescription becomeFirstResponder];
    }else if ([txtJobDescription isFirstResponder]){
        [txtJobDescription resignFirstResponder];
        [txtAmount becomeFirstResponder];
    }else if ([txtAmount isFirstResponder]){
        [txtAmount resignFirstResponder];
        [txtCustomerName becomeFirstResponder];
    }else if ([txtCustomerName isFirstResponder]){
        [txtCustomerName resignFirstResponder];
        [txtEmail becomeFirstResponder];
    }else if ([txtEmail isFirstResponder]){
        [self.view endEditing:YES];
    }
}


-(IBAction)previousTextField:(id)sender{
    if ([txtTrxNo isFirstResponder]){
        [self.view endEditing:YES];
    }else if ([txtJobDescription isFirstResponder]){
        [txtJobDescription resignFirstResponder];
        [txtAmount becomeFirstResponder];
    }else if ([txtAmount isFirstResponder]){
        [txtAmount resignFirstResponder];
        [txtJobDescription becomeFirstResponder];
    }else if ([txtCustomerName isFirstResponder]){
        [txtCustomerName resignFirstResponder];
        [txtAmount becomeFirstResponder];
    }else if ([txtEmail isFirstResponder]){
        [txtEmail resignFirstResponder];
        [txtCustomerName becomeFirstResponder];
    }
}


-(void)scrollViewDidScroll: (UIScrollView*)scrollView
{
    float scrollViewHeight = scrollView.frame.size.height;
    float scrollContentSizeHeight = scrollView.contentSize.height;
    float scrollOffset = scrollView.contentOffset.y;
    
    if (scrollOffset == 0)
    {
        bottom = NO;
    }
    else if (scrollOffset + scrollViewHeight == scrollContentSizeHeight)
    {
        bottom = YES;
    }
}

-(IBAction)keyDoneClicked:(id)sender{
    [self.view endEditing:YES];
}
- (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}
-(IBAction)txtAmountDidChange:(UITextField *)sender{
    CGFloat strAmount = (CGFloat)[sender.text floatValue];
    strAmount = strAmount + (strAmount * 0.21);
    txtTotal.text = [NSString stringWithFormat:@"%0.2f",strAmount];
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

-(IBAction)sendClicked:(id)sender{
    if (signatureImage.image != nil){
        NSString *imageString = [self encodeToBase64String:signatureImage.image];
       
        label.text = @"Sending ... ";
        [self showIndicator];
        
        NSString * card = [[NSUserDefaults standardUserDefaults]
                           objectForKey:@"card"];
        
        NSArray *cardJ = [NSJSONSerialization JSONObjectWithData:[card dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        NSString *card_id = [cardJ valueForKey:@"app_id"];
        NSString *email = [cardJ valueForKey:@"email"];
        NSString *name = [NSString stringWithFormat:@"%@ %@",[cardJ valueForKey:@"first_name"],[cardJ valueForKey:@"lastName"]];
        NSString *job_description = [txtJobDescription.text stringByReplacingOccurrencesOfString:@"\n"
                                                                 withString:@"<br />"];
        
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
        
        NSURL * url = [NSURL URLWithString:@"http://www.biznetcards.com/emailer/email_invoice/"];
        NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:url];
        
        NSString *subject = [NSString stringWithFormat:@"Invoice-%@",txtTrxNo.text];
        
        NSString * params = [NSString stringWithFormat:
                             @"card_id=%@&to=%@&cc=%@&subject=%@&description=%@&amount=%@&total=%@&from=%@&image=%@",
                             card_id,txtEmail.text,email,subject,job_description,txtAmount.text,txtTotal.text,name,imageString];
        
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
                 NSLog(@"%@",sData);
                 [message show];
             }
         }];
        
        [dataTask resume];
    }else{
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: @"BiznetCards"
                                                          message: @"Signature is needed before sending."
                                                         delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];

        [message show];
    }
}
-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
@end
