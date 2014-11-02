//
//  TCCraigslistItemViewController.m
//  TrueCar
//
//  Created by Finucane on 8/2/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "TCCraigslistItemViewController.h"
#import "insist.h"
#import "UIAlertView+Additions.h"

@implementation TCCraigslistItemViewController


/*
  when view is loaded, start fetching the page. set ourself as the webview's delegate
  so we can start/stop the network activity indicator and report any error.
*/
-(void)viewDidLoad
{
  [super viewDidLoad];
  insist (self.url);
  
  _webView.delegate = self;
  NSURLRequest*request = [NSURLRequest requestWithURL:self.url];
  
  [_webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate

/*
  these are called on the main thread, so we don't have to worry about accessing UIKit stuff
*/
-(void)webViewDidFinishLoad:(UIWebView*)webView
{
  insist ([NSThread isMainThread]);
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

}
-(void)webViewDidStartLoad:(UIWebView *)webView
{
  insist ([NSThread isMainThread]);
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError*)error
{
  insist ([NSThread isMainThread]);
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  [UIAlertView showAlertWithTitle:NSLocalizedString(@"Craigslist Error", nil) message:@"Couldn't load craigslist page."];
}
@end
