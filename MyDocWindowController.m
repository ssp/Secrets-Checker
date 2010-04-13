//
//  MyDocWindowConotroller.m
//  Secrets Checker
//
//  Created by Sven-S. Porst on Fri Mar 15 2002.
//  Copyright (c) 2002-2010 earthlingsoft. All rights reserved.
//

#import "MyDocWindowController.h"


@implementation MyDocWindowController


#pragma mark ACTIONS


- (IBAction) addItem:(id) sender
{
	// Adds a new leaf entry to the current selection, by inserting a new leaf node.
	[self _addNewDataToSelection: [[[SimpleTreeNode alloc] initWithData: [SimpleNodeData leafDataWithName:SCNewSecretName andSecret:@""] parent:nil children:[NSArray array]] autorelease]];
}
	
- (IBAction) addFolder:(id) sender
{
	// Adds a new expandable entry to the current selection, by inserting a new group node.
	[self _addNewDataToSelection:[[[SimpleTreeNode alloc] initWithData: [SimpleNodeData groupDataWithName:SCNewFolderName] parent:nil children:[NSArray array]] autorelease]];
}
	
- (IBAction) deleteItem:(id) sender
{
	NSArray *selection = [self selectedNodes];

	// Tell all of the selected nodes to remove themselves from the model.
	[selection makeObjectsPerformSelector: @selector(removeFromParent)];
	[browser deselectAll:nil];
	[browser reloadData];	
}

/*
- (BOOL)textShouldEndEditing:(NSText *)aTextObject
{
	debugLog(@"[MyDocWindowController textShouldEndEditing]")
	return YES;
}
*/

- (void)textDidEndEditing:(NSNotification *)aNotification
{
	debugLog(@"[MyDocWindowController textDidEndEditing]");
	[self touch];
	[currentItem setSecret:[[[textField string] copy] autorelease]];
}


- (IBAction) changeEncryptionType:(id) sender
{
//	int 	nr= [[sender selectedItem] tag];
	NSInteger	nr = [sender tag];
	[self setPreviousEncryptionType:[[self document] encryptionType]];
	[[self document] setEncryptionTypeByInt:nr];

	if ([[self previousEncryptionType] isEqualToString:[[self document] encryptionType]]) {
		[self touch];
	}
	
	// activate 'Options' button for everything but 'none'
	if (nr != SCNoEncryption){
	//	[optionsButton setEnabled:YES];
		[self showOptions:self];
	}
	else {
	//	[optionsButton setEnabled:NO];
	}

}



- (IBAction) showOptions:(id) sender
{
	if ([[[self document] encryptionType] isEqualToString:SCSymmetricEncryptionKey]) {
		[self showSymmetricOptions:sender];
	}
	else if ([[[self document] encryptionType] isEqualToString:SCPublicKeyEncryptionKey]) {
		[self showPublicKeyOptions:sender];
	}
}



- (IBAction) changeSelection:(id) sender
{
	debugLog(@"changeSelection");
/*
	// This message is sent from the outlineView as it's action (see the connection in IB).
	NSArray *selectedNodes = [self selectedNodes];
	SimpleNodeData* theData;

#ifdef debugbuild
	NSLog(@"changeSelection To:\n%@",[selectedNodes description]);
#endif
	
	if ([selectedNodes count]>1) {
		//		[textField setStringValue: SCMultipleSelection];
		[textField setString: SCMultipleSelection];
		currentItem = nil;
		[textField setEditable:NO];
	}
	else if ([selectedNodes count]==1) {
		// exactly one node is selected
		theData = NODE_DATA([selectedNodes objectAtIndex:0]);
		if ([theData isLeaf]) {
			// it's a leaf
			currentItem = theData;
			//			[textField setStringValue: [currentItem secret]];
			[textField setString: [currentItem secret]];
			[textField setEditable:YES];
		}
		else {
			// it's a branch
			currentItem = nil;
			//			[textField setStringValue:SCNodeSelection];
			[textField setString:SCNodeSelection];
			[textField setEditable:NO];
		}
	}
	else {
		//		[textField setStringValue:SCNoSelection];
		[textField setString:SCNoSelection];
		currentItem = nil;
		[textField setEditable:NO];
	}
*/
}




#pragma mark HANDLING THE DRAWER
- (IBAction) toggleDrawer:(id) sender
{
	BOOL drawerIsClosed = ([filterDrawer state] == NSDrawerClosedState);

	[[self document] setFilterDrawerIsOpen:(!drawerIsClosed)];
	[filterDrawer toggle:sender];
	if (drawerIsClosed) {
		[[self window] makeFirstResponder:filterField];
	}
}


- (void)drawerWillOpen:(NSNotification *)notification
{
	[[self document] setFilterDrawerIsOpen:YES];
	if (![[filterField stringValue] isEqualToString:@""]){
		[self changeFilterTo:[filterField stringValue]];
	}
	[[self window] makeFirstResponder:filterField];
}

- (void)drawerWillClose:(NSNotification *)notification
{
	[[self document] setFilterDrawerIsOpen:NO];
	if (![[filterField stringValue] isEqualToString:@""]){
		[self changeFilterTo:@""];
	}
}




- (IBAction) switchDisplayFolders:(id) sender
{
	[[self document] setFilterIncludeFolders:[sender integerValue]];
	[self changeFilterTo:[filterField stringValue]];
}

- (IBAction) switchLabelsOnly:(id) sender
{
	[[self document] setFilterSearchLabelsOnly:[sender integerValue]];
	[self changeFilterTo:[filterField stringValue]];
}


- (void)controlTextDidChange:(NSNotification *)aNotification
{
	// find out who's sending the notification. We're delegate of the outline view and the filter text field

	if ([[aNotification userInfo] objectForKey:@"NSFieldEditor"] == [filterField currentEditor]) {
		[self changeFilterTo:[filterField stringValue]];
	}
}


