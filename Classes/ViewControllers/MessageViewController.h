//
//  MessageViewController.h
//  Reddit2
//
//  Created by Ross Boucher on 6/16/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTCoreText.h"
#import <Three20/Three20.h>
#import "CreateMessage.h"

@interface MessageViewController : TTTableViewController <CreateMessageDelegate>
{
	TTURLRequest *activeRequest;
}

@end
