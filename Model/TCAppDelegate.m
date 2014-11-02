//
//  TCAppDelegate.m
//  TrueCar
//
//  Created by Finucane on 7/31/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "TCAppDelegate.h"
#import "TCCraigslist.h"
#import "UIAlertView+Additions.h"
#import "insist.h"

NSString*const kTCCarsNotification = @"com.finucane.TrueCar.TCCarsNotification";

@implementation TCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  /*create a TCCars object*/
  NSString*path = [[NSBundle mainBundle] pathForResource:@"Mobile Challenge Assignment Excel" ofType:@"csv"];
  NSURL*url = [NSURL fileURLWithPath:path];
  _cars = [[TCCars alloc] initWithURL:url];
  insist (_cars);
  
  /*
   start the parsing, which happens in the background. when new data is loaded, notify who ever cares
   with a notification. notifications are delivered on the thread they are posted on, so make sure
   we post on the main thread.
   */
  
  [_cars parseWithProgressBlock:^(BOOL done, NSError *error){
    
    dispatch_async (dispatch_get_main_queue(), ^{
      
      if (error)
      {
        [UIAlertView showAlertWithTitle:NSLocalizedString(@"CSV Error", nil) message:error.localizedDescription];
      }
      else
      {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTCCarsNotification object:self userInfo:nil];
      }
      
    });
  }];
  
  return YES;
}

@end
