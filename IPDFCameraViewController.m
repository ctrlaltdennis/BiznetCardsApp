//
//  IPDFCameraViewController.m
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import "IPDFCameraViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <GLKit/GLKit.h>

@interface IPDFCameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDevice *captureDevice;
@property (nonatomic,strong) EAGLContext *context;

@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;

@property (nonatomic, assign) BOOL forceStop;

@end

@implementation IPDFCameraViewController
{
    CIContext *_coreImageContext;
    GLuint _renderBuffer;
    GLKView *_glkView;
    
    BOOL _isStopped;
    
    CGFloat _imageDedectionConfidence;
    NSTimer *_borderDetectTimeKeeper;
    BOOL _borderDetectFrame;
    CIRectangleFeature *_borderDetectLastRectangleFeature;
    
    BOOL _isCapturing;
    CGFloat maxWidth;
    CGFloat maxHeight;
    NSTimer *luminosityTimer;
    BOOL getBuffer;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backgroundMode) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_foregroundMode) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)_backgroundMode
{
    self.forceStop = YES;
}

- (void)_foregroundMode
{
    self.forceStop = NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createGLKView
{
    if (self.context) return;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = [[GLKView alloc] initWithFrame:self.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.context = self.context;
    view.contentScaleFactor = 1.0f;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self insertSubview:view atIndex:0];
    _glkView = view;
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    _coreImageContext = [CIContext contextWithEAGLContext:self.context];
    [EAGLContext setCurrentContext:self.context];
    
}

- (void)setupCameraView
{
    [self createGLKView];

    NSArray *possibleDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [possibleDevices firstObject];
    if (!device) return;
    
    _imageDedectionConfidence = 0.0;
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.captureSession = session;
    [session beginConfiguration];
    self.captureDevice = device;
    
    NSError *error = nil;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    session.sessionPreset = AVCaptureSessionPresetPhoto;
    [session addInput:input];
    
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput:dataOutput];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [session addOutput:self.stillImageOutput];
    
    AVCaptureConnection *connection = [dataOutput.connections firstObject];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    if (device.isFlashAvailable)
    {
        [device lockForConfiguration:nil];
        [device setFlashMode:AVCaptureFlashModeOff];
        [device unlockForConfiguration];
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            [device lockForConfiguration:nil];
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [device unlockForConfiguration];
        }
       
    }
    
    if (device.isLowLightBoostSupported){
        [device lockForConfiguration:nil];
         device.automaticallyEnablesLowLightBoostWhenAvailable = YES;
        [device unlockForConfiguration];
    }
    [session commitConfiguration];
}

- (void)setCameraViewType:(IPDFCameraViewType)cameraViewType
{
    UIBlurEffect * effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *viewWithBlurredBackground =[[UIVisualEffectView alloc] initWithEffect:effect];
    viewWithBlurredBackground.frame = self.bounds;
    [self insertSubview:viewWithBlurredBackground aboveSubview:_glkView];
    
    _cameraViewType = cameraViewType;
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        [viewWithBlurredBackground removeFromSuperview];
    });
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.forceStop) return;
    if (_isStopped || _isCapturing || !CMSampleBufferIsValid(sampleBuffer)) return;
    
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    if (getBuffer){
        if ([self getLuminosity:sampleBuffer] < 10){
            if (!_enableTorch){
                [self setEnableTorch:YES];
            }
        }
    }
    maxWidth = image.extent.size.width;
    maxHeight = image.extent.size.height;
    
    if (self.cameraViewType != IPDFCameraViewTypeNormal)
    {
        image = [self filteredImageUsingEnhanceFilterOnImage:image];
    }
    else
    {
        image = [self filteredImageUsingContrastFilterOnImage:image];
    }
    
    if (self.isBorderDetectionEnabled)
    {
        if (_borderDetectFrame)
        {
            _borderDetectLastRectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:image]];
            _borderDetectFrame = NO;
        }
        
        if (_borderDetectLastRectangleFeature)
        {
            _imageDedectionConfidence += .5;
            
            image = [self drawHighlightOverlayForPoints:image topLeft:_borderDetectLastRectangleFeature.topLeft topRight:_borderDetectLastRectangleFeature.topRight bottomLeft:_borderDetectLastRectangleFeature.bottomLeft bottomRight:_borderDetectLastRectangleFeature.bottomRight];
            
        }
        else
        {
            _imageDedectionConfidence = 0.0f;
        }
    }
    
    if (self.context && _coreImageContext)
    {
        [_coreImageContext drawImage:image inRect:self.bounds fromRect:image.extent];
        [self.context presentRenderbuffer:GL_RENDERBUFFER];
        
        [_glkView setNeedsDisplay];
    }
}