- (void) changeFilterTo:(NSString*) newFilter
{
	SimpleTreeNode *	root = nil;
	MyDocument *		d = [self document];
	NSArray *			oldSelection = [[[self selectedNodes] copy] autorelease];

	[currentFilter release];
	currentFilter = [newFilter retain];
	
	if ([newFilter length] > 0) {
		// the filter is non-trivial
		root = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData groupDataWithName:@"root"] parent:nil children:[NSArray array]] autorelease];

		[root insertChildren:[[d treeData] subtreeWithFilter:newFilter searchingSecrets:![d filterSearchLabelsOnly]  allowDuplicates:NO leafsOnly:![d filterIncludeFolders]] atIndex:0];

		[self setCurrentData:root];
		// don't accep d&d in Browser
		[browser unregisterDraggedTypes];
	}
	else {
		// the filter is trivial
		[self setCurrentData:[d treeData]];
		// re-activate d & d
		[browser registerForDraggedTypes:SCBrowserAcceptDraggedTypes];
	}

	[browser reloadData];
	
	// If there is a unique result, select it. Otherwise attempt to preserve the existing selection.
	if ( [root numberOfChildren] == 1 ) {
		NSArray * uniqueResult = [NSArray arrayWithObject:[root childAtIndex:0]];
		[browser selectItems:uniqueResult byExtendingSelection:NO];
	}
	else {
		[browser selectItems:oldSelection byExtendingSelection:NO];		
	}
}


#pragma mark EXPORTING DATA

-(IBAction) export:(id)sender
{
	NSSavePanel *sp = [NSSavePanel savePanel];

	[sp setCanSelectHiddenExtension:NO];
//	[sp setDelegate:self];
	[sp setAccessoryView:exportAuxiliaryView];
	[sp beginSheetForDirectory:nil file:NSLocalizedString(@"Exported Secrets", @"Exported Secrets Default Filename") modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)savePanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo;
{
	id resultObject = nil;
	NSArray* items = ([[self selectedNodes] count]) ? [self selectedNodes] : [[self currentData] children];
	SimpleTreeNode * node = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData groupDataWithName:@"root"] parent:nil children:items] autorelease];

	
	if (returnCode == NSOKButton) {
		NSInteger selectedFormat = [[exportFormatPopup selectedItem] tag];
		NSString * path =[(NSSavePanel*)sheet filename];
		debugLog(@"%@", path);
			
		if (selectedFormat == 0) {
			// SC Property List
			resultObject = [node arrayForTree];
		}
		else if (selectedFormat == 1) {
			// tab/cr format
			resultObject = [node listForTreeTabbed:YES];
		}
		else if (selectedFormat == 2) {
			// human readable
			resultObject = [node listForTreeTabbed:NO];
		}
		
		[resultObject writeToFile:path atomically:NO];
		[[NSFileManager defaultManager] changeFileAttributes:
			[NSDictionary dictionaryWithObjectsAndKeys:
				 [NSNumber numberWithLong:'TEXT'], NSFileHFSTypeCode, nil] atPath:path];
	}
	else {
		// dann eben nicht
	}
	[sheet orderOut:self];
}




#pragma mark SYMMETRIC OPTION SHEET

- (void) showSymmetricOptions:(id) sender
{
	MyDocument*		d = [self document];

	// fill text fields
	[symmetricPasswordField setStringValue:[d passphrase]];
	[symmetricRePasswordField setStringValue:[d passphrase]];
	[symmetricHintField setStringValue:[d passphraseHint]];

	// setup matrix
	[algorithmMatrix selectCellWithTag:[d useCustomSymmetricCipher]];

	// setup popup menu
	[algorithmPopup removeAllItems];
	[algorithmPopup addItemsWithTitles:[[Data Data] cipherAlgorithms]];
	if (![[d customSymmetricCipher] isEqualToString:@""]) {
		// restore old setting
		[algorithmPopup selectItemWithTitle:[d customSymmetricCipher]];
	}
	else if ([algorithmPopup numberOfItems]) {
		// otherwise select first item if there is one
		[algorithmPopup selectItemAtIndex:0];
	}
	[algorithmPopup setEnabled:[d useCustomSymmetricCipher]];

	// Showtime!
	[NSApp beginSheet:symmetricSettingsSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(symmetricSheetEnded:returnCode:contextInfo:) contextInfo:sender];
}



- (void) symmetricSheetEnded:(NSWindow *) sheet returnCode:(NSInteger) returnCode contextInfo:(void*) contextInfo
{
	NSString * type;

	debugLog(@"symmetricSheetEnded with returnCode: %u", returnCode);

	if (returnCode == 1) {
		// sheet was cancelled
		if ([(NSObject*)contextInfo isKindOfClass:[MyDocWindowController class]]) {
			// sheet was invoked by change in popup menu, so
			// 1. restore previous setting
			type = [self previousEncryptionType];
			[[self document] setEncryptionType:type];
			// 2. restore old setting of popup button
			// [encryptionPopup selectItemWithTitle:type];
			// 3. if necessary, disable Options button
			// [optionsButton setEnabled:![type isEqualToString:SCNoEncryptionKey]];
		}
		else {
			// whatever
		}
	}
	else if (returnCode == 0) {
		// sheet was OKed
		// everything is done in the OK Button handler
	}

	// remove sheet
	[sheet orderOut:self];
	// clean up
	[statusField setStringValue:@""];
}


- (IBAction)changeSymmetricMatrix:(id)sender
{
	[algorithmPopup setEnabled:[[sender selectedCell] tag]];
}



// called by the OK button. This has to check whether both passphrases are identical and non-empty and report the error if they're not. Or dismiss the sheet if everything is hunky dory.
- (IBAction)OKSymmetricSettingsSheet:(id)sender
{
	NSString*	passwd = [symmetricPasswordField stringValue];
	MyDocument*	d;

	if (![passwd isEqualToString:[symmetricRePasswordField stringValue]]) {
		// strings are different
		NSBeep();
		[statusField setStringValue:NSLocalizedString(@"The two passwords aren't identical.",@"The two passwords aren't identical.")];
		return;
	}
	if ([passwd isEqualToString:@""]) {
		// password is empty
		NSBeep();
		[statusField setStringValue:NSLocalizedString(@"Password needs to be non-empty.",@"Password needs to be non-empty.")];
		return;
	}

	// everything is fine then...
	[self touch];

	d = [self document];
	[d setUseCustomSymmetricCipher:[[algorithmMatrix selectedCell] tag]];
	[d setCustomSymmetricCipher:[algorithmPopup titleOfSelectedItem]];
	[d setPassphrase:passwd];
	[d setPassphraseHint:[symmetricHintField stringValue]];

	// go away for good
	[NSApp endSheet:symmetricSettingsSheet returnCode:0];
}



