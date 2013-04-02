//
//  MessageDataSource.m
//  Reddit2
//
//  Created by Ross Boucher on 6/16/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "MessageDataSource.h"
#import "Constants.h"
#import "RedditMessage.h"
#import "MessageCell.h"
#import "LoginController.h"

@interface MessageDataSource ()
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSMutableData  *receivedData;
@end

@implementation MessageDataSource

- (id)init
{
	if (self = [super init])
	{
		canLoadMore = YES;
        _items = [[NSMutableArray array] retain];
	}

	return self;
}
-(NSInteger)count {
    return _items.count;
}
-(RedditMessage *)messageAtIndex:(NSInteger)index {
    return [_items objectAtIndex:index];
}
- (void)dealloc
{	
	[self cancel];	
    [lastLoadedTime release];
	[super dealloc];
}

- (BOOL)canLoadMore
{
	return canLoadMore;
}

- (NSDate *)loadedTime
{
    return lastLoadedTime;
}

- (BOOL)isLoading
{
    return isLoading;
}

- (BOOL)isLoadingMore
{
    return isLoadingMore;
}

- (BOOL)isLoaded
{
    return lastLoadedTime != nil;
}

- (void)invalidate:(BOOL)erase 
{
	[self.items removeAllObjects];
}

- (void)cancel
{

}

- (void)didStartLoad
{
    isLoading = YES;
}

- (void)didFinishLoad
{
    isLoading = NO;
    isLoadingMore = NO;
    [lastLoadedTime release];
    lastLoadedTime = [[NSDate date] retain];
}

- (void)didFailLoadWithError:(NSError*)error
{
    isLoading = NO;
    isLoadingMore = NO;
}

- (void)didCancelLoad
{
    isLoading = NO;
    isLoadingMore = NO;
}

- (unsigned int)unreadMessageCount
{
	return unreadMessageCount;
}

- (unsigned int)messageCount
{
	return [self.items count];
}

- (void)loadMore:(BOOL)more {	
	NSString *loadURL = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, RedditMessagesAPIString];

	if (more) {
		id object = [self.items lastObject];
		
		RedditMessage *lastMessage = (RedditMessage *)object;
		loadURL = [NSString stringWithFormat:@"%@&after=%@", loadURL, lastMessage.name];
	} else {
		// remove any previous items
		[self.items removeAllObjects];
		unreadMessageCount = 0;		
	}
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:loadURL]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setHTTPShouldHandleCookies:[[LoginController sharedLoginController] isLoggedIn] ? YES : NO];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [connection start];
}

#pragma mark url request delegate
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    isLoading = YES;
    _receivedData = [[NSMutableData data] retain];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_receivedData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	canLoadMore = NO;

	int totalCount = [self.items count];

	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_receivedData options:NSJSONReadingMutableContainers error:nil];
    
	if (![json isKindOfClass:[NSDictionary class]])
	{
	    [self didFinishLoad];
		return;
	}

    NSArray *results = [[json objectForKey:@"data"] objectForKey:@"children"];	
	
	unreadMessageCount = 0;
    for (NSDictionary *result in results) 
	{     
		RedditMessage *newMessage = [RedditMessage messageWithDictionary:[result objectForKey:@"data"]];
		if (newMessage) 
		{
			[self.items	addObject:newMessage];
			
			if (newMessage.isNew)
				unreadMessageCount++;
		}
	}
    
	canLoadMore = [self.items count] > totalCount;
	    
    [self didFinishLoad];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:MessageCountDidChangeNotification object:nil];
}
@end
