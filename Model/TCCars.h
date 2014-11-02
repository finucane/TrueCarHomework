//
//  TCCars.h
//  TrueCar
//
//  Created by Finucane on 7/31/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHCSVParser.h"

typedef void (^TCCarsProgressBlock)(BOOL done, NSError*error);

@interface TCMake : NSObject
@property NSString*make;
@property NSArray*years;
@end

@interface TCYear : NSObject
@property NSString*year;
@property NSMutableArray*models;
@end

@interface TCCars : NSObject <CHCSVParserDelegate>
{
  @private
  BOOL ignoreParsing; //to skip 1st line
  TCMake*_make; //the curent make being read in from the csv
  NSMutableDictionary*_years; //to collect models in, while reading the current make
  TCYear*_year;//last read year
  NSMutableArray*_makes;
  CHCSVParser*_parser;
  TCCarsProgressBlock _block;
  dispatch_queue_t _concurrentQueue;
}

-(instancetype)initWithURL:(NSURL*)url;
-(void)parseWithProgressBlock:(TCCarsProgressBlock)block;
-(NSUInteger)count;
-(TCMake*)makeAtIndex:(NSUInteger)index;
@end
