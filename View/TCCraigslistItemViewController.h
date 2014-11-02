//
//  TCCraigslistItemViewController.h
//  TrueCar
//
//  Created by Finucane on 8/2/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCCraigslistItemViewController : UIViewController <UIWebViewDelegate>
{
  @private
  IBOutlet UIWebView*_webView;
}
@property NSURL*url;
@end
