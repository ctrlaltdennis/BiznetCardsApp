//
//  WalletTableViewController.m
//  BiznetCards
//
//  Created by TheApp4U on 3/12/15.
//  Copyright (c) 2015 BiznetCards. All rights reserved.
//

#import "WalletTableViewController.h"
#import "ImageCache.h"

@interface WalletTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *txtSearch;

@end

@implementation WalletTableViewController
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
NSMutableDictionary *sections;
NSArray *keys;
UIView *cardPanel;
UIActivityIndicatorView *indicator;
UILabel *label;
NSMutableArray  *contacts;
long sec;
long i;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    sections = [[NSMutableDictionary alloc] init];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self addressBookRoutines:addressBookRef];
    }
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,40)];
    [keyboardDoneButtonView setItems: [NSArray arrayWithObjects:
                                       [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(keyDoneClicked:)],
                                       nil]];
    
    self.txtSearch.delegate = (id<UISearchBarDelegate>)self;
    self.txtSearch.inputAccessoryView = keyboardDoneButtonView;
    [self configureIndicator];
    [self setTransitioningDelegate:(id<UIViewControllerTransitioningDelegate>)self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return  [[sections objectForKey:[keys objectAtIndex:section]] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return keys;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [keys objectAtIndex:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *cellTableIdentifier = @"personCellTemplate";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellTableIdentifier];
   
    NSArray *contacts = [sections objectForKey:[keys objectAtIndex:indexPath.section]];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellTableIdentifier];
        NSString *person_name = [NSString stringWithFormat:@"%@ %@",
                                 [[contacts objectAtIndex:indexPath.row] valueForKey:@"first_name"],
                                 [[contacts objectAtIndex:indexPath.row] valueForKey:@"last_name"]];
        
        UILabel *name = (UILabel *)[cell.contentView viewWithTag:10];
        UILabel *company = (UILabel *)[cell.contentView viewWithTag:11];
        UILabel *title = (UILabel *)[cell.contentView viewWithTag:12];
        UIImageView *img = (UIImageView *)[cell.contentView viewWithTag:13];
        
        [name setText:person_name];
        [company setText:[[contacts objectAtIndex:indexPath.row] valueForKey:@"company"]];
        [title setText:[[contacts objectAtIndex:indexPath.row] valueForKey:@"title"]];
        NSString *url = [NSString stringWithFormat:@"%@/img/icon.png",
                         [[contacts objectAtIndex:indexPath.row] valueForKey:@"url"]];
        if ([[ImageCache sharedImageCache] DoesExist:url] == true){
            img.image = [[ImageCache sharedImageCache] GetImage:url];
        }
        else{
            
            
            dispatch_queue_t queue = dispatch_queue_create("openImageQueue", NULL);
            dispatch_async(queue, ^{

                NSData * data = [[NSData alloc] initWithContentsOfURL:
                                 [NSURL URLWithString:url]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    // WARNING: is the cell still using the same data by this point??
                    img.image = [UIImage imageWithData: data];
                    [[ImageCache sharedImageCache] AddImage:url :img.image];
                });
                data = nil;
            });
            
        }
        
    }else{
        NSString *person_name = [NSString stringWithFormat:@"%@ %@",
                                 [[contacts objectAtIndex:indexPath.row] valueForKey:@"first_name"],
                                 [[contacts objectAtIndex:indexPath.row] valueForKey:@"last_name"]];
        
        UILabel *name = (UILabel *)[cell.contentView viewWithTag:10];
        UILabel *company = (UILabel *)[cell.contentView viewWithTag:11];
        UILabel *title = (UILabel *)[cell.contentView viewWithTag:12];
        UIImageView *img = (UIImageView *)[cell.contentView viewWithTag:13];
        NSString *url = [NSString stringWithFormat:@"%@/img/icon.png",
                         [[contacts objectAtIndex:indexPath.row] valueForKey:@"url"]];
        
        [name setText:person_name];
        [company setText:[[contacts objectAtIndex:indexPath.row] valueForKey:@"company"]];
        [title setText:[[contacts objectAtIndex:indexPath.row] valueForKey:@"title"]];
        if ([[ImageCache sharedImageCache] DoesExist:url] == true){
            img.image = [[ImageCache sharedImageCache] GetImage:url];
        }
        else{
            dispatch_queue_t queue = dispatch_queue_create("openImageQueue", NULL);
            dispatch_async(queue, ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL:
                                 [NSURL URLWithString:url]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    // WARNING: is the cell still using the same data by this point??
                    img.image = [UIImage imageWithData: data];
                    [[ImageCache sharedImageCache] AddImage:url :img.image];
                });
                data = nil;
            });
            
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    i = indexPath.row;
    sec = indexPath.section;
    [self.txtSearch resignFirstResponder];
    [self createCardView:indexPath.row :indexPath.section];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle) editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *contacts = [sections objectForKey:[keys objectAtIndex:indexPath.section]];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [self removeContact:[[contacts objectAtIndex:indexPath.row] valueForKey:@"ab_id"]];
        [contacts removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
    
}

