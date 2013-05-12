//
//  StoryViewController.h
//  Reddit2
//
//  Created by Ross Boucher on 6/12/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "Story.h"
#import "AlienProgressView.h"


@interface StoryViewController : UIViewController <UIWebViewDelegate>
@property (nonatomic,strong) Story *story;

- (void)setStoryID:(NSString *)storyID commentID:(NSString *)commentID URL:(NSString *)aURL;
- (id)initForComments;

- (void)loadStoryComments;
- (void)loadStory;

- (IBAction)showComments:(id)sender;
- (IBAction)showStory:(id)sender;
- (IBAction)share:(id)sender;
- (IBAction)voteUp:(id)sender;
- (IBAction)voteDown:(id)sender;
- (IBAction)segmentAction:(id)sender;
- (void)saveCurrentStory:(id)sender;
- (void)saveOnInstapaper:(id)sender;
- (void)saveOnPocket:(id)sender;
- (void)hideCurrentStory:(id)sender;

- (void)setScore:(int)score;
- (void)setNumberOfComments:(unsigned)num;

@end