-(float)getLuminosity:(CMSampleBufferRef)sampleBuffer{

    int x = 300;
    int y = 300;
    
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *tempAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t bwidth = CVPixelBufferGetWidth(imageBuffer);
    size_t bheight = CVPixelBufferGetHeight(imageBuffer);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    int bufferSize = (int)(bytesPerRow * bheight);
    uint8_t *myPixelBuf = malloc(bufferSize);
    memmove(myPixelBuf, tempAddress, bufferSize);
    tempAddress = nil;
    // remember it's BGRA data
    int b = myPixelBuf[(x*4)+(y*bytesPerRow)];
    int g = myPixelBuf[((x*4)+(y*bytesPerRow))+1];
    int r = myPixelBuf[((x*4)+(y*bytesPerRow))+2];
    
    free(myPixelBuf);

    float luminance = (0.2126*r + 0.7152*g + 0.0722*b);
    //NSLog(@"Luminance %f",luminance);
    getBuffer = NO;
    return luminance;
}

- (void)enableBorderDetectFrame
{
    _borderDetectFrame = YES;
}

- (CIImage *)drawHighlightOverlayForPoints:(CIImage *)image topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
     CIImage *overlay = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0 alpha:0.4]];
    
    overlay = [overlay imageByCroppingToRect:image.extent];
    overlay = [overlay imageByApplyingFilter:@"CIPerspectiveTransformWithExtent" withInputParameters:@{@"inputExtent":[CIVector vectorWithCGRect:image.extent],@"inputTopLeft":[CIVector vectorWithCGPoint:topLeft],@"inputTopRight":[CIVector vectorWithCGPoint:topRight],@"inputBottomLeft":[CIVector vectorWithCGPoint:bottomLeft],@"inputBottomRight":[CIVector vectorWithCGPoint:bottomRight]}];
    
    return [overlay imageByCompositingOverImage:image];
}

- (void)start
{
    _isStopped = NO;
    
    [self.captureSession startRunning];
    
    _borderDetectTimeKeeper = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(enableBorderDetectFrame) userInfo:nil repeats:YES];
    
    luminosityTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setLuminosityFlag:) userInfo:nil repeats:YES];
    
    [self hideGLKView:NO completion:nil];
}

- (void)stop
{
    _isStopped = YES;
    
    [self.captureSession stopRunning];
    
    [_borderDetectTimeKeeper invalidate];
    [luminosityTimer invalidate];
    luminosityTimer = nil;
    
    [self hideGLKView:YES completion:nil];
}

-(IBAction)setLuminosityFlag:(id)sender{
    getBuffer = YES;
}