-(void)addressBookRoutines:(ABAddressBookRef)addressBookRef{
    contacts = [[NSMutableArray alloc]init];
    NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    for (id record in allContacts){
        
        NSMutableDictionary *contact = [[NSMutableDictionary alloc]init];
        
        ABRecordRef thisContact = (__bridge ABRecordRef)record;
        NSString * lastname = (__bridge NSString *)ABRecordCopyValue( thisContact,kABPersonLastNameProperty );
        NSString * first_name = (__bridge NSString *)ABRecordCopyValue( thisContact, kABPersonFirstNameProperty );

        NSString * company = (__bridge NSString *)ABRecordCopyValue( thisContact, kABPersonOrganizationProperty );
        NSString * job = (__bridge NSString *)ABRecordCopyValue( thisContact, kABPersonJobTitleProperty);
        ABRecordID ab_id = ABRecordGetRecordID(thisContact);
        ABMultiValueRef address = ABRecordCopyValue( thisContact, kABPersonAddressProperty);
        ABMultiValueRef phones = ABRecordCopyValue( thisContact, kABPersonPhoneProperty);
        ABMultiValueRef urls = ABRecordCopyValue(thisContact,kABPersonURLProperty);
        ABMultiValueRef emails = ABRecordCopyValue( thisContact, kABPersonEmailProperty);
   
        NSMutableArray *URLs = [[NSMutableArray alloc] init];
        
        for(CFIndex i=0;i<ABMultiValueGetCount(urls);++i) {
            CFStringRef urlRef = ABMultiValueCopyValueAtIndex(urls, i);
            NSString *url = (__bridge NSString *)urlRef;
            
            [URLs addObject:url];
        }
        NSString *url = @"";
        if (URLs.count>0){
          url = [URLs objectAtIndex:0];
          BOOL biznet = NO;
          if (IS_OS_8_OR_LATER){
             if ([url containsString:@"biznetcards.com/zappcards/"])
                 biznet = YES;
          }else{
            if ([url rangeOfString:@"biznetcards.com/zappcards/"].location != NSNotFound)
                 biznet = YES;
          }
          NSString *street = @"";
          NSString *city = @"";
          NSString *zipcode = @"";
          NSString *saddress = @"";
          NSString *tel = @"";
          NSString *mobile = @"";
          NSString *email = @"";
            
          if (biznet){
            if (ABMultiValueGetCount(address) > 0) {
                  CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(address, 0);
                  street = CFDictionaryGetValue(dict,kABPersonAddressStreetKey);
                  city = CFDictionaryGetValue(dict, kABPersonAddressCityKey);
                  zipcode = CFDictionaryGetValue(dict, kABPersonAddressZIPKey);
                  if (street == NULL) street = @"";
                  saddress = [NSString stringWithFormat:@"%@,\n%@, %@",street,city,zipcode];
            }
            if (ABMultiValueGetCount(phones) > 0) {
                CFStringRef temp = ABMultiValueCopyValueAtIndex(phones, 0);
                tel = (__bridge NSString*)temp;
                CFStringRef temp1 = ABMultiValueCopyValueAtIndex(phones, 1);
                mobile = (__bridge NSString*)temp1;
            }
            if (ABMultiValueGetCount(emails) > 0) {
                  CFStringRef temp = ABMultiValueCopyValueAtIndex(emails, 0);
                  email = (__bridge NSString*)temp;
            }
              
            if (url == nil) url = @"";
            if (email == nil) email = @"";
            if (tel == nil) tel = @"";
            if (mobile == nil) mobile = @"";
            if (saddress == nil) saddress = @"";
            if (first_name == nil) first_name = @"";
            if (lastname == nil) lastname = @"";
            if (company == nil) company = @"";
            if (job == nil) job = @"";

              
            [contact setObject:url forKey:@"url"];
            [contact setObject:email forKey:@"email"];
            [contact setObject:tel forKey:@"tel"];
            [contact setObject:mobile forKey:@"mobile"];
            [contact setObject:saddress forKey:@"address"];
            [contact setObject:first_name forKey:@"first_name"];
            [contact setObject:lastname forKey:@"last_name"];
            [contact setObject:company forKey:@"company"];
            [contact setObject:job forKey:@"title"];
            [contact setObject:[NSString stringWithFormat:@"%d",ab_id] forKey:@"ab_id"];
            [contacts addObject:contact];
            
          }
        }
   }
   
   for(int i=0;i<contacts.count;i++){
       
       NSString *key = [NSString stringWithFormat:@"%c",[[[contacts objectAtIndex:i] valueForKey:@"last_name"] characterAtIndex:0]];
       if (key != nil){
         if ([sections valueForKey:key] == NULL)
           [sections setObject:@"temp" forKey:key];
       }
   }
    
    NSArray *temp = [[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    keys = temp;
    sections = [[NSMutableDictionary alloc] init];
    for (int i = 0; i< temp.count; i++){
        NSMutableArray *tempA = [[NSMutableArray alloc] init];

        for (int j = 0; j< contacts.count;j++){
             NSString *k = [NSString stringWithFormat:@"%c",[[[contacts objectAtIndex:j] valueForKey:@"last_name"] characterAtIndex:0]];
            if ([[temp objectAtIndex:i] isEqual:k]){
                [tempA addObject:[contacts objectAtIndex:j]];
            }
            [sections setValue:tempA forKey:[temp objectAtIndex:i]];
        }
    }

   if (addressBookRef != nil)
     CFRelease(addressBookRef);
}

-(void)createCardView:(long)index : (long)section{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat y = 40;

    if (IS_OS_8_OR_LATER){
      
      UIVisualEffect *blurEffect;
  
      blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
      cardPanel = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
      cardPanel.frame = CGRectMake(0,0,width,height);
      
    }else{
      cardPanel = [[UIView alloc] initWithFrame:CGRectMake(0,0,width,height)];
      cardPanel.backgroundColor = [UIColor whiteColor];
    }
    //cardPanel.alpha = 0.8;
    NSMutableArray *contacts = [sections objectForKey:[keys objectAtIndex:section]];
    UIImageView *imgLogo = [[UIImageView alloc] init];
    imgLogo.frame = CGRectMake((width/2)-75, y, 150, 150);
    NSString *url = [NSString stringWithFormat:@"%@/img/icon.png",[[contacts objectAtIndex:index] valueForKey:@"url"]];
    if ([[ImageCache sharedImageCache] DoesExist:url] == true){
        imgLogo.image = [[ImageCache sharedImageCache] GetImage:url];
    }
    y+= 160;
    UILabel *person_name = [[UILabel alloc] initWithFrame:CGRectMake(0,y,width,50)];
    person_name.text = [NSString stringWithFormat:@"%@ %@",
                        [[contacts objectAtIndex:index] valueForKey:@"first_name"],
                        [[contacts objectAtIndex:index] valueForKey:@"last_name"]];
    person_name.font = [UIFont boldSystemFontOfSize:20];
    person_name.textAlignment = NSTextAlignmentCenter;
    if (IS_OS_8_OR_LATER)
        person_name.textColor = [UIColor whiteColor];
    y += 25;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0,y,width,50)];
    title.text = [[contacts objectAtIndex:index] valueForKey:@"title"];
    title.textAlignment = NSTextAlignmentCenter;
    if (IS_OS_8_OR_LATER)
        title.textColor = [UIColor whiteColor];
    y += 55;
    UILabel *company = [[UILabel alloc] initWithFrame:CGRectMake(0,y,width,50)];
    company.text = [[contacts objectAtIndex:index] valueForKey:@"company"];
    company.textAlignment = NSTextAlignmentCenter;
    company.font = [UIFont boldSystemFontOfSize:18];
    if (IS_OS_8_OR_LATER)
        company.textColor = [UIColor whiteColor];
    y += 30;
    UILabel *address = [[UILabel alloc] initWithFrame:CGRectMake(0,y,width,50)];
    address.text = [[contacts objectAtIndex:index] valueForKey:@"address"];
    address.textAlignment = NSTextAlignmentCenter;
    address.numberOfLines = 0;
    if (IS_OS_8_OR_LATER)
        address.textColor = [UIColor whiteColor];
    UIButton *tel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    tel.frame = CGRectMake(0,5,50,50);
    [tel setImage:[UIImage imageNamed:@"call11"] forState:UIControlStateNormal];
    [tel addTarget:self
                  action:@selector(telClicked:)
        forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *mobile = [UIButton buttonWithType:UIButtonTypeRoundedRect];
 
    mobile.frame = CGRectMake(50,5,50,50);
    [mobile setImage:[UIImage imageNamed:@"smart1"] forState:UIControlStateNormal];
    [mobile addTarget:self
            action:@selector(mobileClicked:)
            forControlEvents:UIControlEventTouchUpInside];
    UIButton *sms = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sms.frame = CGRectMake(105,5,50,50);
    [sms setImage:[UIImage imageNamed:@"chat26"] forState:UIControlStateNormal];
    [sms addTarget:self
               action:@selector(smsClicked:)
     forControlEvents:UIControlEventTouchUpInside];
    UIButton *email = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    email.frame = CGRectMake(160,5,50,50);
    [email setImage:[UIImage imageNamed:@"mail21"] forState:UIControlStateNormal];
    [email addTarget:self
            action:@selector(emailClicked:)
       forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *share = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    share.frame = CGRectMake(215,5,50,50);
    [share setImage:[UIImage imageNamed:@"arrow423"] forState:UIControlStateNormal];
    [share addTarget:self
              action:@selector(shareClicked:)
    forControlEvents:UIControlEventTouchUpInside];
    
    y += 70;
    UIView *btnPanel = [[UIView alloc] initWithFrame:
                        CGRectMake((width/2)-130, y, 250, 60)];
    y += 70;
    UIButton *view_card = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    view_card.frame = CGRectMake((width/2) - 75,y,150,50);
    [view_card setTitle:@"View Card" forState:UIControlStateNormal];
    [view_card.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
    
    [view_card addTarget:self
                 action:@selector(viewCard:)
       forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    y+= 60;
    [btnClose setTitle:@"Close" forState:UIControlStateNormal];
    btnClose.frame = CGRectMake(((width / 2)-50),y,100,40);
    btnClose.layer.cornerRadius = 5;
    btnClose.backgroundColor = [UIColor blackColor];
    
    [btnClose addTarget:self
                 action:@selector(closeClick:)
       forControlEvents:UIControlEventTouchUpInside];
    
    [cardPanel addSubview:imgLogo];
    [cardPanel addSubview:person_name];
    [cardPanel addSubview:title];
    [cardPanel addSubview:company];
    [cardPanel addSubview:address];

    [btnPanel addSubview:tel];
    [btnPanel addSubview:mobile];
    [btnPanel addSubview:sms];
    [btnPanel addSubview:email];
    [btnPanel addSubview:share];
    
    [cardPanel addSubview:btnPanel];
    [cardPanel addSubview:view_card];
    [cardPanel addSubview:btnClose];

    [self.navigationController.view addSubview:cardPanel];
}
-(void)removeContact:(id)ab_id{
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    int Id = [ab_id integerValue];
    ABRecordRef c = ABAddressBookGetPersonWithRecordID (addressBookRef,Id);
    CFErrorRef *error=nil;
    ABAddressBookRemoveRecord(addressBookRef, c, error);
    ABAddressBookSave(addressBookRef, error);
    if (addressBookRef != nil){
        CFRelease(addressBookRef);
    }
}

-(IBAction)closeClick:(id)sender{
    cardPanel.hidden=YES;
}

-(IBAction)doneClicked:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)viewCard:(id)sender{
    
    NSString *url =
       [[[sections objectForKey:[keys objectAtIndex:sec]] objectAtIndex:i] valueForKey:@"url"];
    
   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

-(IBAction)telClicked:(id)sender{
    NSString *url = [NSString stringWithFormat:@"tel:%@",[[[sections objectForKey:[keys objectAtIndex:sec]] objectAtIndex:i] valueForKey:@"tel"]];
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

-(IBAction)mobileClicked:(id)sender{
    NSString *url = [NSString stringWithFormat:@"tel:%@",[[[sections objectForKey:[keys objectAtIndex:sec]] objectAtIndex:i] valueForKey:@"mobile"]];
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

-(IBAction)smsClicked:(id)sender{
    NSString *url = [NSString stringWithFormat:@"sms:%@",[[[sections objectForKey:[keys objectAtIndex:sec]] objectAtIndex:i] valueForKey:@"mobile"]];
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

-(IBAction)emailClicked:(id)sender{
    NSString *url = [NSString stringWithFormat:@"mailto:%@",[[[sections objectForKey:[keys objectAtIndex:sec]] objectAtIndex:i] valueForKey:@"email"]];
    url = [url stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
-(IBAction)shareClicked:(id)sender{
    [self showIndicator];
    label.text = @"Please Wait...";
    NSURL *url = [NSURL  URLWithString:[[[sections objectForKey:[keys objectAtIndex:sec]] objectAtIndex:i] valueForKey:@"url"]];
    NSArray *itemsToShare = @[url];
    dispatch_queue_t queue = dispatch_queue_create("openActivityIndicatorQueue", NULL);
    
    // send initialization of UIActivityViewController in background
    dispatch_async(queue, ^{
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        
        [activityVC setValue:@"Don't Print It - Phone It!" forKey:@"subject"];
        // when UIActivityViewController is finally initialized,
        // hide indicator and present it on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideIndicator];
            [self presentViewController:activityVC animated:YES completion:nil];
        });
    });
   
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
- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar {
    [theSearchBar resignFirstResponder];
}
-(void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar{
    [theSearchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    searchText = [searchText lowercaseString];
    NSMutableArray *filtered = [[NSMutableArray alloc] init];
    if ([searchText length] > 0){
        for (NSDictionary *rec in contacts){
          if (IS_OS_8_OR_LATER){
            if ([[[rec valueForKey:@"first_name"] lowercaseString] containsString:searchText] ||
                [[[rec valueForKey:@"last_name"] lowercaseString] containsString:searchText] ||
                [[[rec valueForKey:@"email"] lowercaseString] containsString:searchText] ||
                [[[rec valueForKey:@"mobile"] lowercaseString] containsString:searchText] ||
                [[[rec valueForKey:@"tel"] lowercaseString] containsString:searchText] ||
                [[[rec valueForKey:@"email"] lowercaseString] containsString:searchText] ||
                [[[rec valueForKey:@"address"] lowercaseString] containsString:searchText] ||
                [[[rec valueForKey:@"company"] lowercaseString] containsString:searchText] ||
                [[[rec valueForKey:@"title"] lowercaseString] containsString:searchText]){
                [filtered addObject:rec];
            }
          }else{
              if ([[[rec valueForKey:@"first_name"] lowercaseString] rangeOfString:searchText].location != NSNotFound ||
                  [[[rec valueForKey:@"last_name"] lowercaseString] rangeOfString:searchText].location != NSNotFound ||
                  [[[rec valueForKey:@"email"] lowercaseString]  rangeOfString:searchText].location != NSNotFound ||
                  [[[rec valueForKey:@"mobile"] lowercaseString]  rangeOfString:searchText].location != NSNotFound ||
                  [[[rec valueForKey:@"tel"] lowercaseString]  rangeOfString:searchText].location != NSNotFound ||
                  [[[rec valueForKey:@"email"] lowercaseString] rangeOfString:searchText].location != NSNotFound ||
                  [[[rec valueForKey:@"address"] lowercaseString] rangeOfString:searchText].location != NSNotFound ||
                  [[[rec valueForKey:@"company"] lowercaseString] containsString:searchText] ||
                  [[[rec valueForKey:@"title"] lowercaseString] containsString:searchText]){
                  [filtered addObject:rec];
              }

          }
        }
    }else{
        filtered = contacts;
    }
    
    NSMutableDictionary *ts = [[NSMutableDictionary alloc] init];
    for(int i=0;i<filtered.count;i++){
        
        NSString *key = [NSString stringWithFormat:@"%c",[[[filtered objectAtIndex:i] valueForKey:@"last_name"] characterAtIndex:0]];
        if (key != nil){
            if ([ts valueForKey:key] == NULL)
                [ts setObject:@"temp" forKey:key];
        }
    }
    
    NSArray *temp = [[ts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    keys = temp;
    sections = [[NSMutableDictionary alloc] init];
    for (int i = 0; i< temp.count; i++){
        NSMutableArray *tempA = [[NSMutableArray alloc] init];
        
        for (int j = 0; j< filtered.count;j++){
            NSString *k = [NSString stringWithFormat:@"%c",[[[filtered objectAtIndex:j] valueForKey:@"last_name"] characterAtIndex:0]];
            if ([[temp objectAtIndex:i] isEqual:k]){
                [tempA addObject:[filtered objectAtIndex:j]];
            }
            [sections setValue:tempA forKey:[temp objectAtIndex:i]];
        }
    }
    [self.tableView reloadData];
    if ([searchText length] == 0){
        [searchBar resignFirstResponder];
    }
}
-(IBAction)keyDoneClicked:(id)sender{
    [self.txtSearch resignFirstResponder];
}
-(IBAction)OCRClicked:(id)sender{

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ocrView"];
    [self presentViewController:vc animated:true completion:nil];
}
@end
