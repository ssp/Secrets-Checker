//
//  SimpleTreeNode.h
//
//  Copyright (c) 2001 Apple. All rights reserved.
//

//********************************************************
// Enhanced by 'secret' property and related methods (ssp)
//********************************************************
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "TreeNode.h"
#import "Data.h"


#define SCDataItemsKey @"items"
#define SCDataNameKey @"name"
#define SCDataSecretKey @"secret"
#define SCGroupIsExpandedKey @"expanded"



@interface SimpleNodeData : TreeNodeData {
@private
	NSString *name;
	NSString *secret;
	NSImage *iconRep;
	BOOL isLeaf;
	BOOL isExpandable;

	BOOL isExpanded;
}

- (id)initWithName:(NSString*)str andSecret:(NSString*) sec isLeaf:(BOOL)leaf;

+ (id)leafDataWithName:(NSString*)name andSecret:(NSString*) sec;
    // Convenience method to return a leaf node with its name set.

+ (id)groupDataWithName:(NSString*)name;
    // Convenience method to return a branch node with its name set.
    
- (void)setName:(NSString*)name;
- (NSString*)name;
    // Set and get the name.

- (void)setSecret:(NSString*)sec;
- (NSString*)secret;
	// Set and get the name.



- (void)setIsLeaf:(BOOL)isLeaf;
- (BOOL)isLeaf;
- (BOOL)isGroup;
    // Set and determine the type of this item (leaf or group).

- (void)setIconRep:(NSImage*)iconRep;
- (NSImage*)iconRep;
    // Set and get the icon displayed next to the 

- (void)setIsExpandable: (BOOL)checked;
- (BOOL)isExpandable;
    // Set and get the expandability of this item.

- (BOOL) isExpanded;
- (void) setIsExpanded:(BOOL) b;

@end

@interface SimpleTreeNode : TreeNode {
}

- (id) initWithArray:(NSArray*) ar;
+ (id) treeFromArray:(NSArray*) ar;
+ (id) nodeWithPath:(NSString*) path;

- (NSArray*) arrayForTree;

- (BOOL) containsString:(NSString*) s searchingSecrets:(BOOL) searchSecrets  leafsOnly:(BOOL) leafsOnly;
- (NSArray*) subtreeWithFilter:(NSString*) filter searchingSecrets:(BOOL) searchSecrets allowDuplicates:(BOOL) duplicates leafsOnly:(BOOL) leafsOnly;

-(NSString*) listForTreeTabbed:(BOOL) tabbed;
-(NSString*) hierarchicalName;


@end

