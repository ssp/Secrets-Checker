//
//  FlagChangeWindow.h
//  GPG Checker
//
//  Created by Steffen Kamp on Sat Feb 02 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface FlagChangeWindow : NSWindow {
	IBOutlet id		capsLockIndicatorTextField;
}

- (void) indicateCapsLock:(int) capsLock;

- (void)becomeKeyWindow;


@end
