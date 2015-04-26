//
//  OCRViewController.m
//  BiznetCards
//
//  Created by TheApp4U on 4/9/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "OCRViewController.h"
#import "IPDFCameraViewController.h"
#import "AppDelegate.h"
#import "ImageResizer.h"
#import <opencv2/opencv.hpp>


@interface OCRViewController () 
@property (weak, nonatomic) IBOutlet IPDFCameraViewController *vImagePreview;

@end

@implementation OCRViewController
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
UIView *buttonPanel;
UIView *rectangleP;
UIButton *btnClose;
UIButton *btnShoot;
UIButton *btnClosePreview;
UIButton *btnProcess;
UIButton *btnTorch;

UIImageView  *vImage;
UIView *imagePreview;

CGFloat width;
CGFloat height;
UIProgressView *progressBar;
float currentProgress;
NSTimer *shooterTimer;
NSTimer *progressTimer;
UILabel *status;
G8Tesseract *tesseract;
- (void)viewDidLoad {
    [super viewDidLoad];

    width = [UIScreen mainScreen].bounds.size.width;
    height = [UIScreen mainScreen].bounds.size.height;
    if (IS_OS_8_OR_LATER){
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        buttonPanel = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        buttonPanel.frame = CGRectMake(0, height-70, width, 70);
        imagePreview = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        imagePreview.frame = CGRectMake(0, 0, width, height);
        
    }else{
        buttonPanel = [[UIView alloc] initWithFrame:CGRectMake(0, height-70, width, 70)];
        buttonPanel.backgroundColor = [UIColor blackColor];
        buttonPanel.alpha = 0.8;
        imagePreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    }
    rectangleP = [[UIView alloc] initWithFrame:CGRectMake((width * 0.1),
                                                          (height * 0.1),
                                                          width-(width * 0.2),
                                                          height-(height * 0.3))];
    rectangleP.layer.borderWidth= 5;
    
    CGFloat nRed=10/255.0;
    CGFloat nBlue=200.0/255.0;
    CGFloat nGreen=60.0/255.0;
    UIColor *myColor= [[UIColor alloc]initWithRed:nRed green:nBlue blue:nGreen alpha:0.6];
    rectangleP.layer.borderColor = [myColor CGColor];
    imagePreview.hidden = YES;
    btnClose  = [UIButton buttonWithType
                 :UIButtonTypeRoundedRect];
    btnClose.frame = CGRectMake(width-60, 20 , 50, 30);
    [btnClose setTitle:@"Close" forState:UIControlStateNormal];
    [btnClose addTarget:self
               action:@selector(closeClicked:)
     forControlEvents:UIControlEventTouchUpInside];
    
    btnShoot  = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnShoot.frame = CGRectMake((width/2)-75, 20 , 150, 30);
    [btnShoot setTitle:@"Take Picture" forState:UIControlStateNormal];
    [btnShoot addTarget:self
                 action:@selector(shootClicked:)
       forControlEvents:UIControlEventTouchUpInside];
    
    btnClosePreview  = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnClosePreview.frame = CGRectMake((width/2)-75, height-40 , 150, 30);
    [btnClosePreview setTitle:@"Close" forState:UIControlStateNormal];
    [btnClosePreview addTarget:self
                     action:@selector(closeImagePreview:)
         forControlEvents:UIControlEventTouchUpInside];
    
    btnTorch = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnTorch.frame = CGRectMake(5, 20 , 70, 30);
    [btnTorch  setTitle:@"Torch" forState:UIControlStateNormal];
    [btnTorch  addTarget:self
                        action:@selector(torchOn:)
              forControlEvents:UIControlEventTouchUpInside];
    
    vImage = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,width,height)];
    [buttonPanel addSubview:btnShoot];
    [buttonPanel addSubview:btnClose];
    [buttonPanel addSubview:btnTorch];
    [self.view addSubview:buttonPanel];
    [imagePreview addSubview:vImage];
    [imagePreview addSubview:btnClosePreview];
    UIView *cameraFrame = [[UIView alloc]
                           initWithFrame:CGRectMake((width /2)-((width * 0.8) /2),
                                                    10,
                                                    width * 0.8,height * 0.7)];
    
    cameraFrame.layer.borderColor = [[UIColor greenColor] CGColor];
    cameraFrame.layer.borderWidth = 1;
    
    progressBar = [[UIProgressView alloc] initWithFrame:
                   CGRectMake(10, imagePreview.bounds.size.height-150 , imagePreview.bounds.size.width-20,10)];
    
    currentProgress = 0.0f;
    [progressBar setProgress:0.0f];
    status = [[UILabel alloc]initWithFrame:CGRectMake(16,80,width-32,100)];
    [status setText:@"Preparing Image, Please Wait..."];
    [status setTextAlignment:NSTextAlignmentCenter];
    [status setTextColor:[UIColor whiteColor]];
    [status setLineBreakMode:NSLineBreakByWordWrapping];
    [status setNumberOfLines:2];
    [imagePreview addSubview:progressBar];
    [imagePreview addSubview:status];
    [self.view addSubview:imagePreview];
    
