//
//  AppController.m
//  Secrets Checker
//
//  Created by Sven-S. Porst on Mon Mar 18 2002.
//  Copyright (c) 2001 earthlingsoft. All rights reserved.
//

#import "AppController.h"


@implementation AppController
- (void) awakeFromNib
{
	// use this to fill arrays with information on available private keys and cipher algorithms

#ifdef debugbuild
#else
	[Data Data];
#endif
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*) sender
{
	return NO;
}

@end
