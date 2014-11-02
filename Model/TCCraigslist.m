//
//  TCCraigslist.m
//  TrueCar
//
//  Created by Finucane on 7/31/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

/*
  TCCraigslist encapsulates dealing with getting craigslist results from searching for owner-only sold used
  cars of a certain make, model, and year.
 
  the error reporting is simple since this is a programming assignment. the underlying error is not passed up
  to the caller, instead just a human readable string. Also there's no retrying done at this level. Partly for
  simplicity but also because even in a real app it might not be worth the complexity to implement retrying at
  the individual results page level, rather than just retrying the entire operation (of scraping multiple pages
  of the single result of a query.
 
  the same goes for handling scraping errors, we just bail at the first one. we shouldn't be scraping in an app
  in the first place, but this is a toy...
 
  The page fetches are not parallelized even though they could be, based on how craigslist names its page urls.
  we are scraping (which only a toy app would do in the app itself, and not on a server), so it's not
  any worse to use knowledge of page url naming, but ... for simplicty and the expectation that we aren't really
  going to get tons of results since we are limiting the search, it's not worth the effort to basically .. do it
  right.
*/

#import "TCCraigslist.h"
#import "insist.h"
#import "NSError+Additions.h"
#import "NSScanner+Additions.h"

static NSString*const CRAIGSLIST_ORG_URL = @"http://craigslist.org";

//http_://losangeles.craigslist.org/search/cto?query=fiat&autoMinYear=2013&autoMaxYear=2013&autoMakeModel=500

/*
 we don't know which cragislist site to use (which is closest to the user) until we fetch http://craigslist.org and
 then see what it redirects to. baseURL caches this result. the compiler initializes it to nil.
 */

static NSURL*_baseURL;

@implementation TCCraigslist