-(void)setEnableTorchAuto:(BOOL)enableTorchAuto{
    _enableTorchAuto = enableTorchAuto;
    AVCaptureDevice *device = self.captureDevice;
    if ([device hasTorch] && [device hasFlash])
    {
        [device lockForConfiguration:nil];
        
        if (enableTorchAuto)
        {
            [device setTorchMode:AVCaptureTorchModeAuto];
        }
        else
        {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}
- (void)setEnableTorch:(BOOL)enableTorch
{
    _enableTorch = enableTorch;
    
    AVCaptureDevice *device = self.captureDevice;
    if ([device hasTorch] && [device hasFlash])
    {
        [device lockForConfiguration:nil];
        
        if (enableTorch)
        {
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        else
        {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)())completionHandler
{
    AVCaptureDevice *device = self.captureDevice;
    CGPoint pointOfInterest = CGPointZero;
    CGSize frameSize = self.bounds.size;
    pointOfInterest = CGPointMake(point.y / frameSize.height, 1.f - (point.x / frameSize.width));
    
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        NSError *error;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
            {
                [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                [device setFocusPointOfInterest:pointOfInterest];
            }
            
            if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            {
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                completionHandler();
            }
            
            [device unlockForConfiguration];
        }
    }
    else
    {
        completionHandler();
    }
}

- (void)captureImageWithCompletionHander:(void(^)(UIImage *data))completionHandler
{
    if (_isCapturing) return;
    
    __weak typeof(self) weakSelf = self;
    
    [weakSelf hideGLKView:YES completion:^
    {
        [weakSelf hideGLKView:NO completion:^
        {
            [weakSelf hideGLKView:YES completion:nil];
        }];
    }];
    
    _isCapturing = YES;
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) break;
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         if (!imageSampleBuffer)
             return;
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         
         CGFloat xWidth = 0;
         CGFloat xHeight = 0;
         
         if (weakSelf.cameraViewType == IPDFCameraViewTypeBlackAndWhite || weakSelf.isBorderDetectionEnabled)
         {
             
             CIImage *enhancedImage = [CIImage imageWithData:imageData];

            
             if (weakSelf.cameraViewType == IPDFCameraViewTypeBlackAndWhite)
             {
                 enhancedImage = [self filteredImageUsingEnhanceFilterOnImage:enhancedImage];
             }
             else
             {
                 enhancedImage = [self filterFinalImage:enhancedImage];
             }
             
             if (weakSelf.isBorderDetectionEnabled && rectangleDetectionConfidenceHighEnough(_imageDedectionConfidence))
             {
                 CIRectangleFeature *rectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:enhancedImage]];
                 if (rectangleFeature)
                 {
                     CGPoint p1 = rectangleFeature.topLeft;
                     CGPoint p2 = rectangleFeature.topRight;
                     xWidth = hypotf(p1.x - p2.x, p1.y - p2.y);
                     
                     CGPoint p3 = rectangleFeature.topLeft;
                     CGPoint p4 = rectangleFeature.bottomLeft;
                     xHeight = hypotf(p3.x - p4.x, p3.y - p4.y);
                     
                     
                     enhancedImage = [self correctPerspectiveForImage:enhancedImage withFeatures:rectangleFeature];
                 }
             }else{
                 
                   _borderDetectLastRectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:enhancedImage]];
                 
                   CIRectangleFeature *rectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:enhancedImage]];
                 
                    NSLog(@"Border Not Detected Have to Detect again %@",rectangleFeature);
                   if (rectangleFeature)
                   {
                     CGPoint p1 = rectangleFeature.topLeft;
                     CGPoint p2 = rectangleFeature.topRight;
                     xWidth = hypotf(p1.x - p2.x, p1.y - p2.y);
                     
                     CGPoint p3 = rectangleFeature.topLeft;
                     CGPoint p4 = rectangleFeature.bottomLeft;
                     xHeight = hypotf(p3.x - p4.x, p3.y - p4.y);
                     
                     
                     enhancedImage = [self correctPerspectiveForImage:enhancedImage withFeatures:rectangleFeature];
                  }
             }
             
             enhancedImage = [CIFilter filterWithName:@"CIExposureAdjust"
                               keysAndValues:kCIInputImageKey,
                               enhancedImage,
                              @"inputEV", @0.5, nil ].outputImage ;
             
             if (xWidth > xHeight){
                UIGraphicsBeginImageContext(CGSizeMake(enhancedImage.extent.size.width, enhancedImage.extent.size.height));
                 [[UIImage imageWithCIImage:enhancedImage scale:1.0 orientation:UIImageOrientationUp] drawInRect:CGRectMake(0,0, enhancedImage.extent.size.width, enhancedImage.extent.size.height)];
             }else{
                 UIGraphicsBeginImageContext(CGSizeMake(enhancedImage.extent.size.height, enhancedImage.extent.size.width));
                 
               [[UIImage imageWithCIImage:enhancedImage scale:1.0 orientation:UIImageOrientationRight] drawInRect:CGRectMake(0,0, enhancedImage.extent.size.height, enhancedImage.extent.size.width)];
             }
             
             UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             
             [weakSelf hideGLKView:NO completion:nil];
             
             completionHandler(image);
             image = nil;
         }
         else
         {
             [weakSelf hideGLKView:NO completion:nil];
             UIImage *image = [[UIImage alloc] initWithData:imageData];
             completionHandler(image);
             image = nil;
         }

         _isCapturing = NO;
     }];
}

-(UIImage *)tempImageLoad:(UIImage*)image{
    CIImage *enhancedImage = [[CIImage alloc] initWithCGImage:image.CGImage options:nil];
    CGFloat xWidth = 0;
    CGFloat xHeight = 0;
    NSLog(@"Was here %@",enhancedImage);
    CIRectangleFeature *rectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:enhancedImage]];
    
    enhancedImage = [self filterFinalImage:enhancedImage];
    
    if (rectangleFeature)
    {
        CGPoint p1 = rectangleFeature.topLeft;
        CGPoint p2 = rectangleFeature.topRight;
        xWidth = hypotf(p1.x - p2.x, p1.y - p2.y);
        
        CGPoint p3 = rectangleFeature.topLeft;
        CGPoint p4 = rectangleFeature.bottomLeft;
        xHeight = hypotf(p3.x - p4.x, p3.y - p4.y);
        
        enhancedImage = [self correctPerspectiveForImage:enhancedImage withFeatures:rectangleFeature];
    }
    
    enhancedImage = [CIFilter filterWithName:@"CIExposureAdjust"
                               keysAndValues:kCIInputImageKey,
                     enhancedImage,
                     @"inputEV", @0.5, nil ].outputImage ;
    
    if (xWidth > xHeight){
        UIGraphicsBeginImageContext(CGSizeMake(enhancedImage.extent.size.width, enhancedImage.extent.size.height));
        [[UIImage imageWithCIImage:enhancedImage scale:1.0 orientation:UIImageOrientationUp] drawInRect:CGRectMake(0,0, enhancedImage.extent.size.width, enhancedImage.extent.size.height)];
    }else{
        UIGraphicsBeginImageContext(CGSizeMake(enhancedImage.extent.size.height, enhancedImage.extent.size.width));
        
        [[UIImage imageWithCIImage:enhancedImage scale:1.0 orientation:UIImageOrientationRight] drawInRect:CGRectMake(0,0, enhancedImage.extent.size.height, enhancedImage.extent.size.width)];
    }
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)hideGLKView:(BOOL)hidden completion:(void(^)())completion
{
    [UIView animateWithDuration:0.1 animations:^
    {
        _glkView.alpha = (hidden) ? 0.0 : 1.0;
    }
    completion:^(BOOL finished)
    {
        if (!completion) return;
        completion();
    }];
}

