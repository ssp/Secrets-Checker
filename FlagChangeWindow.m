//
//  FlagChangeWindow.m
//  GPG Checker
//
//  Created by Steffen Kamp on Sat Feb 02 2002.
//  Copyright (c) 2001 earthlingsoft. All rights reserved.
//

#import "FlagChangeWindow.h"


@implementation FlagChangeWindow
- (void)sendEvent:(NSEvent *)event {
	//NSLog(@"FlagChangeWindow sendEvent, modifiers: %d, %d", [event modifierFlags], ([event modifierFlags] & NSAlphaShiftKeyMask));
    if([event type] == NSFlagsChanged) {
		 [self indicateCapsLock:([event modifierFlags] & NSAlphaShiftKeyMask)];
    }
    [super sendEvent:event];
}

- (void) indicateCapsLock:(NSInteger) capsLock
{
	//NSLog(@"capsLock: %d", capsLock);
	if (capsLock) {
		[capsLockIndicatorTextField setStringValue:NSLocalizedString(@"Caps Lock Sign", @"Caps Lock Sign")];
	}
	else {
		[capsLockIndicatorTextField setStringValue:@""];
	}
			
}

- (void)becomeKeyWindow
{
	[super becomeKeyWindow];
}

@end