-(instancetype)initWithMake:(NSString*)make model:(NSString*)model year:(NSString*)year
{
//  insist (make && make.length && model && model.length && year && year.length);
  
  if ((self = [super init]))
  {
    /*make the query part of the url. we'll use this when we actually do query
     in queryWithProgressBlock:. don't include a leading / separator because we're going
     to compose a complete url with NSURL methods and not string methods.
     */
    
    _queryString = [NSString stringWithFormat:@"search/cto?query=%@&autoMinYear=%@&autoMaxYear=%@&autoMakeModel=%@",
                    [make stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [year stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [year stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                    [model stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    /*make url session to use for networking*/
    _session = [NSURLSession sessionWithConfiguration: [NSURLSessionConfiguration defaultSessionConfiguration]];
    insist (_session);
    
    /*make the array to hold items, and and the gcd queue we'll use to protect it across threads*/
    _items = [[NSMutableArray alloc] init];
    insist (_items);
    
    _concurrentQueue = dispatch_queue_create("com.finucane.TrueCar.TCCraigslist", DISPATCH_QUEUE_CONCURRENT);
    insist (_concurrentQueue);
  }
  return self;
}

/*
  start the craigslist query.
 
  block - block to be called whenever new query results come in. this block looks like this:

  ^(BOOL done, NSError*error)
 
  and: done is true when the entire query is done (including error)
       error is set if there's any error, in which case block will not be called again and done will be set.
 
  the caller can use accessor methods in TCCraigslist to get the actual query result items.
 
*/
-(void)queryWithProgressBlock:(TCCraigslistQueryProgressBlock)block
{
  insist (block);
  _block = block;
  
  if (!_baseURL)
  {
    [self resolveBaseURL];
    return;
  }
  
  [self getFirstPage];
}

/*
  fetch the generic craigslist.org page in order to see what URL it resolves to, which is based on
  the user's location. save that URL in _baseURL. This method is used in a chain of methods, in other words
  it's called before getFirstPage if we haven't got the _baseURL yet. So it eventually calls getFirstPage
  to continue the process of fetching craigslist results. In this (and similar methods) we don't need to
  keep references to any tasks around, because to cancel is implemented by cancelling everying on the session,
  not individual tasks.
*/

-(void)resolveBaseURL
{
  insist (_session && _block);
  
  NSURL*url = [NSURL URLWithString:CRAIGSLIST_ORG_URL];
  insist (url);
  
  NSURLSessionDataTask*task = [_session dataTaskWithURL:url completionHandler:^(NSData*data, NSURLResponse*response, NSError*error){
    
    if (error)
    {
      _block (YES, [NSError errorWithCode:0 description:NSLocalizedString(@"Couldn't determine nearest craigslist site", nil)]);
      return;
    }
    
    /*no error, so we can get the redirected url*/
    insist (response);
    _baseURL = response.URL;
    insist (_baseURL);
    
    /*now we can get the first page*/
    [self getFirstPage];
  }];
  
  insist (task);
  
  [task resume];
}

/*
  get the first page
*/
-(void)getFirstPage
{
  return [self getPage:[NSURL URLWithString:_queryString relativeToURL:_baseURL]];
}

/*
  get a page of craigslist results. scrape its contents and if there's a next page, start getting that too.
 
  url - the url for the craigslist page to get.
*/

-(void)getPage:(NSURL*)url
{
  insist (url);
  
  NSURLSessionDataTask*task = [_session dataTaskWithURL:url completionHandler:^(NSData*data, NSURLResponse*response, NSError*error){
    
    if (error)
    {
      _block (YES, [NSError errorWithCode:0 description:NSLocalizedString(@"Couldn't get page of results", nil)]);
      return;
    }
    
    NSString*html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!html)
    {
      /*craiglist might send us garbage...*/
      _block (YES, [NSError errorWithCode:0 description:NSLocalizedString(@"Couldn't read page of results", nil)]);
      return;
    }
  
    /*scrape the page*/
    NSURL*nextURL;
    BOOL changed;
    if (![self scrapeHTML:html nextURL:&nextURL changed:&changed])
    {
      _block (YES, [NSError errorWithCode:0 description:NSLocalizedString(@"Couldn't scrape page", nil)]);
      return;
    }
    
    /*if there's a next page, get it, otherwise we're done*/
    if (nextURL)
    {
      /*if items were added, notify caller*/
      if (changed)
      {
        _block (NO, nil);
      }
      [self getPage:nextURL];
    }
    else
    {
      _block (YES, nil); // done!
      return;
    }
  }];
  
  insist (task);
  
  [task resume];
}

/*
  scrape a page of craigslist results, accumulating result items. If there's a next page to scrape, return that
  in nextURL.
 
  html - the text of a page to scrape
  nextURL - url for next page, if any
  changed - true if new items were added
 
  returns - YES if there were no errors. (in the implementation we are letting scraping errors fail silently)
*/

-(BOOL)scrapeHTML:(NSString*)html nextURL:(NSURL*__autoreleasing*)nextURL changed:(BOOL*)changed
{
  insist (html && nextURL);
  insist (changed);
  
  NSScanner*scanner = [NSScanner scannerWithString:html];
  insist (scanner);

  *changed = NO;
  
  if (![scanner scanPast:@"<div class=\"content\">"])
    return NO;
  
  NSString*s;
  while ([scanner scanPast:@"<p class=\"row\""])
  {
    TCCraigslistItem*item = [[TCCraigslistItem alloc] init];
    insist (item);
   
    if (![scanner scanPast:@"class=\"price\">"] ||
        ![scanner scanUpToString:@"</span>" intoString:&s])
      continue;
  
    /*quick and dirty since we are scraping, get rid of $ entity*/
    s = [s stringByReplacingOccurrencesOfString:@"&#x0024;" withString:@"$"];
    item.price = s;
    
    if (![scanner scanPast:@"<span class=\"date\">"] ||
        ![scanner scanUpToString:@"</span>" intoString:&s])
      continue;
    item.date = s;
    
    /*url can be relative or absolute depending on if it's local or nearby results in the case of few NEARBY results*/
    if (![scanner scanPast:@"<a href=\""] ||
        ![scanner scanUpToString:@"\">" intoString:&s])
      continue;

    if ([s hasPrefix:@"http"])
      item.url = [NSURL URLWithString:s];
    else
      item.url = [NSURL URLWithString:s relativeToURL:_baseURL];

    if (!item.url)
      continue;
    
    if (![scanner scanPast:@">"] ||
        ![scanner scanUpToString:@"</a>" intoString:&s])
      continue;
    item.title = s;

    /*location is optional*/
    if ([scanner scanPast:@"<small>" beforeStrings:@[@"<p class=\"row\"", @"<span class=\"px\""]] &&
        [scanner scanUpToString:@"</small>" intoString:&s])
    {
      s = [s stringByReplacingOccurrencesOfString:@"(" withString:@""];
      s = [s stringByReplacingOccurrencesOfString:@")" withString:@""];
      item.location = s;
    }
    
    /*now that we have an item, add it to our list.*/
    *changed = YES;
    dispatch_barrier_async (_concurrentQueue , ^{
      [_items addObject:item];
    });
  }
  
  /*now find the next page, if any. we may have scanned to the end of the page while scraping, so just start over*/
  [scanner setScanLocation:0];
  
  if ([scanner scanPast:@"<span class=\"button pagenum\">"] &&
      [scanner scanPast:@"<a href='" before:@"class=\"button next\""] &&
      [scanner scanUpToString:@"'" intoString:&s])
  {
    *nextURL = [NSURL URLWithString:s relativeToURL:_baseURL];
  }
  else
  {
    *nextURL = nil;
  }
  return YES;
}

/*
  cancel the query.
  it is an error to call queryWithProgressBlock more than once, and also once cancel is called
  it's an error to call queryWithProgressBlock in the first place.
 
  this is intended to be used before instances of this class are destroyed, for instance if the user
  interface that was being loaded with this was destroyed while the query was still going on.
 
  after cancel, any data that was collected from craigslist is still ok to look at.
*/
-(void)cancel
{
  [_session invalidateAndCancel];
}
/*
  get number of results scraped so far
 
  returns - count of items scraped
*/
-(NSUInteger)count
{
  __block NSUInteger count;
  dispatch_sync (_concurrentQueue, ^{
    count = _items.count;
  });
  return count;
}

/*
  get a result
 
  index - index of result to return
 
  returns - an item
*/
-(TCCraigslistItem*)itemAtIndex:(NSUInteger)index
{
  __block TCCraigslistItem*item;
  dispatch_sync (_concurrentQueue, ^{
    insist (index < _items.count);
    item = _items [index];
  });
  return item;
}


@end
