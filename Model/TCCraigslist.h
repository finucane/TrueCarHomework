//
//  TCCraigslist.h
//  TrueCar
//
//  Created by Finucane on 7/31/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCCraigslistItem.h"

typedef void (^TCCraigslistQueryProgressBlock)(BOOL done, NSError*error);

@interface TCCraigslist : NSObject
{
  @private
  NSURLSession*_session;
  TCCraigslistQueryProgressBlock _block;
  NSString*_queryString;
  NSMutableArray*_items;
  dispatch_queue_t _concurrentQueue;
}

-(instancetype)initWithMake:(NSString*)make model:(NSString*)model year:(NSString*)year;
-(void)queryWithProgressBlock:(TCCraigslistQueryProgressBlock)block;
-(NSUInteger)count;
-(TCCraigslistItem*)itemAtIndex:(NSUInteger)index;
-(void)cancel;

@end
