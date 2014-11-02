//
//  TCCars.m
//  TrueCar
//
//  Created by Finucane on 7/31/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "TCCars.h"
#import "insist.h"
#import "NSError+Additions.h"

/*
 these are just simple classes to give some structure to the make->years->models tree.
 it's guaranteed that they aren't going to be modified when the rest of the app knows
 about them, so there's no threading concerns.
 
 the arrays should be immutable properties in the public interface but for simplicity
 just leave them mutable.
*/

@implementation TCMake

-(instancetype)init
{
  if ((self = [super init]))
  {
    _years = [[NSMutableArray alloc] init];
  }
  return self;
}
@end


@implementation TCYear

-(instancetype)init
{
  if ((self = [super init]))
  {
    _models = [[NSMutableArray alloc] init];
  }
  return self;
}

@end

/*
 TCCars is a class that represents data from the programming challenge's input file. it parses
 the csv file in the background and lets callers get at the data as it is read. the granularity
 of the rest of the app knowing about new data being read is at the "make" level. in other words
 each new make that is read in results in some kind of callback.
 */
@implementation TCCars

/*
 init method
 
 url - path to csv file
 
 returns - instance of TCCars
 */
-(instancetype)initWithURL:(NSURL*)url
{
  insist (url);
  
  if ((self = [super init]))
  {
    /*make a CHCSVParser to parse the csv file and set it to remove "'s, and also trim.*/
    _parser = [[CHCSVParser alloc] initWithContentsOfCSVURL:url];
    insist (_parser);
    _parser.sanitizesFields = YES;
    _parser.delegate = self;
    
    /*make the makes array and also the queue to protect it across threads with*/
    _makes = [[NSMutableArray alloc] init];
    insist (_makes);
    
    _concurrentQueue = dispatch_queue_create("com.finucane.TrueCar.TCCars", DISPATCH_QUEUE_CONCURRENT);
    insist (_concurrentQueue);
    
    /*
      make a dictionary to collect years in as we read them. since in the csv file
      the years are interleaved and not sorted the way the makes are.
     */
    _years = [[NSMutableDictionary alloc] init];
    insist (_years);
    
  }
  return self;
}

/*
 start the csv parse on a background queue
*/
-(void)parseWithProgressBlock:(TCCarsProgressBlock)block
{
  insist (block);
  _block = block;
  
  /*set this to ignore fields until we've scanned the 1st line, which is a header and not data*/
  ignoreParsing = YES;
  
  dispatch_async (dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [_parser parse];
  });
}

/*
 get number of makes read so far
 
 returns - count of makes read
 */
-(NSUInteger)count
{
  __block NSUInteger count;
  dispatch_sync (_concurrentQueue, ^{
    count = _makes.count;
  });
  return count;
}

/*
 get a make
 
 index - index of make to return
 
 returns - a make
 */
-(TCMake*)makeAtIndex:(NSUInteger)index
{
  __block TCMake*make;
  dispatch_sync (_concurrentQueue, ^{
    insist (index < _makes.count);
    make = _makes [index];
  });
  return make;
}

/*
  convenience method to call whenever we encounter a parse error.
  cancels the parsing and reports error to caller.
 
  description - human readable message
*/
-(void)abortWithDescription:(NSString*)description
{
  insist (_block);
  [_parser cancelParsing];
  _block (YES, [NSError errorWithCode:0 description:description]);
}
          
/*
 read in a make string.
 in these "handle" methods which read each field from the parser we make sure
 to copy the strings for our own data structure because we have no idea what the parser
 might do to the underlying strings.
 
 field - field from csv file, trimmed and dequoted
*/

-(void)handleMake:(NSString*)field
{
  /*
   if the make string is different from the last one we've read, it means we are starting a new make
   section in the csv file, and we should create a new make object for it.
   */

  BOOL newSection = NO;
  
  newSection = _make ? [_make.make caseInsensitiveCompare:field] != NSOrderedSame : YES;
  
  /*if it's a new make string, add a new make object to our list*/
  if (newSection)
  {
    /*if there was a previous make being read, add it to the array and notify the caller*/

    if (_make)
    {
      [self finishMake];
      _block (NO, nil);
    }
    
    /*reset the years dictionary so we can use it to collect the new make's years*/
    insist (_years);
    [_years removeAllObjects];
    
    _make = [[TCMake alloc] init];
    insist (_make);
    _make.make = [field copy];
  }
}

/*
  read in a year string
 
  field - field from csv file, trimmed and dequoted
*/
-(void)handleYear:(NSString*)field
{
  if (!_make)
  {
    [self abortWithDescription:NSLocalizedString(@"CSV Parse error, unexpected year", nil)];
    return;
  }

  insist (_years);

  _year = _years [field];
  if (!_year)
  {
    _year = [[TCYear alloc] init];
    insist (_year);
    _year.year = [field copy];
    _years [field] = _year;
  }
}

/*
 read in a model string. allow duplicates
 
 field - field from csv file, trimmed and dequoted
*/
-(void)handleModel:(NSString*)field
{
  if (!_make || !_year)
  {
    [self abortWithDescription:NSLocalizedString(@"CSV Parse error, unexpected model", nil)];
    return;
  }

  insist (_year.models);
  
  [_year.models addObject:[field copy]];
}


#pragma mark - CHCSVParserDelegate methods

- (void)parser:(CHCSVParser*)parser didBeginLine:(NSUInteger)recordNumber
{
  /*skip first line, numbering apparently starts at 1*/
  if (recordNumber > 1)
    ignoreParsing = NO;
}
-(void)parser:(CHCSVParser*)parser didReadField:(NSString*)field atIndex:(NSInteger)fieldIndex
{
  insist (_makes);
  
  if (ignoreParsing)
    return;
  
  switch (fieldIndex)
  {
    case 0:
      [self handleMake:field];
      break;
    case 1:
      [self handleYear:field];
      break;
    case 2:
      [self handleModel:field];
      break;
    default:
      [self abortWithDescription:NSLocalizedString(@"CSV parse error", nil)];
      break;
  }
}

/*
  when we're done, tell the caller
*/
-(void)parserDidEndDocument:(CHCSVParser*)parser
{
  if (_make)
  {
    [self finishMake];
  }
  _block (YES, nil);
}

/*
  finish setting up the current make, by copying over the _years information into it
  and by adding it to the _makes array.
 
  in practice this method is called just before _block () is called. when _block ()
  is called the make hasn't been added to the _makes array yet (since that's done asynchronously)
  and yet it's not a race condition, because access to the makes items (including the count)
  happens on the same queue.
*/
-(void)finishMake
{
  insist (_make);
  insist (_years);
  
  /*make an array of years, sorted by year*/
  _make.years = [[_years allValues] sortedArrayUsingComparator:^NSComparisonResult (TCYear*year1, TCYear*year2)
  {
    return [year1.year compare:year2.year];
  }];
  
  /*
    get a reference to the _make because we're going to use it asynchronously and
    self->_make will be changed in the meantime
  */
  __block TCMake*make = _make;
  dispatch_barrier_async (_concurrentQueue , ^{
    [_makes addObject:make];
  });
}
@end
