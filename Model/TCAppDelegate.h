//
//  TCAppDelegate.h
//  TrueCar
//
//  Created by Finucane on 7/31/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCCars.h"

extern NSString*const kTCCarsNotification;

@interface TCAppDelegate : UIResponder <UIApplicationDelegate>

@property (readonly) TCCars*cars;
@property (strong, nonatomic) UIWindow*window;

#define App ((TCAppDelegate*)[UIApplication sharedApplication].delegate)

@end
