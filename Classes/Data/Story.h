//
//  Story.h
//  Reddit
//
//  Created by Ross Boucher on 12/6/08.
//  Copyright 2008 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SubredditDataSource;

@interface Story : NSObject 
{
	float	 heights[4];
	
	NSString *title;
	NSString *author;
	NSString *domain;
	NSString *identifier;
	NSString *name;
	NSString *URL;
	NSString *kind;
	NSString *created;
	NSString *thumbnailURL;
	NSString *commentID;

	unsigned int totalComments;
	unsigned int downs;
	unsigned int ups;
	unsigned int index;

	BOOL likes;
	BOOL dislikes;
	BOOL visited;
	BOOL isSelfReddit;

	NSString *subreddit;
	SubredditDataSource *__weak subredditDataSource;
}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *URL;
@property (nonatomic, strong) NSString *kind;
@property (nonatomic, strong) NSString *created;
@property (nonatomic, weak) SubredditDataSource *subredditDataSource;
@property (nonatomic, strong) NSString *subreddit;
@property (nonatomic, assign) unsigned int totalComments;
@property (nonatomic, assign) unsigned int downs;
@property (nonatomic, assign) unsigned int ups;
@property (nonatomic, assign) unsigned int index;
@property (nonatomic, assign) BOOL likes;
@property (nonatomic, assign) BOOL dislikes;
@property (nonatomic, assign) BOOL isSelfReddit;
@property (nonatomic, strong) NSString *thumbnailURL;
@property (nonatomic, strong) NSString *commentID;

//dynamic properties
@property (nonatomic, assign) int score;
@property (nonatomic, assign) BOOL visited;
@property (nonatomic, weak) NSString *commentsURL;

//public
+ (Story *)storyWithDictionary:(NSDictionary *)dict inReddit:(id)reddit;
+ (Story *)storyWithID:(NSString *)anID;

- (CGFloat)heightForDeviceMode:(UIDeviceOrientation)orientation withThumbnail:(BOOL)showsThumbnail;
- (BOOL)hasThumbnail;

//private
- (void)setHeight:(CGFloat)aHeight forIndex:(int)anIndex;

@end