- (IBAction)cancelSymmetricSettingsSheet:(id)sender
{
	[NSApp endSheet:symmetricSettingsSheet returnCode:1];
}




#pragma mark PUBLIC KEY OPTIONS SHEET

- (void) showPublicKeyOptions:(id) sender
{
	MyDocument*		d = [self document];
	NSArray*			keyArray = [[Data Data] privateKeys];
	NSEnumerator*	myEnum = [keyArray objectEnumerator];
	NSArray*			myObj;
	NSString*		docKey = [d keyID];
	NSString*		prefsKey = [PREFS stringForKey:SCEncryptToKey];

	// setup popup menu
	[privateKeyPopup removeAllItems];

	while (myObj = [myEnum nextObject]){
		//myArray = [myObj componentsSeparatedByString:@":"];
		[privateKeyPopup addItemWithTitle:[NSString stringWithFormat:@"%@ (ID: %@, %@ bit)", [myObj objectAtIndex:9], [[myObj objectAtIndex:4] substringFromIndex:8], [myObj objectAtIndex:2]]];
		[[privateKeyPopup lastItem] setRepresentedObject:[myObj objectAtIndex:4]];
	}

	// determine which key should be selected in the menu with the following priority:
   //  1. as saved in document
	//  2. as set in user defaults
   //  3. first item
	// ... and select the best match in the menu

	if ([privateKeyPopup numberOfItems]) {
		// there are keys
  		// just in case select first item first
		[privateKeyPopup selectItemAtIndex:0];

		// now try better matches
		myEnum = [[[Data Data] privateKeys] objectEnumerator];
		
		while (myObj = [myEnum nextObject]) {
			if ([prefsKey isEqualTo:[myObj objectAtIndex:4]]) {
				[privateKeyPopup selectItemAtIndex:[keyArray indexOfObject:myObj]];
			}

			if ([docKey isEqualTo:[myObj objectAtIndex:4]]) {
				[privateKeyPopup selectItemAtIndex:[keyArray indexOfObject:myObj]];
				break;
			}
		}

		[privateKeyPopup setEnabled:YES];
		[publicKeyOKButton setEnabled:YES];
	}
	else {
		// there are no private keys
		[privateKeyPopup addItemWithTitle:NSLocalizedString(@"No private keys found.", @"No private keys found (for key popup)")];
		[privateKeyPopup selectItemAtIndex:0];
		[privateKeyPopup setEnabled:NO];
		[publicKeyOKButton setEnabled:NO];
	}

	// Showtime!
	[NSApp beginSheet:publicKeySettingsSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(publicKeySheetEnded:returnCode:contextInfo:) contextInfo:sender];

}


- (void) publicKeySheetEnded:(NSWindow *) sheet returnCode:(NSInteger) returnCode contextInfo:(void*) contextInfo
{
	NSString *			type;

	if (returnCode == 1) {
		// sheet was cancelled
		if ([(NSObject*)contextInfo isKindOfClass:[MyDocWindowController class]]) {
			// sheet was invoked by change in popup menu, so
			// 1. restore previous setting
			type = [self previousEncryptionType];
			[[self document] setEncryptionType:type];
			// 2. restore old setting of popup button
			//[encryptionPopup selectItemWithTitle:type];
			// 3. if necessary, disable Options button
			//[optionsButton setEnabled:![type isEqualToString:SCNoEncryptionKey]];
		}
		else {
			// whatever
		}
	}
	else if (returnCode == 0) {
		// sheet was OKed
		// everything is done in the OK Button handler
	}

	// remove sheet
	[sheet orderOut:self];
}


- (IBAction)OKPublicKeySheet:(id) sender
{
	[self touch];
	[[self document] setKeyID:[[privateKeyPopup selectedItem] representedObject]];
	
	// go away for good
	[NSApp endSheet:publicKeySettingsSheet returnCode:0];	
}


- (IBAction)cancelPublicKeySheet:(id) sender
{
	[NSApp endSheet:publicKeySettingsSheet returnCode:1];
}



#pragma mark OUTLINE VIEW DATA SOURCE & DELEGATE

// ================================================================
//  NSOutlineView data source methods. (The required ones)
// ================================================================

