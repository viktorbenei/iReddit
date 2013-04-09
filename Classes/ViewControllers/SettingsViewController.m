//
//  SettingsViewController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/14/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "SettingsViewController.h"
#import "iRedditAppDelegate.h"
#import "LoginController.h"
#import "Constants.h"
#import "GIDAAlertView.h"

@interface SettingsViewController () {
    NSInteger selectedRow;
    BOOL changed;
}
@property (strong) NSArray *sections;
@property (strong) NSMutableArray *options;

@end
@implementation SettingsViewController

-(id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self createModel];
        selectedRow = 0;
        changed = NO;
    }
    return self;
}
- (void)loadView
{
	[super loadView];
	self.title = @"Settings";
    //	self.autoresizesForKeyboard = YES;
	self.navigationController.navigationBar.TintColor = [iRedditAppDelegate redditNavigationBarTintColor];
    
    //	self.variableHeightRows = YES;
	
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
    [self.tableView setBackgroundView:nil];
    self.tableView.backgroundColor = [UIColor colorWithRed:229.0/255.0 green:238.0/255.0 blue:1 alpha:1];    
	
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return  [_sections count];
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [_sections objectAtIndex:section];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_options objectAtIndex:section] count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [tableView dequeueReusableCellWithIdentifier:@"settings"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settings"];
    }
    
    [cell setAccessoryView:nil];
    NSDictionary *cellData = [[_options objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [[cell textLabel] setText:[cellData objectForKey:@"title"]];
    if ([[cellData objectForKey:@"type"] isEqualToString:@"switch"]) {
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        [switchview setOn:[cellData[@"value"] boolValue]];
        
        [cell setAccessoryView:switchview];
        [switchview addTarget:self action:@selector(valueChange:) forControlEvents:UIControlEventValueChanged];
        
    } else {
        if ([cellData[@"type"] isEqualToString:@"check"]) {
            if ([cellData[@"value"] boolValue]) {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
        } else {
            if ([cellData[@"type"] isEqualToString:@"text"]) {
                CGFloat width = 180;
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    width = 544;
                }
                UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, width, 24)];
                [textField setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
                [textField setDelegate:self];
                [textField setText:cellData[@"value"]];
                [textField setSpellCheckingType:UITextSpellCheckingTypeNo];
                [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
                [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
                [textField setPlaceholder:cellData[@"placeholder"]];
                if ([cellData[@"secure"] boolValue]) {
                    [textField setSecureTextEntry:YES];
                }
                [cell setAccessoryView:textField];
            }
        }
    }
    return cell;
}
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[textField superview]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *data = [[_options objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *previous = [defaults stringForKey:data[@"key"]];
    [defaults setObject:[textField text] forKey:data[@"key"]];
    [defaults synchronize];
    
    if (redditPasswordKey == data[@"key"] || redditUsernameKey == data[@"key"]) {
        if (![previous isEqualToString:data[@"value"]]) {
            changed = YES;
        }
    }
    [self createModel];
}
-(void)textFieldDidEndEditing:(UITextField *)textField {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[textField superview]];
    
    NSDictionary *data = [[_options objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:[textField text] forKey:data[@"key"]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (redditPasswordKey == data[@"key"] || redditUsernameKey == data[@"key"]) {
        changed = YES;
    }
    [self createModel];
}
-(void)valueChange:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[sender superview]];
    
    NSDictionary *data = [[_options objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([data[@"key"] isEqualToString:usePocket]) {
        if ([sender isOn] && ![[PocketAPI sharedAPI] isLoggedIn]) {
            [[PocketAPI sharedAPI] loginWithHandler: ^(PocketAPI *API, NSError *error){
                if (error != nil)
                {
                    // There was an error when authorizing the user.
                    // The most common error is that the user denied access to your application.
                    // The error object will contain a human readable error message that you
                    // should display to the user. Ex: Show an UIAlertView with the message
                    // from error.localizedDescription
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:usePocket];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSLog(@"%@",error.localizedDescription);
                    GIDAAlertView *gav = [[GIDAAlertView alloc] initWithXMarkAndMessage:@"Could not log in to Pocket"];
                    [gav setColor:[iRedditAppDelegate redditNavigationBarTintColor]];
                    [gav presentAlertFor:1.08];
                    
                }
                else
                {
                    // The user logged in successfully, your app can now make requests.
                    // [API username] will return the logged-in user’s username
                    // and API.loggedIn will == YES
                    
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:usePocket];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    GIDAAlertView *gav = [[GIDAAlertView alloc] initWithCheckMarkAndMessage:@"Logged in to Pocket"];
                    [gav setColor:[iRedditAppDelegate redditNavigationBarTintColor]];
                    [gav presentAlertFor:1.08];
                }
            }];
        }
        if (![sender isOn] && [[PocketAPI sharedAPI] isLoggedIn]) {
            [[PocketAPI sharedAPI] logout];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:data[@"key"]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        if ([sender isOn] && [[PocketAPI sharedAPI] isLoggedIn]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:usePocket];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    } else {
        if ([data[@"key"] isEqualToString:@"useChrome"]) {
            if ([sender isOn] && ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:data[@"key"]];
                [sender setOn:NO animated:YES];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:data[@"key"]];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:data[@"key"]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    [self createModel];
    //[self.tableView reloadData];
    
}
-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 5) {
        return YES;
    }
    return NO;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 5) {
        if (indexPath.row != selectedRow) {
            NSIndexPath *old = [NSIndexPath indexPathForItem:selectedRow inSection:5];
            id cellOld = [tableView cellForRowAtIndexPath:old];
            [cellOld setAccessoryType:UITableViewCellAccessoryNone];
            id cellNew = [tableView cellForRowAtIndexPath:indexPath];
            [cellNew setAccessoryType:UITableViewCellAccessoryCheckmark];
            selectedRow = indexPath.row;
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}
-(void)createModel
{
    if (_options) {
        _options = nil;
    }
    if (_sections) {
        _sections = nil;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _sections = [NSArray arrayWithObjects:
                 @"reddit Account Information",
                 @"Instapaper Account Information",
                 @"Other",
                 @"Customized reddits",
                 @"Display Preferences",
                 nil];
    NSDictionary *chrome = nil;
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
        chrome =  [NSDictionary dictionaryWithObjectsAndKeys:@"Use Chrome",@"title",[NSNumber numberWithBool:[defaults boolForKey:useChrome]],@"value",useChrome, @"key", @"switch", @"type", nil];
    }
    _options = [NSMutableArray arrayWithObjects:
                [NSArray arrayWithObjects:
                 [NSDictionary dictionaryWithObjectsAndKeys:
                  @"Username",@"title",
                  redditUsernameKey, @"key",
                  @"text", @"type",
                  [NSNumber numberWithBool:NO],@"secure",
                  @"splashy", @"placeholder",
                  [defaults stringForKey:redditUsernameKey],@"value",
                  nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:
                  @"Password",@"title",
                  redditPasswordKey, @"key",
                  @"text", @"type",
                  [NSNumber numberWithBool:YES],@"secure",
                  @"••••••", @"placeholder",
                  [defaults stringForKey:redditPasswordKey],@"value",
                  nil],
                 nil],
                [NSArray arrayWithObjects:
                 [NSDictionary dictionaryWithObjectsAndKeys:
                  @"Username",@"title",
                  instapaperUsernameKey, @"key",
                  @"text", @"type",
                  [NSNumber numberWithBool:NO],@"secure",
                  @"splashy", @"placeholder",
                  [defaults stringForKey:instapaperUsernameKey],@"value",
                  nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:@"Password",@"title",instapaperPasswordKey, @"key", @"text", @"type", [NSNumber numberWithBool:YES],@"secure", @"••••••", @"placeholder", [defaults stringForKey:instapaperPasswordKey],@"value", nil],
                 nil],
                [NSArray arrayWithObjects:
                 [NSDictionary dictionaryWithObjectsAndKeys:@"Pocket",@"title",[NSNumber numberWithBool:[defaults boolForKey:usePocket]],@"value",usePocket, @"key", @"switch", @"type", nil], chrome, nil],
                [NSArray arrayWithObject:
                 [NSDictionary dictionaryWithObjectsAndKeys:@"Use Account Settings",@"title",[NSNumber numberWithBool:[defaults boolForKey:useCustomRedditListKey]],@"value",useCustomRedditListKey, @"key", @"switch", @"type", nil]],
                [NSArray arrayWithObjects:
                 [NSDictionary dictionaryWithObjectsAndKeys:@"Show Thumbnails",@"title",[NSNumber numberWithBool:[defaults boolForKey:showStoryThumbnailKey]],@"value",showStoryThumbnailKey, @"key", @"switch", @"type", nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:@"Shake for New Story",@"title",[NSNumber numberWithBool:[defaults boolForKey:shakeForStoryKey]],@"value",shakeForStoryKey, @"key", @"switch", @"type", nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:@"Show Loading Alien",@"title",[NSNumber numberWithBool:[defaults boolForKey:showLoadingAlienKey]],@"value",showLoadingAlienKey, @"key", @"switch", @"type", nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:@"Allow Landscape",@"title",[NSNumber numberWithBool:[defaults boolForKey:allowLandscapeOrientationKey]],@"value",allowLandscapeOrientationKey, @"key", @"switch", @"type", nil],
                 nil],
                nil];
}
- (void)viewWillDisappear:(BOOL)animated{
    [[[[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] accessoryView] resignFirstResponder];
    [[[[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] accessoryView] resignFirstResponder];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (changed) {
        [[LoginController sharedLoginController] logOut];
        [[LoginController sharedLoginController] loginWithUsername:[defaults stringForKey:redditUsernameKey] password:[defaults stringForKey:redditPasswordKey]];
    }
    
    
}
-(BOOL)shouldAutorotate {
    return YES;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // this interface is portrait only, but allow it to operate in *either* portrait
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? YES : (interfaceOrientation == UIInterfaceOrientationPortrait) ? YES : NO ;
}
-(NSUInteger)supportedInterfaceOrientations {
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}

@end
