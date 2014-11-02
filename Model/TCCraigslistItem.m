//
//  TCCraigslistItem.m
//  TrueCar
//
//  Created by Finucane on 7/31/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "TCCraigslistItem.h"

@implementation TCCraigslistItem

/*
  give the string properties some nice default values
*/
-(instancetype)init
{
  if ((self = [super init]))
  {
    _title = @"";
    _price = @"";
    _date = @"";
    _location = @"";
  }
  return self;
}
@end