// Required methods.
- (id)outlineView:(NSOutlineView *)olv child:(NSInteger)index ofItem:(id)item {
	return [SAFENODE(item) childAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)olv isItemExpandable:(id)item {
	SimpleNodeData * data = NODE_DATA(item);
	BOOL isGroup = [data isGroup];
/*	BOOL isOpen = [data isExpanded];
	if (isGroup && isOpen) {
		[browser expandItem:item];
	}
	*/
	return isGroup;
}

- (NSInteger)outlineView:(NSOutlineView *)olv numberOfChildrenOfItem:(id)item {
//	NSLog(@"noC: %i",[SAFENODE(item) numberOfChildren]);
	return [SAFENODE(item) numberOfChildren];
}

- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	SimpleNodeData * data = NODE_DATA(item);
	//BOOL isGroup = [data isGroup];
//	BOOL isOpen = [data isExpanded];
	id objectValue = nil;

	// The return value from this method is used to configure the state of the items cell via setObjectValue:
	if([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) {
		objectValue = [data name];
		//if (isGroup && isOpen && ![browser isItemExpanded:item] ) {
			//NSLog(@"send expandItem Notification");
		//	[NOTCENTER postNotificationName:SCOpenOutlineItemNotification object:item];
			//	[browser setNeedsDisplay:YES];
		//}
	}
	
	return objectValue;
}

// Optional method: needed to allow editing.
- (void)outlineView:(NSOutlineView *)olv setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	SimpleNodeData * data = NODE_DATA(item);
	if([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) {
		[data setName: object];
		[self touch];
	}
}


// ================================================================
//  NSOutlineView delegate methods.
// ================================================================

- (BOOL)outlineView:(NSOutlineView *)olv shouldExpandItem:(id)item {
	return [NODE_DATA(item) isExpandable];
}

- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	SimpleNodeData * data = NODE_DATA(item);
	BOOL isGroup = [data isGroup];
//	BOOL isOpen = [data isExpanded];

	if ([[tableColumn identifier] isEqualToString: COLUMNID_NAME]) {
		if (![PREFS boolForKey:SCDisplayIcons]) {
			[(ImageAndTextCell*)cell setImage:nil];
		}
		else {
			if (!isGroup) {
				[(ImageAndTextCell*)cell setImage:[[Data Data] documentMiniIcon]];
			}
			else {
				//if (isGroup && isOpen) {
				//	[browser expandItem:item];
				//[browser reloadItem:nil reloadChildren:YES];
				//}				
				[(ImageAndTextCell*)cell setImage:[[Data Data] folderMiniIcon]];
			}
		}
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
//- (BOOL) selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView
{
//	NSArray *selectedNodes = [[self selectedNodes] arrayByAddingObject:item]; 
	NSArray *selectedNodes = [self selectedNodes]; 
	SimpleNodeData* theData;

#ifdef debugbuild
	NSLog(@"changingSelection"); // To:\n%@", [selectedNodes description]);
#endif

	// when selection changes, there goes our chance to undo.
	[[self undoManager] removeAllActions];

	if ([selectedNodes count]>1) {
		[textField setString: SCMultipleSelection];
		currentItem = nil;
		[textField setEditable:NO];
	}
	else if ([selectedNodes count]==1) {
		// exactly one node is selected
		theData = NODE_DATA([selectedNodes objectAtIndex:0]);
		if ([theData isLeaf]) {
			// it's a leaf
			currentItem = theData;
			[textField setString: [currentItem secret]];
			[textField setEditable:YES];
		}
		else {
			// it's a branch
			currentItem = nil;
			[textField setString:SCNodeSelection];
			[textField setEditable:NO];
		}
	}
	else {
		// there's nothing selected
		[textField setString:SCNoSelection];
		currentItem = nil;
		[textField setEditable:NO];
	}
//	return YES;
}


- (void)outlineViewItemDidExpand:(NSNotification *) aNotification
{
	id item = [[aNotification userInfo] objectForKey:@"NSObject"];
	[NODE_DATA(item) setIsExpanded:YES];
}

- (void)outlineViewItemDidCollapse:(NSNotification *) aNotification
{
	id item = [[aNotification userInfo] objectForKey:@"NSObject"];
	[NODE_DATA(item) setIsExpanded:NO];
}


/*
// ================================================================
//  NSOutlineView data source methods. (for persistant objects)
// ================================================================
- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item
{
	return [NSArchiver archivedDataWithRootObject:item]; // return NSData object
}

- (id)outlineView:(NSOutlineView *)outlineView
itemForPersistentObject:(id)data
{
	return [NSUnarchiver unarchiveObjectWithData:data]; // data is NSData
}
*/


// ================================================================
//  NSOutlineView data source methods. (dragging related)
// ================================================================

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard {
//	NSString * s;
	SimpleTreeNode * node;
	draggedNodes = items;
	// Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.

	// Provide data for our custom type, and simple NSStrings.
	[pboard declareTypes:[NSArray arrayWithObjects: DragDropSimplePboardType, /*NSFileContentsPboardType, NSFilenamesPboardType,*/ NSStringPboardType, nil] owner:self];

	// the actual data doesn't matter since DragDropSimplePboardType drags aren't recognized by anyone but us!.
	[pboard setData:[NSData data] forType:DragDropSimplePboardType];

	//
	node = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData groupDataWithName:@"root"] parent:nil children:items] autorelease];
	
	// Put string data on the pboard... notice you candrag into TextEdit!
	// should be Tabbed:[PREFS boolForKey:SCExportWithTabs] instead of NO
	[pboard setString:[node listForTreeTabbed:NO] forType: NSStringPboardType];

//	[pboard setData:[[[node arrayForTree] description] dataUsingEncoding:NSUTF8StringEncoding] forType:NSFileContentsPboardType];
//	[pboard setString:[[NSArray arrayWithObject:NSLocalizedString(@"Exported secrets.plist",@"Exported secrets.plist")] description] forType:NSFilenamesPboardType];
	
	return YES;
}



- (NSUInteger)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex {
	// This method validates whether or not the proposal is a valid one. Returns NO if the drop should not be allowed.
	SimpleTreeNode *targetNode = item;
	BOOL targetNodeIsValid = YES;
	BOOL isOnDropTypeProposal = childIndex==NSOutlineViewDropOnItemIndex;

	// Refuse if: dropping "on" the view itself unless we have no data in the view.
	if (targetNode==nil && childIndex==NSOutlineViewDropOnItemIndex && [[[self document] treeData] numberOfChildren]!=0)
		targetNodeIsValid = NO;

	if (targetNode==nil && childIndex==NSOutlineViewDropOnItemIndex)
		targetNodeIsValid = NO;

	// Refuse if: we are trying to do something which is not allowed as specified by the UI check boxes.
	if ([NODE_DATA(targetNode) isGroup] && isOnDropTypeProposal==YES ||
	  [NODE_DATA(targetNode) isLeaf] && isOnDropTypeProposal==YES)
		targetNodeIsValid = NO;

	// Check to make sure we don't allow a node to be inserted into one of its descendants!
	if (targetNodeIsValid && ([info draggingSource]==browser) && [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject: DragDropSimplePboardType]] != nil) {
		NSArray *_draggedNodes = [[[info draggingSource] dataSource] draggedNodes];
		targetNodeIsValid = ![targetNode isDescendantOfNodeInArray: _draggedNodes];
	}

	// Set the item and child index in case we computed a retargeted one.
	[browser setDropItem:targetNode dropChildIndex:childIndex];

	//NSLog(@"%d",targetNodeIsValid ? NSDragOperationGeneric : NSDragOperationNone);
	return targetNodeIsValid ? NSDragOperationGeneric : NSDragOperationNone;
}




- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(NSInteger)childIndex {
	TreeNode * 		parentNode = nil;

	// Determine the parent to insert into and the child index to insert at.

	if ([NODE_DATA(targetItem) isLeaf]) {
		parentNode = (SimpleTreeNode*)(childIndex==NSOutlineViewDropOnItemIndex ? [targetItem nodeParent] : targetItem);
		childIndex = (childIndex==NSOutlineViewDropOnItemIndex ? [[targetItem nodeParent] indexOfChild: targetItem]+1 : 0);
		if ([NODE_DATA(parentNode) isLeaf]) [NODE_DATA(parentNode) setIsLeaf:NO];
	} else {
		parentNode = SAFENODE(targetItem);
		childIndex = (childIndex==NSOutlineViewDropOnItemIndex?0:childIndex);
	}


	[self _performDropOperation:info onNode:parentNode atIndex:childIndex];

	return YES;
}




