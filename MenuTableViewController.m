//
//  MenuTableViewController.m
//  BiznetCardsV2
//
//  Created by TheApp4U on 2/12/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "MenuTableViewController.h"
#import "DetailViewController.h"

@interface MenuTableViewController ()

@end

@implementation MenuTableViewController
NSMutableArray *menu;
DetailViewController *mother;
UIActivityIndicatorView *activityView;

- (void)viewDidLoad {
    [super viewDidLoad];
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.navigationController.topViewController.view addSubview: activityView];
    activityView.frame = CGRectMake(0, 0, 120, 120);
    activityView.backgroundColor =  [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    activityView.center = self.view.center;
    activityView.layer.cornerRadius = 10.0;
    menu = [[NSMutableArray alloc] init];
    [menu addObject:@"Save To Contacts"];
    [menu addObject:@"Open Card in Safari"];
    mother = [[DetailViewController alloc] init];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return [menu count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *menuTableIdentifier = @"menuTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:menuTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:menuTableIdentifier];
    }
    if ([menu objectAtIndex:indexPath.row] != nil){
        cell.textLabel.text =[menu objectAtIndex:indexPath.row];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [mother dismissPopover];
    if (indexPath.row == 0){
      [mother save_contact];
    }else if (indexPath.row == 1){
        NSString *url = [NSString stringWithFormat:@"%@zappcards/%@",_base_url,_card_id];
        NSLog(@"%@",url);
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
    
}
@end
