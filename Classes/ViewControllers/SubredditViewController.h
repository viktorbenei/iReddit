//
//  SubredditViewController.h
//  Reddit2
//
//  Created by Ross Boucher on 6/8/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SubredditData.h"
#import "StoryViewController.h"
#import "iRedditAppDelegate.h"
#import "Constants.h"
#import "StoryCell.h"
#import "CommentAccessoryView.h"

@interface SubredditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
	BOOL                showTabBar;
	NSDictionary        *subredditItem;
	UISegmentedControl  *tabBar;
    NSIndexPath         *savedLocation;

}
@property (nonatomic, retain) SubredditData *dataSource;
- (id)initWithField:(NSDictionary *)anItem;

@end
