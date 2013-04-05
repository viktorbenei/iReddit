//
//  SubredditViewController.m
//  Reddit2
//
//  Created by Ross Boucher on 6/8/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import "SubredditViewController.h"


@interface SubredditViewController ()
@property (assign) BOOL gettingMore;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIView *updatingView;
@property (nonatomic, retain) UIView *loadingView;

//@property (nonatomic, retain) NSArray *headers;
@property (nonatomic, retain) UINavigationBar *navigationBar;

@end

@implementation SubredditViewController

- (void)dealloc
{
	//[self.dataSource cancel];
	[subredditItem release];
	[tabBar release];
	[savedLocation release];
    [_dataSource release];
    [_tableView release];
    [_updatingView release];
    [_loadingView release];
    [super dealloc];
}

- (id)initWithField:(NSDictionary *)anItem {
    self = [super init];
    if (self) {
        
		subredditItem = [anItem retain];
		showTabBar = ![subredditItem[@"url"] isEqual:@"/saved/"] && ![subredditItem[@"url"] isEqual:@"/recommended/"];
		
        self.title = [anItem[@"url"] isEqual:@"/"] ? @"Front Page" : anItem[@"text"];
		
		if (showTabBar && ![subredditItem[@"url"] isEqual:@"/randomrising/"]){
			[[NSUserDefaults standardUserDefaults] setObject:subredditItem[@"url"] forKey:initialRedditURLKey];
			[[NSUserDefaults standardUserDefaults] setObject:self.title forKey:initialRedditTitleKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
        
		self.hidesBottomBarWhenPushed = YES;
		self.navigationBar = [[[UINavigationBar alloc] init] autorelease];
		self.navigationBar.TintColor = [iRedditAppDelegate redditNavigationBarTintColor];
        self.navigationController.navigationBar.tintColor = [iRedditAppDelegate redditNavigationBarTintColor];
        [self.view addSubview:self.navigationBar];
        
        
	}
    
	return self;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataSource totalStories];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [StoryCell tableView:tableView rowHeightForObject:[_dataSource storyWithIndex:indexPath.row]];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StoryCell *storyCell = [self.tableView dequeueReusableCellWithIdentifier:@"subreddit"];
    if (!storyCell) {
        storyCell = [[[StoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"subreddit"] autorelease];
    }
    Story *story =  [_dataSource storyWithIndex:indexPath.row];
    ((StoryCell *)storyCell).story =story;
    //   [[cell textLabel] setText:@"Something"];
    
    CommentAccessoryView *accessory = nil;
    
    if (!storyCell.accessoryView)
    {
        accessory = [[[CommentAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)] autorelease];
        storyCell.accessoryView = accessory;
    }
    else
    {
        accessory = (CommentAccessoryView *)storyCell.accessoryView;
    }
    
    NSUInteger commentCount = storyCell.story.totalComments;
    
    // a somewhat hacky way to determine width, *but* much faster than sizeWithFont: on every cell
    CGRect accessoryFrame = accessory.frame;
    accessoryFrame.size.width = commentCount > 999 ? 36.0 : 30.0;
    accessory.frame = accessoryFrame;
    
    [accessory setCommentCount:commentCount];
    
    [accessory addTarget:self action:@selector(accessoryViewTapped:) forControlEvents:UIControlEventTouchUpInside];
    accessory.story = story;
    
    //storyCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    return storyCell;
}
- (void)accessoryViewTapped:(id)sender {
    StoryCell *cell = (StoryCell *)[((CommentAccessoryView *)sender) superview];
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    Story *object = [_dataSource storyWithIndex:indexPath.row];
    StoryViewController *controller = [[StoryViewController alloc] initForComments];
    [[self navigationController] pushViewController:controller animated:YES];
    
    controller.story = object;
    [controller release];
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
        tabBar = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Hot",@"New",@"Rising",@"Top",@"Controversial", nil]];
        [tabBar setSelectedSegmentIndex:0];
        UIFont *font = nil;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            font = [UIFont boldSystemFontOfSize:13.0f];
        } else {
            font = [UIFont boldSystemFontOfSize:9.0f];
        }
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:UITextAttributeFont];
        [tabBar setTitleTextAttributes:attributes forState:UIControlStateNormal];
        [tabBar setFrame:CGRectMake(0, 0, applicationFrame.size.width, 35)];
        [tabBar setSegmentedControlStyle:UISegmentedControlStyleBar];
        [tabBar setTintColor:[iRedditAppDelegate redditNavigationBarTintColor]];
        [tabBar addTarget:self action:@selector(toolBarButton:) forControlEvents:UIControlEventValueChanged];
	}
    tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	CGRect aFrame = [[UIScreen mainScreen] applicationFrame];
	
	aFrame.origin.y = tabBar ? CGRectGetHeight(tabBar.frame) : 0.0;
	aFrame.size.height -= aFrame.origin.y;
	
	//UIView *wrapper = [[[UIView alloc] initWithFrame:aFrame] autorelease];
    //wrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
	//aFrame.origin.y	= 0;
 	
	self.tableView = [[[UITableView alloc] initWithFrame:aFrame style:UITableViewStylePlain] autorelease];
    self.tableView.rowHeight = 80.f;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //self.tableView.tableHeaderView = tabBar;
	self.tableView.dataSource = self;
    self.tableView.delegate = self;
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
    UILabel *label = nil;
    UIActivityIndicatorView *aic = nil;
    
    _loadingView = [[UIView alloc] initWithFrame:aFrame];
    [_loadingView setBackgroundColor:[UIColor whiteColor]];
    [_loadingView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    label = [[UILabel alloc] initWithFrame:aFrame];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setText:@"Loading..."];
    [label setContentMode:UIViewContentModeCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
    aic = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [aic setFrame:CGRectMake((_tableView.frame.size.width-100)/2, (_tableView.frame.size.height-100)/2, 100, 100)];
    [aic setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
    [aic startAnimating];
    
    [_loadingView addSubview:aic];
    [_loadingView addSubview:label];
    [self.view addSubview:_loadingView];
    [label release];
    [aic release];
    
    self.updatingView = [[[UIView alloc] initWithFrame:CGRectMake(0, aFrame.size.height+5, aFrame.size.width, 30)] autorelease];
    [self.updatingView setBackgroundColor:[UIColor blackColor]];
    [self.updatingView setAlpha:0.8];
    label = [[UILabel alloc] initWithFrame:CGRectMake((_tableView.frame.size.width-100)/2, 0, 100, 30)];
    [label setText:@"Updating"];
    [label setTextColor:[UIColor whiteColor]];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextAlignment:UITextAlignmentCenter];
    aic = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [aic setFrame:CGRectMake((_tableView.frame.size.width-150)/2, 0, 30, 30)];
    [aic setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin];
    [aic startAnimating];
    
    [self.updatingView addSubview:aic];
    [self.updatingView addSubview:label];
    [label release];
    [aic release];
    // [self.updating setBackgroundColor:[UIColor redColor]];
    
    self.updatingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.updatingView];
    [self.updatingView setHidden:YES];
    [self performSelectorInBackground:@selector(loading) withObject:nil];
}

