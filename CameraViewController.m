//
//  CameraViewController.m
//  BiznetCards
//
//  Created by TheApp4U on 3/15/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "CameraViewController.h"
#import "AppDelegate.h"

@interface CameraViewController ()

@property (weak, nonatomic) IBOutlet UIButton *btnCamera;

@end

@implementation CameraViewController
UIImageView *imageView;
UIImageView * ivWatermark;
UIScrollView  *scrollView;
UITextView *commentTextView;
UIActivityIndicatorView *activityView;
CGFloat kbHeight;

BOOL first_load = YES;
#define WATERMARK_ALPHA = 0.8;
- (void)viewDidLoad {
    [super viewDidLoad];

   
    CGFloat x = (self.view.frame.size.width / 2) - 160;
    CGFloat y =((self.view.frame.size.height-70) / 2) - 213.5;
    imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(x, y, 320, 427);
    imageView.backgroundColor = [UIColor blackColor];
    
    scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height-70)];
    //scrollView.backgroundColor = [UIColor whiteColor];

 
    scrollView.contentSize = CGSizeMake(320,427);
    //scrollView.scrollEnabled = NO;
   
    [scrollView addSubview:imageView];
    [scrollView addSubview:commentTextView];
    [self.view addSubview:scrollView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
  if (first_load){
    [self.btnCamera sendActionsForControlEvents:UIControlEventTouchUpInside];
    first_load = NO;
  }
}

-(void)cameraRoutine{
    // Create the image picker controller
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])  {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];

        imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
        imagePicker.cameraViewTransform = CGAffineTransformScale(imagePicker.cameraViewTransform, 1.24299, 1.24299);
        imagePicker.allowsEditing = NO;
        imagePicker.delegate = self;
        AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];

        ivWatermark = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithData:del.logo]];
        CGSize kMaxImageViewSize = {.width = 75, .height = 75};
        
        CGSize imageSize = ivWatermark.image.size;
        CGFloat aspectRatio = imageSize.width / imageSize.height;
        CGRect frame = ivWatermark.frame;
        frame.origin.x = 5;
        frame.origin.y = self.view.frame.size.height-120;
        if (kMaxImageViewSize.width / aspectRatio <= kMaxImageViewSize.height) {
            frame.size.width = kMaxImageViewSize.width;
            frame.size.height = frame.size.width / aspectRatio;
        } else {
            frame.size.height = kMaxImageViewSize.height;
            frame.size.width = frame.size.height * aspectRatio;
        }
        
        ivWatermark.alpha = 0.8;
        ivWatermark.frame = frame;
        imagePicker.cameraOverlayView = ivWatermark;

        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}
- (IBAction)btnCamera:(id)button
{
    [self cameraRoutine];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    CGSize kMaxImageViewSize = {.width = 150, .height = 150};
    CGSize imageSize = ivWatermark.image.size;
    CGFloat aspectRatio = imageSize.width / imageSize.height;
    CGRect frame = ivWatermark.frame;
    frame.origin.x = 10;
    frame.origin.y = self.view.frame.size.height + 160;
    if (kMaxImageViewSize.width / aspectRatio <= kMaxImageViewSize.height) {
        frame.size.width = kMaxImageViewSize.width;
        frame.size.height = frame.size.width / aspectRatio;
    } else {
        frame.size.height = kMaxImageViewSize.height;
        frame.size.width = frame.size.height * aspectRatio;
    }

    UIGraphicsBeginImageContext(CGSizeMake(640, 854));
    [(UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage] drawInRect:CGRectMake(0, 0, 640, 854)];
    AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [[UIImage imageWithData:del.logo]  drawInRect:frame blendMode:kCGBlendModeNormal alpha:0.8];
   
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDateFormatter *dateFormatter1 = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter1 setDateFormat:@"MMMM dd, YYYY"];
    
    NSString *currentTime = [dateFormatter stringFromDate:today];
    NSString *currentDate = [dateFormatter1 stringFromDate:today];
    
    NSString *text = [NSString stringWithFormat:@"Sent from %@ BiznetCard %@ %@",del.card_owner,currentTime,currentDate];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    [text drawInRect:CGRectMake(10, 835, 630, 25)  withAttributes:
       @{ NSFontAttributeName: [UIFont systemFontOfSize:14],
          NSForegroundColorAttributeName: [UIColor whiteColor],
          NSBackgroundColorAttributeName:[UIColor blackColor]
        }];
    [picker dismissViewControllerAnimated:YES completion:nil];

    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    imageView.image = image;
    UIGraphicsEndImageContext();

    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    

}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"Error %@",error);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)closeClicked:(id)sender{
    first_load = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)sharePhoto:(id)sender{
 \
    UIImage *imageToShare = imageView.image;
    NSArray *itemsToShare = @[];
    if (imageToShare != nil){
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self.view addSubview: activityView];
        activityView.frame = CGRectMake(0, 0, 120, 120);
        activityView.backgroundColor =  [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        activityView.center = self.view.center;
        activityView.layer.cornerRadius = 10.0;
        [activityView startAnimating];
        
        itemsToShare = @[imageToShare];
        
        
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
    }else{
        UIAlertView *message = [[UIAlertView alloc] initWithTitle: @"BiznetCards" message: @"No picture to share" delegate:nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
        [message show];
    }
}

-(IBAction)keyDoneClicked:(id)sender{
    [self.view endEditing:YES];
}

-(void)keyboardWillShow:(NSNotification*)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    kbHeight = keyboardSize.height;
    
    [scrollView setFrame:CGRectMake(0, 0,
                            self.view.frame.size.width,
                            self.view.frame.size.height - kbHeight)];
    //scrollView.scrollEnabled = YES;
    
}

-(void)keyboardWillHide:(NSNotification*)notification {
    [scrollView setFrame:CGRectMake(0, 20, self.view.frame.size.width,self.view.frame.size.height-40)];
    [scrollView setContentOffset:CGPointMake(0,0)];
    //scrollView.scrollEnabled = NO;
}
-(BOOL)textViewDidBeginEditing:(UITextView *)textView{
    UIScrollView* v = (UIScrollView*) self.view ;
    CGPoint pt ;
    
    CGRect rc = [textView bounds];
    
    rc = [textView convertRect:rc toView:v];
    pt = rc.origin ;
    pt.x = 0 ;
    pt.y -= textView.frame.size.height;
    pt.y -= (kbHeight / 2);
    [scrollView setContentOffset:pt animated:YES];
    return YES;
}
- (BOOL) textViewShouldBeginEditing:(UITextView *)textView{
    
    if ([commentTextView.text isEqualToString:@"Type comment here"]){
      commentTextView.text = @"";
      commentTextView.textColor = [UIColor blackColor];
        
    }
    return YES;
}

-(void) textViewDidChange:(UITextView *)textView
{
    
    if(commentTextView.text.length == 0){
        commentTextView.textColor = [UIColor lightGrayColor];
        commentTextView.text = @"Type comment here";
        [commentTextView resignFirstResponder];
    }
}

@end
