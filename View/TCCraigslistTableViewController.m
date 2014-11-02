//
//  TCCraigslistTableViewController.m
//  TrueCar
//
//  Created by Finucane on 8/2/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "TCCraigslistTableViewController.h"
#import "TCCraigslistItemViewController.h"
#import "TCCraigslistTableViewCell.h"
#import "UIAlertView+Additions.h"
#import "insist.h"

static NSString*const REUSE_ID = @"reuseID";
static NSString*const CRAIGSLIST_ITEM_SEGUE_ID = @"craigslistItemSegueID";
static CGFloat const CELL_HEIGHT_WITH_LOCATION = 125.0;
static CGFloat const CELL_HEIGHT_WITHOUT_LOCATION = 100.0;

@implementation TCCraigslistTableViewController

/*
 when the view is loaded, start the craigslist query
 */
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  insist (self.craigslist);
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [self.craigslist queryWithProgressBlock:^(BOOL done, NSError*error) {
    
    dispatch_async (dispatch_get_main_queue(), ^{
      
      if (error)
      {
        [UIAlertView showAlertWithTitle:NSLocalizedString(@"Craigslist Error", nil) message:error.localizedDescription];
      }
      if (done)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
      
      [self.tableView reloadData];
    });
    
  }];
}

/*
  if we are being popped off the navigation stack, cancel any craigslist query that might be running
*/
-(void)viewWillDisappear:(BOOL)animated
{
  if ([self isMovingFromParentViewController])
  {
    [self.craigslist cancel];
  }
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  insist (section == 0);
  insist (self.craigslist);
  return self.craigslist.count;
}

/*
  return the cell height which depends on if the item has a location or not.
  this hardcoded stuff is bad. 
 
  a better way would be to make 2 kinds of custom table view cells.
*/

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  NSUInteger row = indexPath.row;
  insist (row < self.craigslist.count);
  TCCraigslistItem*item = [self.craigslist itemAtIndex:row];
  insist (item);
  
  return item.location.length ? CELL_HEIGHT_WITH_LOCATION : CELL_HEIGHT_WITHOUT_LOCATION;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  insist (self.craigslist);
  
  TCCraigslistTableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:REUSE_ID forIndexPath:indexPath];
  insist (cell);
  
  NSUInteger row = indexPath.row;
  insist (row < self.craigslist.count);
  TCCraigslistItem*item = [self.craigslist itemAtIndex:row];
  insist (item);
  
  cell.title.text = item.title;
  cell.price.text = item.price;
  cell.date.text = item.date;
  cell.location.text = item.location;
  
  return cell;
}


#pragma mark - Navigation

/*
  before we segue to the craigslist item view controller, set that view controller's url string
*/

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:CRAIGSLIST_ITEM_SEGUE_ID])
  {
    TCCraigslistItemViewController*vc = [segue destinationViewController];
    insist (vc);
    
    NSIndexPath*indexPath = [self.tableView indexPathForSelectedRow];
    
    NSUInteger row = indexPath.row;
    insist (row < self.craigslist.count);
    TCCraigslistItem*item = [self.craigslist itemAtIndex:row];
    insist (item);
    vc.url = item.url;
    vc.navigationItem.title = item.title;
  }
}


@end
