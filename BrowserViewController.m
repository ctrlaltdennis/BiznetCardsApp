//
//  BrowserViewController.m
//  BiznetCards
//
//  Created by TheApp4U on 2/14/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "BrowserViewController.h"
#import "AppDelegate.h"

@interface BrowserViewController ()


@end

@implementation BrowserViewController
UIWebView *webView;
UIActivityIndicatorView *activityView;

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.view addSubview: activityView];
    activityView.frame = CGRectMake(0, 0, 120, 120);
    activityView.backgroundColor =  [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    activityView.center = self.view.center;
    activityView.layer.cornerRadius = 10.0;
    
    */
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height)];
    [self.view addSubview:webView];
    
    AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:del.strURL]]];
  

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneClicked:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
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
