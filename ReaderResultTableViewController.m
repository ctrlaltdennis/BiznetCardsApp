//
//  ReaderResultTableViewController.m
//  BiznetCards
//
//  Created by TheApp4U on 4/22/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//
#import "AppDelegate.h"
#import "ReaderResultTableViewController.h"

@interface ReaderResultTableViewController ()

@end

@implementation ReaderResultTableViewController

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

NSMutableDictionary *contactInfo;
NSMutableArray *keys;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self performDataParsing];
}

-(void)performDataParsing{
    AppDelegate * del = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *text = del.strData;
    NSLog(@"%@",text);
    NSMutableArray *pNumbers = [[NSMutableArray alloc] init];
    NSMutableArray *pEmails = [[NSMutableArray alloc] init];
    NSMutableArray *pURLs =[[NSMutableArray alloc] init];
    NSMutableArray *pInfo = [[NSMutableArray alloc] init];
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    NSArray *tlines = [text componentsSeparatedByCharactersInSet:
                       [NSCharacterSet characterSetWithCharactersInString:@"\n"]
                       ];
    
    for (NSString *line in tlines){
        NSString *l = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (l.length > 1 && ![self GarbageFilter:l]){
            NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingAllSystemTypes error:nil];
            NSArray* res = [detector matchesInString:l options:0 range:NSMakeRange(0, [l length])];
            if (res.count > 0){
              for (NSTextCheckingResult *match in res) {
                  if ([match resultType] == NSTextCheckingTypeLink){
                      NSString *url = [[match URL] absoluteString];
                      if (IS_OS_8_OR_LATER){
                          if ([url containsString:@"mailto:"]){
                              url = [url stringByReplacingOccurrencesOfString:@"mailto:" withString:@""];
                              [pEmails addObject:@[@"Work Email",url]];
                          }else{
                              [pURLs addObject:@[@"URL",url]];
                          }
                      }else{
                          if ([url rangeOfString:@"mailto:"].location != NSNotFound){
                              url = [url stringByReplacingOccurrencesOfString:@"mailto:" withString:@""];
                              [pEmails addObject:@[@"Work Email",url]];
                          }else{
                              [pURLs addObject:@[@"URL",url]];
                          }
                      }
                      url = [url stringByReplacingOccurrencesOfString:@"mailto:" withString:@""];
                      url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                      url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@""];
                      l = [l stringByReplacingOccurrencesOfString:url withString:@""];
                  }
                  else if ([match resultType] == NSTextCheckingTypePhoneNumber){
                      NSCharacterSet *nset = [NSCharacterSet characterSetWithCharactersInString:@"+()0123456789"];
                      NSString *lbl = [[l componentsSeparatedByCharactersInSet:nset]
                                              componentsJoinedByString:@""];
                      lbl = [lbl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                      if ([lbl length] > 0){
                          if ([[match phoneNumber] characterAtIndex:0] == 'T' ||
                                   [[match phoneNumber] characterAtIndex:0] == 'P' ){
                              lbl = @"Work Tel";
                          }else if ([[match phoneNumber] characterAtIndex:0] == 'M' ){
                              lbl = @"Mobile";
                          }else if ([lbl characterAtIndex:0] == 'T' ||
                              [lbl characterAtIndex:0] == 'P'){
                             lbl = @"Work Tel";
                          }else if ([lbl characterAtIndex:0] == 'M'){
                             lbl = @"Mobile";
                          }else if ([lbl characterAtIndex:0] == 'F'){
                             lbl = @"Work Fax";
                          }else{
                             lbl = @"Work Tel";
                          }
                      }else{
                          lbl = @"Work Tel";
                      }
                      
                      NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"|/"];
                      NSArray *PNos = [[match phoneNumber] componentsSeparatedByCharactersInSet:charSet];
                      if (PNos.count > 1){
                        for (NSString *p in PNos){
                            NSString *ps = [p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                            ps = [[ps componentsSeparatedByCharactersInSet:[nset invertedSet]]
                                  componentsJoinedByString:@""];
                            NSArray *a = @[lbl,ps];
                            [pNumbers addObject:a];
                        }
                      }else{
                          NSString *p = [[[match phoneNumber] componentsSeparatedByCharactersInSet:[nset invertedSet]]
                              componentsJoinedByString:@""];
                          NSArray *a  = @[lbl,p];
                          [pNumbers addObject:a];
                      }
                      l = [l stringByReplacingOccurrencesOfString:[match phoneNumber] withString:@""];
                  }
                  else{
                      NSLog(@"Unfiltered %@",match);
                  }
              }
            }

            [lines addObject:l];
            
        }
        
    }
    NSMutableArray *cleanLines = [[NSMutableArray alloc] init];
    for (NSString *l in lines){
        NSArray *words  = [l componentsSeparatedByString:@" "];
        NSString *line = @"";

        for (NSString *s in words){
            
            if (![self garbage:s]){
                NSLog(@"%@",s);
                line = [NSString stringWithFormat:@"%@ %@",line,s];
            }
        }
        
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([line length] > 0)
          [cleanLines addObject:line];
    }
    lines = nil;
    NSError *error;
    NSRegularExpression *personName =
    [NSRegularExpression regularExpressionWithPattern:
     @"(([A-Z].?\s?)*([A-Z][a-z]+\s?)+)" options:0 error:&error];
    
    BOOL nameFound = NO;
    long index = 0;
    NSString *name = @"";
    NSString *position = @"";
    for (NSString *l in cleanLines){
        
        NSRange range = NSMakeRange(0, [l length]);
        NSArray *match = [personName matchesInString:l options:0 range:range ];
       
        if ([match count] > 0 && [l length] > 5){
            
            nameFound = YES;
            NSLog(@"%@",l);
            name = l;
            break;
            
        }
        index++;
    }
    if (index < [cleanLines count]){
      position = [cleanLines objectAtIndex:index+1];
    }
    
    NSRegularExpression *companyName =
    [NSRegularExpression regularExpressionWithPattern:
     @"^[.@&]?[a-zA-Z0-9 ]+[ !.@&()]?[ a-zA-Z0-9!()]+" options:0 error:&error];
    for (NSString *c in cleanLines){
        NSRange range = NSMakeRange(0, [c length]);
        NSArray *match = [companyName matchesInString:c options:0 range:range ];
        if ([match count] > 0 ){
            NSLog(@"%@",c);
        }
    }
    
    [pInfo addObject:@[@"Name",name]];
    [pInfo addObject:@[@"Position",position]];
    [pInfo addObject:@[@"Company",@""]];
    [pInfo addObject:@[@"Address",@""]];
    contactInfo = [[NSMutableDictionary alloc] init];
    keys = [[NSMutableArray alloc] init];
    [keys addObject:@"Info"];
    [keys addObject:@"Phone Numbers"];
    [keys addObject:@"Emails"];
    [keys addObject:@"URLs"];
    [contactInfo setValue:pInfo forKey:@"Info"];
    [contactInfo setValue:pNumbers forKey:@"Phone Numbers"];
    [contactInfo setValue:pEmails forKey:@"Emails"];
    [contactInfo setValue:pURLs forKey:@"URLs"];
    // NSLog(@"%@",contactInfo);
}

