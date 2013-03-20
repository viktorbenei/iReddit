//
//  LoginController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/15/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "LoginController.h"
#import "Constants.h"

LoginController *SharedLoginController = nil;
@interface LoginController (){
    NSMutableData *receivedData;
}

@end
@implementation LoginController

@synthesize modhash, lastLoginTime;

+ (id)sharedLoginController
{
	if (!SharedLoginController)
	{
		SharedLoginController = [[self alloc] init];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:hasModHash]) {
            NSDate *last = [defaults objectForKey:@"lastLoginTime"];
            NSDate *now = [NSDate date];
            NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]autorelease];
            NSDateComponents *components = [calendar components:NSDayCalendarUnit fromDate:last toDate:now options:0];
            if ([components day] < 7) {
                SharedLoginController.modhash = [defaults objectForKey:redditModHash];
            } else {
                SharedLoginController.modhash = @"";
            }
        }   else
            SharedLoginController.modhash = @"";
	}
	
	return SharedLoginController;
}

- (void)dealloc
{
	self.modhash = nil;
	self.lastLoginTime = nil;
    
	[super dealloc];
}

- (BOOL)isLoggedIn {
    if (lastLoginTime == nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:hasModHash]) {
            id last = [defaults objectForKey:@"lastLoginTime"];
            if ([last isKindOfClass:[NSDate class]]) {
                NSDate *now = [NSDate date];
                NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]autorelease];
                NSDateComponents *components = [calendar components:NSDayCalendarUnit fromDate:last toDate:now options:0];
                if ([components day] < 7) {
                    lastLoginTime = [defaults objectForKey:@"lastLoginTime"];
                } else {
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setBool:NO forKey:hasModHash];
                    [defaults setObject:@"" forKey:@"lastLoginTime"];
                    [defaults setObject:@"" forKey:redditModHash];
                    [defaults synchronize];
                    self.modhash = @"";
                    self.lastLoginTime = nil;
                }
            }
        }
    }
    return lastLoginTime != nil;
}

- (BOOL)isLoggingIn
{
    return isLoggingIn;
}

- (void)loginWithUsername:(NSString *)aUsername password:(NSString *)aPassword {
    self.lastLoginTime = nil;
    
    if (!aUsername || !aPassword || ![aUsername length] || ![aPassword length])
    {
        [self logOut];
        [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidFinishLoggingInNotification object:nil];
        return;
    }
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:aUsername forKey:redditUsernameKey];
    [defaults setObject:aPassword forKey:redditPasswordKey];
    [defaults synchronize];
	isLoggingIn = YES;
	
	NSString *loadURL = [NSString stringWithFormat:@"%@%@", RedditBaseURLString, @"/api/login"];
	
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:loadURL]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"rem=on&passwd=%@&user=%@&api_type=json",
                           [aPassword stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                           [aUsername stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]
                          dataUsingEncoding:NSASCIIStringEncoding]];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [connection start];
}

#pragma mark NSURLConnectionDataDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidBeginLoggingInNotification object:nil];
    receivedData = [[NSMutableData alloc] init];
}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // parse the JSON data that we retrieved from the server
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:receivedData options:NSJSONReadingMutableContainers error:&error];
    NSDictionary *responseJSON = [(NSDictionary *)json valueForKey:@"json"];
    BOOL loggedIn = !error && [responseJSON objectForKey:@"data"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (loggedIn) {
        self.modhash = (NSString *)[(NSDictionary *)[responseJSON objectForKey:@"data"] objectForKey:@"modhash"];
        self.lastLoginTime = [NSDate date];
        [defaults setBool:YES forKey:hasModHash];
        [defaults setObject:self.lastLoginTime forKey:@"lastLoginTime"];
    } else {
        self.modhash = @"";
        self.lastLoginTime = nil;
        NSLog(@"%@",responseJSON[@"errors"]);
        [defaults setObject:@"" forKey:redditUsernameKey];
        [defaults setObject:@"" forKey:redditPasswordKey];
        [defaults setBool:NO forKey:hasModHash];
        [defaults setObject:@"" forKey:@"lastLoginTime"];
        self.modhash = @"";
        self.lastLoginTime = nil;
    }
    [defaults setObject:self.modhash forKey:redditModHash];
    [defaults synchronize];
    
    isLoggingIn = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidFinishLoggingInNotification object:nil];
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    isLoggingIn = NO;
    self.lastLoginTime = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:RedditDidFinishLoggingInNotification object:nil];
}
-(void)logOut {
    if ([self isLoggedIn]){
        self.modhash = @"";
        self.lastLoginTime = nil;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"" forKey:redditUsernameKey];
        [defaults setObject:@"" forKey:redditPasswordKey];
        [defaults setBool:NO forKey:hasModHash];
        [defaults setObject:@"" forKey:@"lastLoginTime"];
        [defaults setObject:@"" forKey:redditModHash];
        [defaults synchronize];
        lastLoginTime = nil;
    }
}

@end
