//
//  mainUViewController.m
//  BiznetCards
//
//  Created by TheApp4U on 3/13/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "mainUViewController.h"

@interface mainUViewController ()

@end

@implementation mainUViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"%@",[segue identifier]);
    /*
    if ([[segue identifier] isEqualToString:@""])
    {
     
        ViewController *vc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        [vc setMyObjectHere:object];
    }
     */
}


@end