#if TARGET_IPHONE_SIMULATOR
    imagePreview.hidden = NO;
    [self temporary];
#else

    [self.vImagePreview addSubview:cameraFrame];
    [self.vImagePreview setupCameraView];
    [self.vImagePreview setCameraViewType:IPDFCameraViewTypeNormal];
    [self.vImagePreview setEnableBorderDetection:YES];
    
    [self.vImagePreview start];
    shooterTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                    target:self
                                                  selector:@selector(autoShoot:)
                                                  userInfo:nil
                                                   repeats:YES];
#endif
    
   
}

- (void)viewDidAppear:(BOOL)animated
{
   
}

-(IBAction)autoShoot:(id)sender{
    if ([self.vImagePreview isRectangleStable]){
      [shooterTimer invalidate];
      shooterTimer = nil;
      [self shootClicked:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

-(IBAction)closeClicked:(id)sender{
    NSLog(@"Close Clicked");
    [shooterTimer invalidate];
    shooterTimer = nil;
    [self.vImagePreview stop];
    [self.vImagePreview setEnableTorch:NO];
    [self dismissViewControllerAnimated:true completion:nil];
}

-(IBAction)shootClicked:(id)sender{
    [self.vImagePreview captureImageWithCompletionHander:^(UIImage *image){
        
        [self recognitionProcess:image];

    }];
}


-(void)temporary{

    UIImage *image = [[UIImage alloc] init];
    
    image = [UIImage imageNamed:@"BC5.jpg"];
    
    image = [self.vImagePreview tempImageLoad:image];
    [self recognitionProcess:image];

}

-(void)recognitionProcess:(UIImage *)image{
    [status setText:@"Preparing Image, Please Wait..."];
    //image = [ImageResizer  imageWithImage:image scaledToMaxWidth:4000 maxHeight:4000];
    NSLog(@"w = %f h = %f",image.size.width,image.size.height);
    
    CGSize kMaxImageViewSize = {.width = width, .height = width};
    
    CGSize imageSize = image.size;
    CGFloat aspectRatio = imageSize.width / imageSize.height;
    CGRect frame = vImage.frame;
    if (kMaxImageViewSize.width / aspectRatio <= kMaxImageViewSize.height) {
        frame.size.width = kMaxImageViewSize.width;
        frame.size.height = frame.size.width / aspectRatio;
        
    } else {
        frame.size.height = kMaxImageViewSize.height;
        frame.size.width = frame.size.height * aspectRatio;
    }
    frame.origin.x = (width/2) - (frame.size.width/2);
    frame.origin.y = ( height / 2 ) - (frame.size.height / 2 );
    vImage.frame = frame;
    vImage.image =  image;
    
    //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    cv::Mat matImage =  [self cvMatFromUIImage:image];
    
    matImage = matImage + cv::Scalar(-50, -50, -50);
    cv::cvtColor(matImage, matImage, CV_BGR2GRAY);
    cv::adaptiveThreshold(matImage,matImage,255,CV_ADAPTIVE_THRESH_MEAN_C, CV_THRESH_BINARY,75,35);
    
    image =  [self UIImageFromCVMat:matImage];
    
    imagePreview.hidden = NO;
    
    vImage.image =  image;
    
    btorchOn = NO;
    [self.vImagePreview setEnableTorch:NO];
    [self.vImagePreview stop];
    currentProgress = 0.0f;
    [progressBar setProgress:0.0f];
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                     target:self
                                                   selector:@selector(progressUpdate:)
                                                   userInfo:nil
                                                    repeats:YES];
    btnClosePreview.hidden = YES;
    tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng+spa"];
    tesseract.delegate = (id<G8TesseractDelegate>)self;
    tesseract.charWhitelist = @"0123456789"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz"
    "':#,./@(){}[]_-+ÁÉÍÑÓÚáéíñóú";
    
    tesseract.pageSegmentationMode = G8PageSegmentationModeAutoOSD;
    
    tesseract.image = image;
    
    dispatch_queue_t queue = dispatch_queue_create("openOCRQueue", NULL);
    
    dispatch_async(queue, ^{
        
        [tesseract recognize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *text = [tesseract recognizedText];
            
            //text = @"";
            NSArray *characterBoxes = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelTextline];
            
            //NSLog(@"characterBoxes:%@", characterBoxes);
            UIImage *imageWithBlocks = [tesseract imageWithBlocks:characterBoxes drawText:YES thresholded:NO];
            
            vImage.image = imageWithBlocks;
            currentProgress = 1.0f;
            [progressBar setProgress:1.0f];
            [progressTimer invalidate];
            progressTimer = nil;
            btnClosePreview.hidden = NO;

            NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
            
            NSArray* links = [detector matchesInString:text options:0 range:NSMakeRange(0, [text length])];
            
            
            
            detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber error:nil];
            NSArray *phones = [detector matchesInString:text options:0
                                                  range:NSMakeRange(0, [text length])];
            
            
            if (links.count > 0 || phones.count > 0){
                AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                del.strData = text;
                
                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"navResultView"];
                [self presentViewController:vc animated:YES completion:nil];

            }else{
                UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Select Action:"
                                                            delegate:(id<UIActionSheetDelegate>)self
                                                          cancelButtonTitle:@"Close"
                                                     destructiveButtonTitle:nil
                                                          otherButtonTitles:
                                        @"Input Manually",
                                        @"Try Again",
                                        @"Exit Business Card Reader",
                                        nil];

                [popup showInView:[UIApplication sharedApplication].keyWindow];
            }
            
            
            [status setText:[NSString stringWithFormat:@"Recognizing Texts\n100%@",@"%"]];
            
        });
    });

}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1){
        [self closeImagePreview:self];
    }else if (buttonIndex == 2){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


-(IBAction)progressUpdate:(id)sender{
    if (currentProgress > 0){
      [status setText:
              [NSString stringWithFormat:@"Recognizing Texts\n%0.0f%@",(currentProgress * 100),@"%"]];
    }
    [progressBar setProgress:currentProgress animated:YES];
}

- (UIImage *)preprocessedImageForTesseract:(G8Tesseract *)tesseract sourceImage:(UIImage *)sourceImage{
    return sourceImage;
}

- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {

    //NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
    currentProgress = ((float)tesseract.progress) /100;

}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL)
    {
        NSLog(@"Error during saving image: %@", error);
    }
}

-(IBAction)closeImagePreview:(id)sender{

    imagePreview.hidden = YES;
    [self.vImagePreview setEnableTorch:NO];
    [self.vImagePreview start];
    shooterTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                    target:self
                                                  selector:@selector(autoShoot:)
                                                  userInfo:nil
                                                   repeats:YES];
}
- (BOOL)shouldAutorotate
{
    return NO;

}
-(IBAction)processImage:(id)sender{

}
bool btorchOn = NO;
-(IBAction)torchOn:(id)sender{
    if (!btorchOn){
        btorchOn = YES;
        [self.vImagePreview setEnableTorch:YES];
    }else{
        btorchOn = NO;
        [self.vImagePreview setEnableTorch:NO];
        
    }
}

-(UIImage *) quadrelateralCorrection:(UIImage *) source{
  /*
    cv::Mat src = [self cvMatFromUIImage:source];
    ImageProcessing wrapper;
    cv::Mat src1 = wrapper.quadrelateralCorrection(src);
    return [self UIImageFromCVMat:src1];
   */
    return nil;
}
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
