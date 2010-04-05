//
//  Key.m
//  GPG Checker
//
//  Created by Sven-S. Porst on Sun Jan 13 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Key.h"


@implementation Key

//
// separate main key part from subkeys and split up main keys into their Array
//
- (id) initWithWithColonsString:(NSString *)keyString
{
	NSArray * subkeyParts = [keyString componentsSeparatedByString:@"\n"];

	[super init];

	mainKeyParts = [[[subkeyParts objectAtIndex:0] componentsSeparatedByString:@":"] retain];
	// NSLog([subkeyParts description]);
	if ([subkeyParts count] > 1) {
		subkeys = [[subkeyParts subarrayWithRange:NSMakeRange(1,[subkeyParts count]-1)] retain];
		// NSLog([subkeys description]);
	}
	else {
		subkeys = nil;
	}

	return self;
}
	

- (NSString *) name
{
	NSRange 		 r1;
	NSRange 		 r2;
	NSString		* NameAndMail = [self userid];
	
	// Assume the name string is of form
	// 'Name' or 'Name <email@domain.com>'
	
	// check for < and >
	r1 = [NameAndMail rangeOfString:@"<"];
	r2 = [NameAndMail rangeOfString:@">"];

	if ((r1.length != 0) && (r2.length != 0))
		{
		// we've got an e-mail address, the name is everything before the first <
		return [NameAndMail substringToIndex:r1.location];

		//!!
		// try to get rid of trailing spaces occasionally
		//!!
		}
	else
		{
		// no e-mail address, everything is the name
		return NameAndMail;
		}	
}




- (NSString*) email
{
	NSString		* NameAndMail = [self userid];
	NSRange 		 r1,r2;

	// Assume the name string is of form
	// 'Name' or 'Name <email@domain.com>'

	// check for < and >
	r1 = [NameAndMail rangeOfString:@"<"];
	r2 = [NameAndMail rangeOfString:@">"];

	if ((r1.length != 0) && (r2.length != 0))
		{
		// we've got an e-mail address, the name is everything before the first <
		return [NameAndMail substringWithRange:NSMakeRange(r1.location+1,r2.location-r1.location-1)];
		
		//Perhaps insert some sanity checks, whether we've rally got an e-mail address?
		}
	else
		{
		// no e-mail address
		return @"";
		}
}

- (NSString *) userid
{
	return [mainKeyParts objectAtIndex:8];
}


- (NSString *) longDescription
{
#warning 64BIT: Check formatting arguments
	return [NSString stringWithFormat:@"%@ (ID %@, %@ %d bit)", [self userid], [self shortid], [self algorithmAsString], [self keylength]];
}


-(NSInteger) algorithm
{
	return [[mainKeyParts objectAtIndex:2] integerValue];
}


- (NSString *)	algorithmAsString
{
	switch ([self algorithm]) {
		case 1: return @"RSA";
		case 16: return @"ElG";
		case 17: return @"DH";
		case 20: return @"ElG";
		default: return @"?";
	}
}


- (NSString *) type
{
	// NSLog(@"%@ %d bit", [self algorithmAsString], [self keylength]);
#warning 64BIT: Check formatting arguments
	return [NSString stringWithFormat:@"%@ %d bit", [self algorithmAsString], [self keylength]];
}


- (NSInteger) keylength
{
	return [[mainKeyParts objectAtIndex:1] integerValue];
}


- (NSString *) keyid
{
	return [mainKeyParts objectAtIndex:3];
}


- (NSString *) shortid
{
	// actually we only want the last 8 characters of the 16 character keyid
	NSString * s = [self keyid];

	if (s && [s length] > 8) {
		return [s substringFromIndex:8];
	}
	else {
		return @"?";
	}
}



- (NSDate *) creationDate
{
	return [NSDate dateWithString:[[mainKeyParts objectAtIndex:4] stringByAppendingString:@" 00:00:00 +0000"]];
}


- (NSDate *) expiryDate
{
	if ([[mainKeyParts objectAtIndex:5] keylength]) {
		return [NSDate dateWithString:[[mainKeyParts objectAtIndex:5] stringByAppendingString:@" 00:00:00 +0000"]];
	}
	else {
		return nil;
	}
}


- (NSInteger) localid
{
	return [[mainKeyParts objectAtIndex:6] integerValue];
}


- (NSString*) trust
{
	return [mainKeyParts objectAtIndex:0];
}

- (NSString*) trustDescription
{
	NSString	* s = [self trust];

	if ([s isEqual:@"o"]) { return NSLocalizedString(@"unknown (new)", @"unknown (new)");}
	else if ([s isEqual:@"i"]) { return NSLocalizedString(@"invalid", @"invalid");}													
	else if ([s isEqual:@"d"]) { return NSLocalizedString(@"disabled", @"disabled");}
	else if ([s isEqual:@"r"]) { return NSLocalizedString(@"revoked", @"revoked");}
	else if ([s isEqual:@"e"]) { return NSLocalizedString(@"expired", @"expired");}
	else if ([s isEqual:@"q"]) { return NSLocalizedString(@"undefined", @"undefined");}
	else if ([s isEqual:@"n"]) { return NSLocalizedString(@"untrusted", @"untrusted (negative)");}
	else if ([s isEqual:@"m"]) { return NSLocalizedString(@"marginal", @"marginal");}
	else if ([s isEqual:@"f"]) { return NSLocalizedString(@"full", @"fully trusted");}
	else if ([s isEqual:@"u"]) { return NSLocalizedString(@"ultimate", @"ultimate");}
	else {return NSLocalizedString(@"unknown trustlevel", @"unknown trustlevel");}
}


- (NSString*) ownertrust
{
	return [mainKeyParts objectAtIndex:7];
}

- (NSString *) signatureClass
{
	return [mainKeyParts objectAtIndex:9];
}


- (NSString *) capabilities
{
	return [mainKeyParts objectAtIndex:10];
}


//- (NSString *) longDescription;


//
// DEAL WITH SUBKEYS
//
- (NSInteger) subkeyCount
{
	return [subkeys count];
}

- (BOOL) hasSubkeyWithID:(NSString*) ID
{
	NSEnumerator *	myEnum = [subkeys objectEnumerator];
	NSString * myItem;
	NSArray * myArray;
	// NSLog([subkeys description]);

	while ((myItem = [myEnum nextObject]) && ![myItem isEqual:@""] ) {
#warning 64BIT: Check formatting arguments
		NSLog(myItem);
		myArray = [myItem componentsSeparatedByString:@":"];
		if ([[myArray objectAtIndex:4] isEqual:ID]) {
			return true;
		}
	}
	return false;
}





- (void) dealloc {
	if (mainKeyParts) { [mainKeyParts release];}
	if (subkeys) { [subkeys release];}

	[super dealloc];
}
	
- (NSComparisonResult) compare:(id)object
{
	if ([object class] == [Key class]) {
		// special treatment for other Key objects
		return [[self name] caseInsensitiveCompare:[object name]];
	}
	else {
		// otherwise compare descriptions
		return [[self description] caseInsensitiveCompare:[object description]];
	}
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"mainKey:%@\nsubkeys:%@",mainKeyParts, subkeys]; 
}

@end
