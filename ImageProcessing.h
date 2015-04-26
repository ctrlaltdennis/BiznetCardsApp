//
//  ImageProcessing.h
//  BiznetCards
//
//  Created by TheApp4U on 4/10/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#ifndef __BiznetCards__ImageProcessing__
#define __BiznetCards__ImageProcessing__
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>

class ImageProcessing{
 
public:
    cv::Mat quadrelateralCorrection(cv::Mat source);
};
#endif /* defined(__BiznetCards__ImageProcessing__) */