- (void)_performDropOperation:(id <NSDraggingInfo>)info onNode:(TreeNode*)parentNode atIndex:(NSInteger)childIndex {
	// Helper method to insert dropped data into the model.
	NSPasteboard * pboard = [info draggingPasteboard];
	NSMutableArray * itemsToSelect = nil;
	SimpleTreeNode * newItem = nil;

	[self switchResponders];
	[self touch];
	
	// Do the appropriate thing depending on wether the data is DragDropSimplePboardType or NSStringPboardType.
	if ([pboard availableTypeFromArray:[NSArray arrayWithObjects:DragDropSimplePboardType, nil]]) {
		//****************
		// INTERNAL DRAG
		//****************
		MyDocWindowController *dragDataSource = [[info draggingSource] dataSource];
		NSArray *_draggedNodes = [TreeNode minimumNodeCoverFromNodesInArray: [dragDataSource draggedNodes]];
		NSEnumerator *draggedNodesEnum = [_draggedNodes objectEnumerator];
		SimpleTreeNode *_draggedNode = nil, *_draggedNodeParent = nil;

		itemsToSelect = [NSMutableArray arrayWithArray:[self selectedNodes]];

		while ((_draggedNode = [draggedNodesEnum nextObject])) {
			_draggedNodeParent = (SimpleTreeNode*)[_draggedNode nodeParent];
			if (parentNode==_draggedNodeParent && [parentNode indexOfChild: _draggedNode]<childIndex) childIndex--;
			[_draggedNodeParent removeChild: _draggedNode];
		}
		[parentNode insertChildren: _draggedNodes atIndex: childIndex];
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]) {
		//***********
		// FILE DRAG
		//***********
		NSArray * filenamesArray = [[pboard stringForType:NSFilenamesPboardType] propertyList];
		NSEnumerator * myEnum = [filenamesArray objectEnumerator];
		NSString * path;
		SimpleTreeNode *newNode;
		NSMutableArray *newNodesArray = [NSMutableArray arrayWithCapacity:[filenamesArray count]];
		
		if ([filenamesArray count] > 1) {
			while (path = [myEnum nextObject]) {
				newNode = [SimpleTreeNode nodeWithPath:path];
				if (newNode) {
					[newNodesArray addObject:newNode];
				}
				else {
					// some error must have occured
					NSLog(@"some error occured while importing");
					NSBeep();
				}
			}
			itemsToSelect = [NSMutableArray arrayWithArray:newNodesArray];
			[parentNode insertChildren:newNodesArray atIndex:childIndex++];
		}
		else if ([filenamesArray count] == 1) {
			// it's only one file. In this case we offer the options sheet
			NSString * path = [filenamesArray objectAtIndex:0];
			[importOptionsFileName setStringValue:path];
			[importOptionsFileIcon setImage:[[NSWorkspace sharedWorkspace] iconForFile:path]];
			[NSApp beginSheet:importOptionsSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndImportOptions:returnCode:contextInfo:) contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:
				[filenamesArray objectAtIndex:0], @"path",
				parentNode, @"parentNode",
				[NSNumber numberWithInteger:childIndex], @"childIndex", nil] retain]];
		}
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject: NSStringPboardType]]) {
		//***********
		// TEXT DRAG
		//***********
		NSString *string = [pboard stringForType: NSStringPboardType];
		newItem = [SimpleTreeNode treeNodeWithData: [SimpleNodeData leafDataWithName:NSLocalizedString(@"Dropped Secret", @"Dropped Secret") andSecret:string]];

		itemsToSelect = [NSMutableArray arrayWithObject: newItem];
		[parentNode insertChild: newItem atIndex:childIndex++];
	}

	[browser reloadData];
	[browser selectItems:itemsToSelect byExtendingSelection: NO];
	if (![pboard availableTypeFromArray:[NSArray arrayWithObject:DragDropSimplePboardType]]) {
		// we inserted a string and its item still has to get a meaningful name, so switch on editing
		[browser editColumn:0 row:[browser rowForItem:newItem] withEvent:nil select:YES];
	}
}


- (void)_addNewDataToSelection:(SimpleTreeNode *)newChild {
	NSInteger childIndex = 0, newRow = 0;
	NSArray *selectedNodes = [self selectedNodes];
	SimpleTreeNode *selectedNode = ([selectedNodes count] ? [selectedNodes objectAtIndex:0] : [[self document] treeData]);
	TreeNode *parentNode = nil;
	SimpleNodeData *data = NODE_DATA(selectedNode);

	[self touch];
	
	if ([data isGroup] && [data isExpanded]) {
		parentNode = selectedNode;
		childIndex = 0;
	}
	else {
		parentNode = [selectedNode nodeParent];
		childIndex = [parentNode indexOfChildIdenticalTo:selectedNode]+1;
	}

	[parentNode insertChild: newChild atIndex: childIndex];
	[browser reloadData];

	[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidEndEditingNotification object:textField];

//	if ([data isExpanded]) [browser expandItem:newChild];
	newRow = [browser rowForItem: newChild];
	if (newRow>=0) [browser selectRow: newRow byExtendingSelection: NO];
	if (newRow>=0) [browser editColumn:0 row:newRow withEvent:nil select:YES];

	// make sure everyone knows about this to save the previously edited data
	//[[NSNotificationCenter defaultCenter] postNotificationName:NSOutlineViewSelectionDidChangeNotification object:self];
}



#pragma mark IMPORT SHEET

- (IBAction)cancelImportSheet:(id)sender
{
	[NSApp endSheet:importOptionsSheet returnCode:1];
}


- (IBAction)OKImportSheet:(id)sender
{
	[NSApp endSheet:importOptionsSheet returnCode:0]; 
}

