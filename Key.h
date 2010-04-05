//
//  Key.h
//  GPG Checker
//
//  Created by Sven-S. Porst on Sun Jan 13 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Key : NSObject {
	// the parts of the main key in with-colons format without the first field containing 'pub' or 'sec'
	NSArray	*	mainKeyParts;
	// the lines of the remaining subkeys
	NSArray	*	subkeys;
}

- (id) initWithWithColonsString:(NSString *)keyString;

- (NSString *) userid;
- (NSString *) name;
- (NSString *) email;

- (NSInteger) algorithm;
- (NSString *) algorithmAsString;

- (NSString *) longDescription;

- (NSString *) type;
- (NSString *) keyid;
- (NSString *) shortid;
- (NSInteger) keylength;

- (NSDate *) creationDate;
- (NSDate *) expiryDate;

- (NSInteger) localid;
- (NSString *) ownertrust;
- (NSString *) trust;
- (NSString *) trustDescription;
- (NSString *) capabilities;

// deal with subkeys
- (NSInteger) subkeyCount;
- (BOOL) hasSubkeyWithID:(NSString*) ID;

//- (NSString *) longDescription;

- (void) dealloc;
- (NSComparisonResult) compare:(id)object;
- (NSString *) description;
@end
