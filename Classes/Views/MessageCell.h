//
//  MessageCell.h
//  Reddit
//
//  Created by Ross Boucher on 3/11/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedditMessage.h"

@interface MessageCell : UITableViewCell 
+ (float)tableView:(UITableView *)aTableView rowHeightForObject:(RedditMessage *)aMessage;

@property (nonatomic,strong) RedditMessage *message;
@property (nonatomic,strong) UILabel *fromLabel;
@property (nonatomic,strong) UILabel *subjectLabel;
@property (nonatomic,strong) UILabel *bodyLabel;
@property (nonatomic,strong) UILabel *dateLabel;

@end
