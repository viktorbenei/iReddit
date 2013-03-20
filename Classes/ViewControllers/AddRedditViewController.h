//
//  AddRedditViewController.h
//  iReddit
//
//  Created by Ross Boucher on 7/2/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GIDAAlertView.h"

@interface AddRedditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, GIDAAlertViewDelegate>

- (BOOL)shouldViewOnly;
- (id)initForViewing;

@end
