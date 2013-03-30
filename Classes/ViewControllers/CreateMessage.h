//
//  CreateMessageViewController.h
//  iReddit
//
//  Created by Alejandro Paredes Alva on 3/29/13.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GIDAAlertView.h"
//#import "iRedditAppDelegate.h"

@class CreateMessage;

@protocol CreateMessageDelegate <NSObject>
- (void)composeController:(CreateMessage *)controller didSendFields:(NSArray*)fields;
@end

@interface CreateMessage : UIViewController <NSURLConnectionDataDelegate, GIDAAlertViewDelegate>
@property (retain, nonatomic) id<CreateMessageDelegate> delegate;
@property (retain, nonatomic) NSString *subject;
@property (retain, nonatomic) NSString *to;
@property (retain, nonatomic) IBOutlet UILabel *toLabel;
@property (retain, nonatomic) IBOutlet UILabel *subjectLabel;
@property (retain, nonatomic) IBOutlet UITextField *subjectField;
@property (retain, nonatomic) IBOutlet UITextField *toField;
@property (retain, nonatomic) IBOutlet UITextView *body;

@end

