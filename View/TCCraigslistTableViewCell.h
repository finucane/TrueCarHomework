//
//  TCCraigslistTableViewCell.h
//  TrueCar
//
//  Created by Finucane on 8/2/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCCraigslistTableViewCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel*title;
@property (nonatomic, strong) IBOutlet UILabel*price;
@property (nonatomic, strong) IBOutlet UILabel*date;
@property (nonatomic, strong) IBOutlet UILabel*location;

@end