- (void)refresh:(id)sender {
    [self.loadingView setHidden:NO];
    [self performSelectorInBackground:@selector(newData) withObject:nil];
}
- (void)newData {
    if ([self.dataSource totalStories]>0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    [self.dataSource invalidate:YES];
    [self.dataSource loadMore:NO];
    [self.tableView reloadData];
    [self.loadingView setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}

-(void)loading {
    [self createModel];
    [_tableView reloadData];
    [_loadingView setHidden:YES];
}

- (void)createModel
{
    self.dataSource = [[[SubredditData alloc] initWithSubreddit:subredditItem[@"url"]] autorelease];
    [self.dataSource loadMore:NO];
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
    ((SubredditData *)self.dataSource).newsModeIndex = sender.selectedSegmentIndex;
    [_loadingView setHidden:NO];
	[self.dataSource invalidate:YES];
    [self performSelectorInBackground:@selector(newData) withObject:nil];
//    [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionTop animated:NO];
    
}

#pragma mark Table view methods
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Story *object = ((StoryCell *)[tableView cellForRowAtIndexPath:indexPath]).story;
    [savedLocation release];
    savedLocation = [indexPath retain];
    
    StoryViewController *controller = [[StoryViewController alloc] init];
    [[self navigationController] pushViewController:controller animated:YES];
    
    controller.story = object;
    [controller release];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
-(void)loadMore {
    [_dataSource loadMore:YES];
    [_tableView reloadData];
    _gettingMore = NO;
    [_updatingView setHidden:YES];
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    CGSize size = scrollView.contentSize;
    UIEdgeInsets inset = scrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = 10;
    if(y > h + reload_distance && !_gettingMore) {
        _gettingMore = YES;
        [_updatingView setHidden:NO];
        [self performSelectorInBackground:@selector(loadMore) withObject:nil];
    }
}

-(BOOL)shouldAutorotate {
    return YES;
}
-(NSUInteger)supportedInterfaceOrientations {
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // this interface is portrait only, but allow it to operate in *either* portrait
    return [[NSUserDefaults standardUserDefaults] boolForKey:allowLandscapeOrientationKey] ? YES : (interfaceOrientation == UIInterfaceOrientationPortrait) ? YES : NO ;
}
@end

