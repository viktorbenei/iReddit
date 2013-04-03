//
//  main.m
//  iReddit
//
//  Created by Ross Boucher on 6/18/09.
//  Copyright 280 North 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef DEBUG
void eHandler(NSException *);

void eHandler(NSException *exception) {
    NSLog(@"%@", exception);
    NSLog(@"%@", [exception callStackSymbols]);
}
#endif

int main(int argc, char *argv[]) {
    
#ifdef DEBUG
    NSSetUncaughtExceptionHandler(&eHandler);
#endif
   
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