- (void) didEndImportOptions:(NSWindow *) sheet returnCode:(NSInteger) returnCode contextInfo:(void*) contextInfo
{
	SimpleTreeNode * newNode;
	NSMutableArray * newItems = [NSMutableArray array];
	NSString * fromFile;
	NSDictionary * infoDict = (NSDictionary*) contextInfo;

	if (!returnCode) {
		NSData	*readData =[NSData dataWithContentsOfFile:[infoDict objectForKey:@"path"]];

		// determine encoding
		NSStringEncoding enc;
		switch ([[importOptionsEncodingSetting selectedItem] tag]) {
			case 0: enc = NSMacOSRomanStringEncoding; break;
			case 1: enc = NSUTF8StringEncoding; break;
			case 2: enc = NSUnicodeStringEncoding; break;
			case 3: enc = NSISOLatin1StringEncoding; break;
			case 4: enc = NSWindowsCP1252StringEncoding; break;
			default: ;
		}

		// read the file
		fromFile = [[[NSString alloc] initWithData:readData encoding:enc] autorelease];

		if ([[importOptionsImportSetting selectedCell] tag] == 0) {
			//
			// import as 'just one secret'
 			//
			newNode = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:[[infoDict objectForKey:@"path"] lastPathComponent] andSecret:fromFile] parent:nil children:[NSArray array]] autorelease];
			[newItems addObject:newNode];
		}
		else if ([[importOptionsImportSetting selectedCell] tag] == 1) {
			//
			// import as tab/cr file
			//
			NSScanner * scan = [NSScanner scannerWithString:fromFile];
			NSString * line;

			while ( [scan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"] intoString:&line]){
				if ([line length]) {
					// we did find characters, i.e no crlf
					NSArray * a = [line componentsSeparatedByString:@"\t"];
					newNode = [[[SimpleTreeNode alloc] initWithData:[SimpleNodeData leafDataWithName:[a objectAtIndex:0] andSecret:[[a subarrayWithRange:NSMakeRange(1,[a count] -1)] componentsJoinedByString:@"\t"]] parent:nil children:[NSArray array]] autorelease];
					if (newNode) [newItems addObject:newNode];
				}
			}
		}
		else if ([[importOptionsImportSetting selectedCell] tag] == 2) {
			//
			// import as SecretsChecker Property List
			//
			NSArray * ar;
			NS_DURING
				ar = [fromFile propertyList];
				if (ar && [ar isKindOfClass:[NSArray class]]) {
					newNode = [SimpleTreeNode treeFromArray:ar];
					if (newNode) [newItems addObjectsFromArray:[newNode children]];
				}
			NS_HANDLER
				NSBeep();
			NS_ENDHANDLER	
		}

		[[infoDict objectForKey:@"parentNode"] insertChildren:newItems atIndex:[[infoDict objectForKey:@"childIndex"] integerValue]];

		[browser reloadData];
		[browser selectItems:newItems byExtendingSelection: NO];
	}
	[infoDict release];
	[sheet orderOut:self];
}



#pragma mark PASSPHRASE SHEET

//
// called by notification that we need a passphrase
//
- (void) askForPassphrase:(NSNotification *)aNotification
{
	NSDictionary	* myDict = [aNotification userInfo];
	NSString 		* s = [myDict objectForKey:GPGTaskKeyID];
// Key				* myKey = [[Data Data] keyOwningSubkeyWithID:myKeyID];

	debugLog(@"[MyDocWindowController askForPassphrase:]");

	if (s) {
		// case for public key encryption
		// prepare sheet
		[passphraseSheetInfoTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Please enter the passphrase for your pgp key ID %@",@"Please enter passphrase for key %@"), [s substringFromIndex:8]]];
	}
	else {
		// symmetric case
		s = [[self document] passphraseHint];
		if (![s isEqualToString:@""]) {
			[passphraseSheetInfoTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"The follwing hint for the passphrase was saved along with the file\n%@", @"The follwing hint for the passphrase was saved along with the file\n%@"), s]];
		}
		else {
			[passphraseSheetInfoTextField setStringValue:NSLocalizedString(@"No hint was saved for the passphrase of this file. Good luck.",@"No hint was saved for the passphrase of this file. Good luck." )];
		}
	}
	// show sheet
	[passphraseSheetPassphraseTextField setStringValue:@""];
	[NSApp beginSheet:passphraseSheet modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndAskForPassphrase:returnCode:contextInfo:) contextInfo:NULL];
}


//
// user cancelled the passphrase sheet
//
- (IBAction)cancelPassphraseSheet:(id)sender
{
	[NSApp endSheet:passphraseSheet returnCode:1];
}

//
// User pressed the decrypt button on the passphrase sheet
//
- (IBAction)OKPassphraseSheet:(id)sender
{
	[NSApp endSheet:passphraseSheet returnCode:0];
}


//
// called when the passphrase sheet has finished.
//
- (void) didEndAskForPassphrase:(NSWindow *) sheet returnCode: (NSInteger) returnCode contextInfo:(void*) infos
{
	NSDictionary * dict = nil;
	NSString * pwd = [passphraseSheetPassphraseTextField stringValue];

	[passphraseSheetPassphraseTextField setStringValue:@""];

	if (!returnCode) {
		// only set dictionary if user didn't cancel
		dict = [NSDictionary dictionaryWithObject:pwd forKey:GPGTaskStringItem];

		// also save the passphrase for re-saving in case we're doing symmetric encryption
		if ([[[self document] encryptionType] isEqualToString:SCSymmetricEncryptionKey]) {
			[[self document] setPassphrase:pwd];
		}
	}

	[sheet close];

	// notify GPGTask
	[[NSNotificationCenter defaultCenter] postNotificationName:GPGTaskBadPassphraseAnswerNotification object:self userInfo:dict];
}






#pragma mark OVERRIDING
- (void)awakeFromNib {
	NSTableColumn *tableColumn = nil;
	ImageAndTextCell *imageAndTextCell = nil;

	// Insert custom cell types into the table view, the standard one does text only
	tableColumn = [browser tableColumnWithIdentifier: COLUMNID_NAME];
	[browser setOutlineTableColumn:tableColumn];
	imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable: YES];
	[tableColumn setDataCell:imageAndTextCell];

	// Register to geet our custom type, strings, and filenames.... try dragging each into the view!
	[browser registerForDraggedTypes:SCBrowserAcceptDraggedTypes];

	// drag vertically as well
	[browser setVerticalMotionCanBeginDrag:YES];
//	[browser setAutosaveName:[document docID]];
//	[browser setAutosaveExpandedItems:YES];

	[NOTCENTER addObserver:self selector:@selector(openOutlineItem:) name:SCOpenOutlineItemNotification object:nil];

	
	// toolbar
	[self setupToolbar];

	//[self refreshBrowser:nil];
	
}



