//
//  PostCell.h
//  Reddit
//
//  Created by Ross Boucher on 11/25/08.
//  Copyright 2008 280 North. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Story.h"

@interface StoryCell : UITableViewCell
{
	Story		*story;
	UILabel		*storyTitleView;
	UILabel		*storyDescriptionView;
	UILabel		*secondaryDescriptionView;
	UIImageView	*storyImage;
  //  UIButton    *virtualAccessory;
}
+ (float)tableView:(UITableView *)aTableView rowHeightForObject:(Story *)aStory;
@property (nonatomic,retain) Story *story;
@property (nonatomic,retain) UILabel *storyTitleView;
@property (nonatomic,retain) UILabel *storyDescriptionView;
@property (nonatomic,retain) UIImageView *storyImage;

@end
