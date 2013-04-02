//
//  SubredditViewController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/8/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "SubredditViewController.h"
#import "SubredditDataSource.h"
#import "StoryViewController.h"
#import "iRedditAppDelegate.h"
#import "Constants.h"
#import "SubredditTableViewDelegate.h" 



@implementation SubredditViewController

- (void)dealloc 
{
	//[self.dataSource cancel];
	[subredditItem release];
	[tabBar release];
	[savedLocation release];

    [super dealloc];
}

- (id)initWithField:(NSDictionary *)anItem {
    if (self = [super init]) {
		subredditItem = [anItem retain];
		showTabBar = ![subredditItem[@"url"] isEqual:@"/saved/"] && ![subredditItem[@"url"] isEqual:@"/recommended/"];
		
        self.title = [anItem[@"url"] isEqual:@"/"] ? @"Front Page" : anItem[@"text"];
		
		if (showTabBar && ![subredditItem[@"url"] isEqual:@"/randomrising/"]){
			[[NSUserDefaults standardUserDefaults] setObject:subredditItem[@"url"] forKey:initialRedditURLKey];
			[[NSUserDefaults standardUserDefaults] setObject:self.title forKey:initialRedditTitleKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}

		self.hidesBottomBarWhenPushed = YES;
		self.variableHeightRows = YES;
		
		self.navigationBarTintColor = [iRedditAppDelegate redditNavigationBarTintColor];
	}

	return self;
}

- (void)loadView
{
	[super loadView];

    // create the tableview
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    self.view = [[[UIView alloc] initWithFrame:applicationFrame] autorelease];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	if (tabBar)
	{
		[tabBar release];
		tabBar = nil;
	}
			
	if (showTabBar)
	{
        tabBar = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Hot",@"New",@"Top",@"Controversial", nil]];
        [tabBar setSelectedSegmentIndex:0];
        UIFont *font = [UIFont boldSystemFontOfSize:11.0f];
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:UITextAttributeFont];
        [tabBar setTitleTextAttributes:attributes forState:UIControlStateNormal];
        [tabBar setFrame:CGRectMake(0, 0, applicationFrame.size.width, 30)];
        [tabBar setSegmentedControlStyle:UISegmentedControlStyleBar];
        [tabBar setTintColor:[iRedditAppDelegate redditNavigationBarTintColor]];
        [tabBar addTarget:self action:@selector(toolBarButton:) forControlEvents:UIControlEventValueChanged];
	}

	CGRect aFrame = self.view.frame;
	
	aFrame.origin.y = tabBar ? CGRectGetHeight(tabBar.frame) : 0.0;
	aFrame.size.height -= aFrame.origin.y;
	
	//UIView *wrapper = [[[UIView alloc] initWithFrame:aFrame] autorelease];
    //wrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	//aFrame.origin.y	= 0;
	
	self.tableView = [[[UITableView alloc] initWithFrame:aFrame style:UITableViewStylePlain] autorelease];
    self.tableView.rowHeight = 80.f;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //self.tableView.tableHeaderView = tabBar;
	
	//[wrapper addSubview:self.tableView];
    
    UIBarButtonItem *reloadItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh.png"]
                                                           style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(refresh:)];
    reloadItem.width = 25.0;
    self.navigationItem.rightBarButtonItem = reloadItem;
    [reloadItem release];
	
	if (tabBar)
		[self.view addSubview:tabBar];

    [self.view addSubview:self.tableView]; 
}

- (void)refresh:(id)sender
{
    [self.dataSource.model load:TTURLRequestCachePolicyNoCache more:NO];
}
/*- (void)unloadView
{
	[tabBar release];
	tabBar = nil;
	
	[super unloadView];
}*/

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)createModel 
{
    SubredditDataSource *source = [[SubredditDataSource alloc] initWithSubreddit:subredditItem[@"url"]];
    source.viewController = self;
    self.dataSource = source;
    [source release];
}

- (id)createDelegate
{
    return [[[SubredditTableViewDelegate alloc] initWithController:self] autorelease]; 
}

- (NSString *)titleForError:(NSError*)error
{
	return @"Connection Error";
}

- (NSString *)subtitleForError:(NSError*)error
{
	return @"iReddit requires an active Internet connection";
}

- (UIImage*)imageForError:(NSError*)error
{
	return [UIImage imageNamed:@"error.png"];
}

- (UIImage*)imageForNoData
{
	return [UIImage imageNamed:@"error.png"];
}

- (NSString*)titleForNoData
{
	return @"No Stories";
}

#pragma mark tab bar stuff
-(void)toolBarButton:(UISegmentedControl *)sender {
    [self.dataSource cancel];
	[self.dataSource invalidate:YES];
    
    ((SubredditDataModel *)((SubredditDataSource *)self.dataSource).model).newsModeIndex = sender.selectedSegmentIndex;
    [self reload];
}
#pragma mark orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? YES : UIInterfaceOrientationIsPortrait(interfaceOrientation) ; 
}

#pragma mark Table view methods

- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath*)indexPath
{
	[super didSelectObject:object atIndexPath:indexPath];

	if ([object isKindOfClass:[Story class]])
	{
		[savedLocation release];
		savedLocation = [indexPath retain];
		
		StoryViewController *controller = [[StoryViewController alloc] init];
		[[self navigationController] pushViewController:controller animated:YES];

		controller.story = object;
		[controller release];

		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (void)didSelectAccessoryForObject:(id)object atIndexPath:(NSIndexPath*)indexPath 
{
	if ([object isKindOfClass:[Story class]])
	{
		StoryViewController *controller = [[StoryViewController alloc] initForComments];
		[[self navigationController] pushViewController:controller animated:YES];
		
		controller.story = object;
		[controller release];
		
		[self.tableView reloadData];
	}
}


@end

