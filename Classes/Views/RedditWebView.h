//
//  RedditWebView.h
//  Reddit
//
//  Created by Ross Boucher on 3/11/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story.h"

@interface RedditWebView : UIWebView {
    UIWebViewNavigationType currentNavigationType;
}
@property (nonatomic, readonly) UIWebViewNavigationType currentNavigationType;

+ (NSString *)storyIDForURL:(NSURL *)aURL;
+ (NSString *)storyIDForURL:(NSURL *)aURL commentID:(NSString **)stringPtr;

- (void)loadWithStory:(Story *)story commentID:(NSString *)comment;
- (void)loadWithStoryID:(NSString *)theID commentID:(NSString *)comment;

@end
