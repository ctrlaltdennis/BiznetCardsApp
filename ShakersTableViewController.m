//
//  ShakersTableViewController.m
//  BiznetCardsV2
//
//  Created by TheApp4U on 1/29/15.
//  Copyright (c) 2015 dta. All rights reserved.
//

#import "ShakersTableViewController.h"
#import "AppDelegate.h"
#import "DetailViewController.h"

@interface ShakersTableViewController()
    @property (strong, nonatomic) IBOutlet UITableView *tableVIew;

@end

@implementation ShakersTableViewController

NSArray *tableData;

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *temp = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    tableData = temp.tableData;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *shakersTableIdentifier = @"shakersTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:shakersTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:shakersTableIdentifier];
    }
    if ([tableData objectAtIndex:indexPath.row] != nil){
      NSString *first_name =[[tableData objectAtIndex:indexPath.row] valueForKey:@"first_name"];
      NSString *last_name =[[tableData objectAtIndex:indexPath.row] valueForKey:@"last_name"];
    
      NSString *name = [NSString stringWithFormat:@"%@ %@",first_name,last_name];
      NSString *company = [[tableData objectAtIndex:indexPath.row] valueForKey:@"company"];
      NSString *distance =[[tableData objectAtIndex:indexPath.row] valueForKey:@"distance"];
      NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
      numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
      float value = [numberFormatter numberFromString:distance].floatValue;

      if (((int)value) == 0){
        value = 5280 * value;
        distance = [NSString stringWithFormat:@"%.02f ft",value];
      }else{
        distance = [NSString stringWithFormat:@"%.02f miles",value];
      }
    
      NSString *position =[[tableData objectAtIndex:indexPath.row] valueForKey:@"title"];
      NSString *description = [NSString stringWithFormat:@"%@ - %@\nDistance  : %@",position,company,distance];
      cell.textLabel.text = name;
      cell.detailTextLabel.text = description;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSString *card_id = [[tableData objectAtIndex:indexPath.row] valueForKey:@"card_id"];
    //NSLog(@"%@",card_id);
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *card_id = [[tableData objectAtIndex:indexPath.row] valueForKey:@"card_id"];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.card_id = card_id;
        

    }
}



- (IBAction)doneTapped:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end