- (IBAction)showWindow:(id)sender
{
	NSSize	size =[browser frame].size;
	MyDocument * d = [self document];
	double	w = [d browserWidth];
	NSString * s = [d windowFrame];

	[self setCurrentData:[d treeData]];
	
	if (![s isEqual:@""]) {
		[[self window] setFrameFromString:s];
	}
	if (w != 0) {
		size.width = w;
		[[[splitView subviews] objectAtIndex:0] setFrameSize:size];
	}
//	[encryptionPopup selectItemAtIndex:[d encryptionTypeAsInt]];

	// filter drawer
	[filterShowFoldersCheckBox setIntegerValue:[d filterIncludeFolders]];
	[filterLabelsOnlyCheckBox setIntegerValue:[d filterSearchLabelsOnly]];
	if ([d filterDrawerIsOpen]) [filterDrawer open];
	
	[super showWindow:sender];

	//[browser noteNumberOfRowsChanged];	[browser display];
}



- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL act = [menuItem action];
	
	if (act == @selector(deleteItem:)) {
		// The delete selection item should be disabled if nothing is selected.
		return ([[self selectedNodes] count]>0);
	}
	else if (act == @selector(changeEncryptionType:)) {
		// one of the three encryption type items. We need to set their state as appropriate
		[menuItem setState:([menuItem tag] == [[self document] encryptionTypeAsInt])];
		return YES;
	}
	else if (act == @selector(showOptions:)) {
		return (![[[self document] encryptionType] isEqualToString:SCNoEncryptionKey]);
	}
	else if (act == @selector(toggleDrawer:)){
		if ([filterDrawer state] == NSDrawerClosedState) {
			[menuItem setTitle:NSLocalizedString(@"Show Filter Drawer", @"Show Filter Drawer")];
		}
		else {
			[menuItem setTitle:NSLocalizedString(@"Hide Filter Drawer", @"Hide Filter Drawer")];
		}
		return YES;
	}
	else if (act == @selector(export:)) {
		if ([[self selectedNodes] count]) {
			// there is a selection
			if ([currentFilter isEqualToString:@""]) {
				// no filter
				[menuItem setTitle:NSLocalizedString(@"Export Selection…", @"Export Selection…")];
			}
			else {
				[menuItem setTitle:NSLocalizedString(@"Export Filtered Selection…", @"Export Filtered Selection…")];
			}
		}
		else {
			// there is no selection so, simply export
			if ([currentFilter isEqualToString:@""]) {
				// no filter
				[menuItem setTitle:NSLocalizedString(@"Export…", @"Export…")];
			}
			else {
				[menuItem setTitle:NSLocalizedString(@"Export Filtered…", @"Export Filtered…")];
			}
		}
		return YES;
	}
	return YES;
}



#pragma mark WINDOW DELEGATE

// Notice window movement / resizing

- (void)windowDidMove:(NSNotification *)aNotification
{
	[[self document] setWindowFrame:[[self window] stringWithSavedFrame]];
}

- (void)windowDidResize:(NSNotification *)aNotification
{
	[[self document] setWindowFrame:[[self window] stringWithSavedFrame]];
}

/*
- (void)windowWillBeginSheet:(NSNotification *)aNotification
{
	[[self window] makeFirstResponder:browser];
}
*/

#pragma mark SPLIT VIEW DELEGATE

// notice changes in split view
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	[[self document] setBrowserWidth:[browser frame].size.width];
}

/*
 - (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	return NO;
}
*/

- (CGFloat)splitView:(NSSplitView *)sView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
{
	CGFloat f = [sView frame].size.width - 100;
	
	if (proposedPosition < 100 ) return 100;
	else if (proposedPosition > f) return f;
	else return proposedPosition; 
}


#pragma mark MORE NOTIFICATIONS
- (void) refreshBrowser:(NSNotification*) aNotification
{
	NSLog(@"refreshBrowser");
	if ([[aNotification userInfo] objectForKey:@"newData"] && [aNotification object] == [self document]) {
		// this happens when new data has been loaded
		[self setCurrentData:[[self document] treeData]];
	}
	[browser reloadData];
}


// for opening a folder in the outline view
- (void) openOutlineItem:(NSNotification*)aNotification
{
//	[browser expandItem:[aNotification object]];
//	[browser noteNumberOfRowsChanged];
}



#pragma mark TOOLBAR

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
	// Create a new toolbar instance, and attach it to our document window
	NSToolbar * tb = [[[NSToolbar alloc] initWithIdentifier:MyDocToolbarIdentifier] autorelease];
	
	// Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
	[tb setAllowsUserCustomization: YES];
	[tb setAutosavesConfiguration: YES];
//	[tb setDisplayMode: NSToolbarDisplayModeTextOnly];
	[tb setVisible:NO];
	
	// We are the delegate
	[tb setDelegate: self];

	// Attach the toolbar to the document window
	[[self window] setToolbar:tb];
}


