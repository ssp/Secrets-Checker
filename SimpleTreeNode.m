/*
	SimpleTreeNode.m
	Copyright (c) 2001 by Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

        Tree node data structure carrying simple data (SimpleTreeNode, and SimpleNodeData).
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "SimpleTreeNode.h"

#define KEY_GROUPNAME	@"Group"
#define KEY_ENTRIES	@"Entries"

@implementation SimpleNodeData

- (id) initWithName:(NSString*) str isLeaf:(BOOL) leaf
{
	return [self initWithName:str andSecret:@"" isLeaf:leaf];
}


- (id)initWithName:(NSString*)str andSecret:(NSString*) sec isLeaf:(BOOL)leaf
{
    self = [super init];
    if (self==nil) return nil;
    name = [str retain];
	 secret = [sec retain];
    isLeaf = leaf;
    iconRep = nil;
    isExpandable = !isLeaf;

	 if (!isLeaf) [self setIsExpanded:YES];
	 
    return self;
}



+ (id)leafDataWithName:(NSString*)str andSecret:(NSString*) sec {
    // Convenience method to return a leaf node with its name set.
	return [[[SimpleNodeData alloc] initWithName:str andSecret:sec isLeaf:YES] autorelease];
}

+ (id)groupDataWithName:(NSString*)str {
    // Convenience method to return a branch node with its name set.
	return [[[SimpleNodeData alloc] initWithName:str andSecret:@"" isLeaf:NO] autorelease];
}

- (void)dealloc {
    [name release];
    [iconRep release];
    name = nil;
    iconRep = nil;
    [super dealloc];
}

- (void)setName:(NSString *)str { 
    if (!name || ![name isEqualToString: str]) {
	[name release]; 
	name = [str retain]; 
    }
}

- (NSString*)name { 
    return name; 
}


- (void)setSecret:(NSString *)sec {
	if (!secret || ![secret isEqualToString: sec]) {
		[secret release];
		secret = [sec retain];
	}
}

- (NSString*)secret {
	return secret;
}




- (void)setIsLeaf:(BOOL)leaf { 
    isLeaf = leaf; 
}

- (BOOL)isLeaf { 
    return isLeaf; 
}

- (BOOL)isGroup { 
    return !isLeaf; 
}

- (void)setIconRep:(NSImage*)ir {
    if (!iconRep || ![iconRep isEqual: ir]) {
	[iconRep release];
	iconRep = [ir retain];
    }
}
- (NSImage*)iconRep {
    return iconRep;
	// ignore the variable and return icon depending on whether we're a leaf or a folder
//	if ([self isLeaf]) {return [[Data Data] documentMiniIcon];}
//	return [[Data Data] folderMiniIcon];
}

- (void)setIsExpandable: (BOOL)expandable {
    isExpandable = expandable;
}

- (BOOL)isExpandable {
    return isExpandable;
}

- (BOOL) isExpanded { return isExpanded;}
- (void) setIsExpanded:(BOOL) b
{
	if (![self isLeaf]) isExpanded = b;
}


- (NSString*)description { 
   // return name;
	return [NSString stringWithFormat:@"%@:\n%@\n",name,secret];
}

- (NSComparisonResult) compare:(SimpleNodeData*)other {
    // We want the data to be sorted by name, so we compare [self name] to [other name]
    return [name compare: [other name]];
}

@end




@implementation SimpleTreeNode


- (id) initWithArray:(NSArray*) ar
{
	NSEnumerator * 	myEnum = [ar objectEnumerator];
	NSDictionary *		myDict;
	SimpleNodeData*	myData;
	SimpleTreeNode*	child;

	self = [super initWithData:[SimpleNodeData groupDataWithName:@"Root"] parent:nil children:[NSArray array]];

	while (myDict = [myEnum nextObject]) {
		if ([myDict objectForKey:SCDataItemsKey]) {
			// this is a folder => call self again on its items
			child = [SimpleTreeNode treeFromArray:[myDict objectForKey:SCDataItemsKey]];
			myData = (SimpleNodeData*)[child nodeData];
			[myData setName:[myDict objectForKey:SCDataNameKey]];
			[myData setIsExpanded:[[myDict objectForKey:SCGroupIsExpandedKey] integerValue]];
		}
		else {
			// otherwise this is a secret, so
			child = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:[myDict objectForKey:SCDataNameKey] andSecret:[myDict objectForKey:SCDataSecretKey]] parent:nil children:[NSArray array]] autorelease];
		}
		[self insertChild:child atIndex:[self numberOfChildren]];
	}
	return self;
}

+ (id) treeFromArray:(NSArray*) ar
{
	return [[[SimpleTreeNode alloc] initWithArray:ar] autorelease];
}


+ (id) nodeWithPath:(NSString*) path
{
	NSFileManager * fm = [NSFileManager defaultManager];
	NSMutableArray *children;
	NSArray	*subpaths;
	NSEnumerator *myEnum;
	NSString * fileName;
	BOOL isDir;
	SimpleTreeNode *result, *child;
	SimpleNodeData *data;

	debugLog(@"nodeWithPath: %@", path);
	
	if ([fm fileExistsAtPath:path isDirectory:&isDir] && isDir) {
		// the path points to a folder
		subpaths = [fm directoryContentsAtPath:path];
		children = [NSMutableArray arrayWithCapacity:[subpaths count]];
		myEnum = [subpaths objectEnumerator];

		while (fileName = [myEnum nextObject]) {
			child = [self nodeWithPath:[path stringByAppendingFormat:@"/%@",fileName]];
			if (child) [children addObject:child];
		}
		data = [SimpleNodeData groupDataWithName:[path lastPathComponent]];
		result = [[SimpleTreeNode alloc] initWithData:data parent:nil children:children];
	}
	else {
		NSDictionary *attributes = [fm fileAttributesAtPath:path traverseLink:YES];
		if ([fm fileExistsAtPath:path] && ([[attributes objectForKey:NSFileSize] integerValue] < SCMaxImportFileSize)) {
			// the file exists and is reasonably small.
			NSStringEncoding myEncoding;
			NSError * myError = nil;
			data = [SimpleNodeData leafDataWithName:[path lastPathComponent] andSecret:[NSString stringWithContentsOfFile:path usedEncoding: &myEncoding error: &myError]];
			result =[[SimpleTreeNode alloc] initWithData:data parent:nil children:[NSArray array]];
		}
		else {
			[NOTCENTER postNotificationName:SCErrorMessageNotification object:nil userInfo:[NSDictionary dictionaryWithObject:path forKey:SCCouldntImportKey]];
			return nil;
		}
	}
	return [result autorelease];
}



- (NSArray*) arrayForTree
{
	NSMutableArray * ar = [NSMutableArray arrayWithCapacity:[self numberOfChildren]];
	NSEnumerator *	myEnum = [[self children] objectEnumerator];
	SimpleTreeNode * myNode;
	SimpleNodeData * myData;

	while (myNode = (SimpleTreeNode*)[myEnum nextObject]) {
		myData = (SimpleNodeData*) [myNode nodeData];
		if ([myData isLeaf]) {
			[ar addObject:[NSDictionary dictionaryWithObjectsAndKeys:[myData name], SCDataNameKey, [myData secret], SCDataSecretKey, nil]];
		}
		else {
			[ar addObject:[NSDictionary dictionaryWithObjectsAndKeys:[myData name], SCDataNameKey, [myNode arrayForTree], SCDataItemsKey, [NSNumber numberWithBool:[myData isExpanded]], SCGroupIsExpandedKey, nil]];
		}
	}

	return ar;
}


- (NSArray*) subtreeWithFilter:(NSString*) filter searchingSecrets:(BOOL) searchSecrets allowDuplicates:(BOOL) duplicates leafsOnly:(BOOL) leafsOnly
{
	NSEnumerator * 	myEnum = [[self children] objectEnumerator];
	SimpleTreeNode*	myNode;
	NSMutableArray*	a = [NSMutableArray array];

	while (myNode = [myEnum nextObject]) {
		if ([myNode containsString:filter searchingSecrets:searchSecrets leafsOnly:leafsOnly]) {
			// found the string
			[a addObject:myNode];
			if ([myNode numberOfChildren] && duplicates) {
				// if we allow duplicates go and search a folder even if it has been inserted into the result array
				[a addObjectsFromArray:[myNode subtreeWithFilter:filter searchingSecrets:searchSecrets allowDuplicates:duplicates leafsOnly:leafsOnly]];
			}
		}
		else {
			// we didn't find the string but will go on searching if this is a folder
			if ([myNode numberOfChildren]) {
				[a addObjectsFromArray:[myNode subtreeWithFilter:filter searchingSecrets:searchSecrets allowDuplicates:duplicates leafsOnly:leafsOnly]];
			}
		}
	}
	return a;	
}


- (BOOL) containsString:(NSString*) s searchingSecrets:(BOOL) searchSecrets  leafsOnly:(BOOL) leafsOnly

{
	SimpleNodeData * d = (SimpleNodeData*)[self nodeData];

	if (leafsOnly && [d isGroup]) return NO;
	
	if ([[d name] rangeOfString:s options:NSCaseInsensitiveSearch].length) return YES;

	if ( !searchSecrets ) return NO;

	if ([[d secret] rangeOfString:s options:NSCaseInsensitiveSearch].length) return YES;

	return NO;
}

-(NSString*) listForTreeTabbed:(BOOL) tabbed
{
	NSEnumerator* myEnum;
	SimpleTreeNode* item;
	SimpleNodeData* data = (SimpleNodeData*) [self nodeData];
	NSString* formatString;
	NSMutableString* s = [NSMutableString string];
	
	if ([data isLeaf]) {
		if (!tabbed) formatString = @"%@:\n%@\n\n";
		else formatString = @"%@\t%@\n";
		return [NSString stringWithFormat:formatString, [self hierarchicalName], [data secret]];
	}
	else {
		myEnum = [[self children] objectEnumerator];
		while (item = [myEnum nextObject]) {
			[s appendString:[item listForTreeTabbed:tabbed]];
		}
		return s;
	}
}


-(NSString*) hierarchicalName
{
	NSString * name = [(SimpleNodeData*)[self nodeData] name];

	if ([self nodeParent]) {
		return [NSString stringWithFormat:@"%@/%@", [(SimpleTreeNode*)[self nodeParent] hierarchicalName], name];
	}
	// don't return anything if there is no parent as then we're the root node ourselves.
	return @"";
}	

/*

// ---------------------------------------------------------------
// NSObject method isEqual:
// In this case, with NSArchiving, implementing isEqual is necessary
// to get the expended items persistence to work.
// ---------------------------------------------------------------

-(BOOL) isEqual:(id) anObject
{
	if (([anObject isKindOfClass:[Item class]]) &&
	  ([[anObject hierarchichalName] isEqualToString:[self hierarchichalName]]))
		{
		return YES;
		}
	return NO;
}
*/
/*
// ---------------------------------------------------------------
// NSCoding protocol and NSKeyValueCoding implementation
// ---------------------------------------------------------------

-(id) initWithCoder:(id) coder
{
	int version = 0;

	if(self = [super init])
		{
		version = [coder versionForClassName:@"Item"];
		NSAssert(version != NSNotFound, @"version of Item not found");
		name = [[coder decodeObject] retain];
//		_nodeParent = [[coder decodeObject] retain];
//		_nodeChildren = [[coder decodeObject] retain];
		}
	return self;
}

-(void) encodeWithCoder:(id) coder
{
	[coder encodeObject: name];
	// note: I'm not sure if encodeConditionalObject is correct here.
 // the reason would be is that _nodeParent may already have been
 // encoded by another Item object.
	[coder encodeConditionalObject:_nodeParent];
	[coder encodeObject:_nodeChildren];
}


*/



@end