- (CIImage *)filteredImageUsingEnhanceFilterOnImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, @"inputBrightness", [NSNumber numberWithFloat:0.0], @"inputContrast", [NSNumber numberWithFloat:1.14], @"inputSaturation", [NSNumber numberWithFloat:0.0], nil].outputImage;
}

- (CIImage *)filteredImageUsingContrastFilterOnImage:(CIImage *)image
{
    if (_enableTorch){
        return [CIFilter filterWithName:@"CIColorControls"
                    withInputParameters:@{@"inputContrast":@(0.98),
                                          kCIInputImageKey:image}].outputImage;
    }else{
        return [CIFilter filterWithName:@"CIColorControls"
                    withInputParameters:@{@"inputContrast":@(0.95),
                                          kCIInputImageKey:image}].outputImage;
    }
    
}

- (CIImage *)filterFinalImage:(CIImage *)image
{
    if (_enableTorch){
         return [CIFilter filterWithName:@"CIColorControls"
                    withInputParameters:@{@"inputContrast":@(0.98),
                                          kCIInputImageKey:image}].outputImage;
    }else{
        return [CIFilter filterWithName:@"CIColorControls"
                             withInputParameters:@{@"inputContrast":@(0.95),
                                           kCIInputImageKey:image}].outputImage;
   }
}

- (CIImage *)correctPerspectiveForImage:(CIImage *)image withFeatures:(CIRectangleFeature *)rectangleFeature
{
    NSMutableDictionary *rectangleCoordinates = [NSMutableDictionary new];
    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:rectangleFeature.topLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:rectangleFeature.topRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:rectangleFeature.bottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:rectangleFeature.bottomRight];
    return [image imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
}

- (CIDetector *)rectangleDetetor
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
          detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyLow,CIDetectorTracking : @(YES)}];
    });
    return detector;
}

- (CIDetector *)highAccuracyRectangleDetector
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
    });
    return detector;
}

- (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles
{
    if (![rectangles count]) return nil;
    
    float halfPerimiterValue = 0;
    
    CIRectangleFeature *biggestRectangle = [rectangles firstObject];
    
    for (CIRectangleFeature *rect in rectangles)
    {
        CGPoint p1 = rect.topLeft;
        CGPoint p2 = rect.topRight;
        CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);
        
        CGPoint p3 = rect.topLeft;
        CGPoint p4 = rect.bottomLeft;
        CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);
        
        CGFloat currentHalfPerimiterValue = height + width;
        
        if (halfPerimiterValue < currentHalfPerimiterValue)
        {
            halfPerimiterValue = currentHalfPerimiterValue;
            biggestRectangle = rect;
        }
    }
    
    return biggestRectangle;
}

-(BOOL)isRectangleStable{
    CGFloat Width = 0, Height = 0;
    CIRectangleFeature *rectangleFeature =  _borderDetectLastRectangleFeature;
    CGPoint p1 = rectangleFeature.topLeft;
    CGPoint p2 = rectangleFeature.topRight;
    Width = hypotf(p1.x - p2.x, p1.y - p2.y);
    
    CGPoint p3 = rectangleFeature.topLeft;
    CGPoint p4 = rectangleFeature.bottomLeft;
    Height = hypotf(p3.x - p4.x, p3.y - p4.y);
    
    CGPoint center;
    center.x = (p1.x + p2.x) /2;
    center.y = (p3.y + p4.y) /2;
    
    //[self focusAtPoint:center completionHandler:^(){}];

    BOOL positionRight = (p1.x > 70 && p1.x < 180) && (p1.y > 780 && p1.y < 960);
    BOOL sizeRight = ((Width >= 380) && Height >= 600);
    
    //NSLog(@"X=%f Y= %f",p1.x,p1.y);
    
    if (_imageDedectionConfidence >= 15 && sizeRight && positionRight)
        return YES;
    else
        return NO;
}

BOOL rectangleDetectionConfidenceHighEnough(float confidence)
{
    return (confidence > 1.5);
}

@end