- (NSToolbarItem*) toolbar: (NSToolbar*)toolbar itemForItemIdentifier:(NSString*) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
/* Required delegate method   Given an item identifier, self method returns an
	item. The toolbar will use self method to obtain toolbar items that can be
	displayed in the customization sheet, or in the toolbar itself
*/
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];

	if ([itemIdent isEqualToString:SaveDocToolbarItemIdentifier]) {
		// Set the text label to be displayed in the toolbar and customization palette
		[toolbarItem setLabel: NSLocalizedString(@"Save",@"Save")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Save",@"Save")];

		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties
		//[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Disk"]];

		// Tell the item what message to send when it is clicked
		[toolbarItem setTarget: [self document]];
		[toolbarItem setAction: @selector(saveDocument:)];
	}
	else if([itemIdent isEqualToString: NewItemToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"New Secret",@"New Secret")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"New Item",@"New Item")];

		[toolbarItem setImage: [NSImage imageNamed: @"NewItem"]];

		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(addItem:)];
	}
	else if([itemIdent isEqualToString: NewFolderToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"New Folder",@"New Folder")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"New Folder",@"New Folder")];

		[toolbarItem setImage: [NSImage imageNamed: @"NewFolder"]];

		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(addFolder:)];
	}
	else if([itemIdent isEqualToString: DeleteItemToolbarItemIdentifier]) {
		[toolbarItem setLabel: NSLocalizedString(@"Delete Item",@"Delete Item")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Delete Item",@"Delete Item")];

		[toolbarItem setImage: [NSImage imageNamed: @"Wastebasket"]];

		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(deleteItem:)];
	}
	else if ([itemIdent isEqualToString:EncryptionSettingsToolbarItemIdentifier]) {	
		NSMenuItem *menuRep;
		NSMenu *menu = [[[toolbarPopupMenu menu] copy] autorelease];

		// menu representation for hidden toolbaritem
		menuRep = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Encryption",@"Encryption") action:nil keyEquivalent:@""] autorelease];
		[menuRep setSubmenu:[[menu copy] autorelease]];
		[toolbarItem setMenuFormRepresentation:menuRep];

		[toolbarItem setLabel:NSLocalizedString(@"Encryption",@"Encryption")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Encryption",@"Encryption")];

		[toolbarItem setView:toolbarPopupMenu];
		[toolbarItem setMinSize:NSMakeSize([toolbarPopupMenu frame].size.width,26)];
		[toolbarItem setMaxSize:NSMakeSize([toolbarPopupMenu frame].size.width,26)];
    }
	else {
		 // itemIdent refered to a toolbar item that is not provide or supported by us or cocoa. Returning nil will inform the toolbar self kind of item is not supported
		 toolbarItem = nil;
    }
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
	// Required delegate method   Returns the ordered list of items to be shown in the toolbar by default. If during the toolbar's initialization, no overriding values are found in the user defaults, or if the user chooses to revert to the default items self set will be used
	
	return [NSArray arrayWithObjects:	SaveDocToolbarItemIdentifier,  NSToolbarSeparatorItemIdentifier, NewItemToolbarItemIdentifier, NewFolderToolbarItemIdentifier, DeleteItemToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, EncryptionSettingsToolbarItemIdentifier,
		nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	// Required delegate method   Returns the list of all allowed items by identifier   By default, the toolbar
 // does not assume any items are allowed, even the separator   So, every allowed item must be explicitly listed
 // The set of allowed items is used to construct the customization palette
	return [NSArray arrayWithObjects:  SaveDocToolbarItemIdentifier, NewItemToolbarItemIdentifier, NewFolderToolbarItemIdentifier, DeleteItemToolbarItemIdentifier,	NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, EncryptionSettingsToolbarItemIdentifier, nil];
}

/*
- (void) toolbarWillAddItem: (NSNotification *) notif {
	// Optional delegate method   Before an new item is added to the toolbar, self notification is posted. self is the best place to notice a new item is going into the toolbar .  For instance, if you need to cache a reference to the toolbar item or need to set up some initial state, self is the best placeto do it.    The notification object is the toolbar to which the item is being added.   The item being added is found by referencing the @"item" key in the userInfo
	NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
	if([[addedItem itemIdentifier] isEqual: SearchDocToolbarItemIdentifier]) {
		activeSearchItem = [addedItem retain];
		[activeSearchItem setTarget: self];
		[activeSearchItem setAction: @selector(searchUsingToolbarTextField:)];
	} else if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
		[addedItem setToolTip: @"Print Your Document"];
		[addedItem setTarget: self];
	}
}
*/


/*
- (void) toolbarDidRemoveItem: (NSNotification *) notif {
	// Optional delegate method   After an item is removed from a toolbar the notification is sent   self allows the chance to tear down information related to the item that may have been cached   The notification object is the toolbar to which the item is being added   The item being added is found by referencing the @"item" key in the userInfo
	
	NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	if (removedItem==activeSearchItem) {
		[activeSearchItem autorelease];
		activeSearchItem = nil;
	}
}
*/

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
	// Optional method   self message is sent to us since we are the target of some toolbar item actions (for example:  of the save items action)

	if ([[toolbarItem itemIdentifier] isEqualToString:SaveDocToolbarItemIdentifier]) {
		// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving
		debugLog(@"validate Save ToolbarItem");
		return [[self document] isDocumentEdited];
	}
	else if ([[toolbarItem itemIdentifier] isEqualToString:DeleteItemToolbarItemIdentifier]){
		return ([[self selectedNodes] count]>0 && [currentFilter isEqualToString:@""]);
	}
	else if ([[toolbarItem itemIdentifier] isEqualToString:NewFolderToolbarItemIdentifier] || [[toolbarItem itemIdentifier] isEqualToString:NewItemToolbarItemIdentifier]) {
		return [currentFilter isEqualToString:@""];
	}
/*	else if ([[toolbarItem itemIdentifier] isEqualToString:EncryptionSettingsToolbarItemIdentifier]) {
		return (!([[self document] encryptionTypeAsInt] == SCNoEncryption));
	}*/
	return YES;
}




#pragma mark OTHER
- (NSArray*)draggedNodes   { return draggedNodes; }
- (NSArray *)selectedNodes { return [browser allSelectedItems]; }

- (NSString*) previousEncryptionType { return previousEncryptionType;}
- (void) setPreviousEncryptionType:(NSString*) type
{
	NSString * oldType = previousEncryptionType;
	previousEncryptionType = [type retain];
	[oldType release];
}

- (void) setCurrentData:(SimpleTreeNode*) node
{
	SimpleTreeNode * oldNode = currentData;
	currentData = [node retain];		
	[oldNode release];
}
- (SimpleTreeNode*) currentData {return currentData;}

- (void) touch
{
	if (![[self document] isDocumentEdited]) {
		[[[self window] toolbar] validateVisibleItems];
	}
	[[self document] updateChangeCount:NSChangeDone];
}

- (void) switchResponders
{
	NSResponder * old = [[self window] firstResponder];
	[[self window] makeFirstResponder:browser];
	[[self window] makeFirstResponder:textField];
	[[self window] makeFirstResponder:old];
}


#pragma mark HOUSEKEEPING


- (id)init
{
	//self = [super initWithWindow:window];
	self = [super initWithWindowNibName:@"MyDocument"];
	[self changeFilterTo:@""];
	previousEncryptionType = [@"" retain];
	[NOTCENTER addObserver:self selector:@selector(refreshBrowser:) name:SCRefreshBrowserNotification object:nil];
	return self;
}

- (void) dealloc
{
	[currentData release];
	[currentFilter release];
	[previousEncryptionType release];
	[super dealloc];
}

@end
