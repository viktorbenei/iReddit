//
//  LoginViewController.h
//  Reddit2
//
//  Created by Ross Boucher on 6/15/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoginViewControllerDelegate

- (void)loginViewController:(id)v didFinishWithContext:(id)c;

@end

@interface LoginViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
	id <LoginViewControllerDelegate>delegate;
	id context;
	
	UIButton *loginButton;
	UILabel *statusLabel;
}

@property (nonatomic, strong) id <LoginViewControllerDelegate>delegate;
@property (nonatomic, strong) id context;

+ (void)presentWithDelegate:(id <LoginViewControllerDelegate>)aDelegate context:(id)aContext;

- (void)dismiss:(id)sender;

@end
