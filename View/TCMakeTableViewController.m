//
//  TCMakeTableViewController.m
//  TrueCar
//
//  Created by Finucane on 8/2/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "TCMakeTableViewController.h"
#import "TCCraigslistTableViewController.h"
#import "insist.h"

static NSString*const REUSE_ID = @"reuseID";
static NSString*const CRAIGSLIST_SEGUE_ID = @"craigslistSegueID";

@implementation TCMakeTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  insist (self.make);
  self.navigationItem.title = self.make.make;
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return self.make.years.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  insist (self.make);
  insist (section >= 0 && section < self.make.years.count);
  
  return [self.make.years [section] models].count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  insist (self.make);
  insist (section >= 0 && section < self.make.years.count);
  
  TCYear*year = self.make.years [section];
  return year.year;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:REUSE_ID forIndexPath:indexPath];
  insist (cell);
  
  NSUInteger section = indexPath.section;
  NSUInteger row = indexPath.row;
  insist (section < self.make.years.count);
  
  TCYear*year = self.make.years [section];
  insist (row >= 0 && row < year.models.count);
  
  cell.textLabel.text = year.models [row];
  return cell;
}



#pragma mark - Navigation
/*
  before the segue to the craigslist table view controller, set that view controller's
  craigslist object to a freshly created craiglist corresponding to the row
  that was selected.
*/
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  insist (self.make);
  
  if ([[segue identifier] isEqualToString:CRAIGSLIST_SEGUE_ID])
  {
    TCCraigslistTableViewController*vc = [segue destinationViewController];
    insist (vc);
    
    NSIndexPath*indexPath = [self.tableView indexPathForSelectedRow];

    NSUInteger section = indexPath.section;
    NSUInteger row = indexPath.row;
    insist (section < self.make.years.count);

    TCYear*year = self.make.years [section];
    insist (row >= 0 && row < year.models.count);

    vc.craigslist = [[TCCraigslist alloc] initWithMake:self.make.make model:year.models [row] year:year.year];
  }
}


@end
