//
//  TCCarsTableViewController.m
//  TrueCar
//
//  Created by Finucane on 8/2/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "TCCarsTableViewController.h"
#import "TCMakeTableViewController.h"
#import "TCAppDelegate.h"
#import "insist.h"

static NSString*const REUSE_ID = @"reuseID";
static NSString*const MAKE_SEGUE_ID = @"makeSegueID";

@implementation TCCarsTableViewController


/*
 when we're loaded, start listening for the notification that happens when new car data
 is read in from the csv file.
 */
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [[NSNotificationCenter defaultCenter] addObserverForName:kTCCarsNotification
                                                    object:App
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification*n) {
                                                  
                                                  [self.tableView reloadData];
                                                }];
}


/*
 on dealloc, stop listening for the notification
 */
-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kTCCarsNotification object:nil];
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return App.cars.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:REUSE_ID forIndexPath:indexPath];
  insist (cell);
  
  NSUInteger row = indexPath.row;
  insist (row >= 0 && row < App.cars.count);
  
  cell.textLabel.text = [App.cars makeAtIndex:row].make;
  return cell;
}


#pragma mark - Navigation


/*
  before seguing to a make tableview controller, set the view controller's make property
  so it has data to use to load itself with.
*/
- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:MAKE_SEGUE_ID])
  {
    TCMakeTableViewController*vc = [segue destinationViewController];
    insist (vc);
    
    NSUInteger row = [self.tableView indexPathForSelectedRow].row;
    insist (row >= 0 && row < App.cars.count);
    
    vc.make = [App.cars makeAtIndex:row];
  }
}
  @end