-(BOOL)GarbageFilter:(NSString*)text{
    BOOL result;
    NSArray *words = [text componentsSeparatedByString:@" "];
    result = NO;
    if (words.count > 15){
        result = YES;
        NSLog(@"Garbage Found : %@",text);
    }
    
    return result;
}

-(BOOL)garbage:(NSString *)text{
    //NSArray *words  = [text componentsSeparatedByString:@" "];
    NSError *error;

    NSRegularExpression *alnum =
        [NSRegularExpression regularExpressionWithPattern:@"[a-z0-9]/i" options:0 error:&error];
    NSRegularExpression *punc =
        [NSRegularExpression regularExpressionWithPattern:@"[[:punct:]]/i" options:0 error:&error];
    NSRegularExpression *repeat =
        [NSRegularExpression regularExpressionWithPattern:@"([^0-9])\1{2,}/" options:0 error:&error];
    NSRegularExpression *upper =
        [NSRegularExpression regularExpressionWithPattern:@"[A-Z]" options:0 error:&error];
    NSRegularExpression *lower =
        [NSRegularExpression regularExpressionWithPattern:@"[a-z]" options:0 error:&error];
    NSRegularExpression *acronym =
        [NSRegularExpression
         regularExpressionWithPattern:@"^\\(?[A-Z0-9\\.-]+('?s)?\\)?[.,:]?$" options:0 error:&error];
    NSRegularExpression *all_alpha =
        [NSRegularExpression regularExpressionWithPattern:@"^[a-z]+$/i" options:0 error:&error];
    NSRegularExpression *consonant =
        [NSRegularExpression
           regularExpressionWithPattern:@"(^y|[bcdfghjklmnpqrstvwxz])/i" options:0 error:&error];
    NSRegularExpression *vowel = [NSRegularExpression
                                  regularExpressionWithPattern:@"([aeiou]|y$)/i"
                                  options:0 error:&error];
    NSRegularExpression *consonant_5 = [NSRegularExpression
                                        regularExpressionWithPattern:@"[bcdfghjklmnpqrstvwxyz]{5}/i"
                                        options:0 error:&error];
    NSRegularExpression *vowel_5     = [NSRegularExpression
                                        regularExpressionWithPattern:@"[aeiou]{5}/i"
                                        options:0 error:&error];
    NSRegularExpression *repeated    =
       [NSRegularExpression
         regularExpressionWithPattern:@"(\\b\\S{1,2}\\s+)(\\S{1,3}\\s+){5,}(\\S{1,2}\\s+)"
         options:0 error:&error];
    NSRegularExpression *singletons  = [NSRegularExpression
                                        regularExpressionWithPattern:@"^[AaIi]$"
                                        options:0 error:&error];
    
    NSArray* matches;
    NSRange range = NSMakeRange(0, [text length]);
    NSRange range2;
    if ([text length] > 1)
     range2 = NSMakeRange(1, [text length]-1);
    
    if ([text length] > 30)
       return YES;
    
    
    if ([repeat matchesInString:text options:0 range:range].count > 0 )
      return YES;
    
    if ([acronym matchesInString:text options:0 range:range].count == 0 &&
        [alnum matchesInString:text options:0 range:range].count <
        [punc matchesInString:text options:0 range:range].count)
        return YES;
    
    if ([text length] > 1){
      if ([punc matchesInString:text options:0 range:range2].count >= 3)
         return YES;
    }
    if ([vowel_5 matchesInString:text options:0 range:range].count > 0 ||
        [consonant_5 matchesInString:text options:0 range:range].count > 0)
        return YES;
    
    if ([acronym matchesInString:text options:0 range:range].count == 0 &&
        [upper matchesInString:text options:0 range:range].count >
        [lower matchesInString:text options:0 range:range].count)
        return YES;
    

    if ([text length] == 1 && ([singletons matchesInString:text options:0 range:range].count == 0))
        return YES;

    if ([acronym matchesInString:text options:0 range:range].count == 0 &&
        [vowel matchesInString:text options:0 range:range].count >
        ([consonant matchesInString:text options:0 range:range].count * 8))
        return YES;
    
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return contactInfo.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[contactInfo objectForKey:[keys objectAtIndex:section]] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [keys objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellTableIdentifier = @"ReaderResultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellTableIdentifier forIndexPath:indexPath];
    
    NSArray *data = [contactInfo objectForKey:[keys objectAtIndex:indexPath.section]];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellTableIdentifier];
    }else{
        for(UIView *eachView in [cell subviews])
            [eachView removeFromSuperview];
    }
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0,0,100,cell.frame.size.height)];
    lbl.backgroundColor = [UIColor colorWithRed:33.0f/255.0f green:122.0f/255.0f blue:250.0f/255.0f alpha:1.0];
    lbl.textColor= [UIColor whiteColor];
    [lbl setFont:[UIFont systemFontOfSize:13]];
    
    NSString *strLabel = [NSString stringWithFormat:@"  %@",[[data objectAtIndex:indexPath.row]objectAtIndex:0]];
    
    if ([[keys objectAtIndex:indexPath.section]  isEqual: @"Info"]){
        UITextField *txt = [[UITextField alloc] initWithFrame:CGRectMake(110,0,cell.frame.size.width-110,cell.frame.size.height)];
        [lbl setText:strLabel];
        [txt setText:[[data objectAtIndex:indexPath.row] objectAtIndex:1]];
        txt.keyboardType = UIKeyboardTypeEmailAddress;
        [cell addSubview:lbl];
        [cell addSubview:txt];
    }else if ([[keys objectAtIndex:indexPath.section]  isEqual: @"Emails"]){
        UITextField *txt = [[UITextField alloc] initWithFrame:CGRectMake(110,0,cell.frame.size.width-110,cell.frame.size.height)];
        [txt setFont:[UIFont systemFontOfSize:12]];
        [lbl setText:strLabel];
        [txt setText:[[data objectAtIndex:indexPath.row] objectAtIndex:1]];
        txt.keyboardType = UIKeyboardTypeEmailAddress;
        [cell addSubview:lbl];
        [cell addSubview:txt];
    }else if ([[keys objectAtIndex:indexPath.section]  isEqual: @"Phone Numbers"]){
        UITextField *txt = [[UITextField alloc] initWithFrame:CGRectMake(110,0,cell.frame.size.width-110,cell.frame.size.height)];
        
        [lbl setText:strLabel];
        [txt setText:[[data objectAtIndex:indexPath.row] objectAtIndex:1]];
        txt.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        [cell addSubview:lbl];
        [cell addSubview:txt];
    }else if ([[keys objectAtIndex:indexPath.section]  isEqual: @"URLs"]){
        UITextField *txt = [[UITextField alloc] initWithFrame:CGRectMake(110,0,cell.frame.size.width-110,cell.frame.size.height)];
        [txt setFont:[UIFont systemFontOfSize:12]];
        [lbl setText:strLabel];
        [txt setText:[[data objectAtIndex:indexPath.row] objectAtIndex:1]];
        txt.keyboardType = UIKeyboardTypeURL;
        [cell addSubview:lbl];
        [cell addSubview:txt];
    }
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(IBAction)btnDoneClicked:(UIBarButtonItem *)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
