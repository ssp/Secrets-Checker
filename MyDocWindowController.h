//
//  MyDocWindowConotroller.h
//  Secrets Checker
//
//  Created by Sven-S. Porst on Fri Mar 15 2002.
//  Copyright (c) 2001 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ImageAndTextCell.h"
#import "NSArray_Extensions.h"
#import "NSOutlineView_Extensions.h"
#import "MyDocument.h"
#import "SimpleTreeNode.h"
#import "Data.h"

// TOOLBAR
#define 	MyDocToolbarIdentifier  @"Secrets Checker Toolbar"
#define  SaveDocToolbarItemIdentifier  @"Save Document ToolbarItem"
#define  NewItemToolbarItemIdentifier  @"New Item ToolbarItem"
#define  NewFolderToolbarItemIdentifier  @"New Folder ToolbarItem"
#define  DeleteItemToolbarItemIdentifier  @"Delete ToolbarItem"
#define	EncryptionSettingsToolbarItemIdentifier @"Encryption Settings ToolbarItem"

#define SCOpenOutlineItemNotification @"SCOOIN"

#define SCBrowserAcceptDraggedTypes [NSArray arrayWithObjects:DragDropSimplePboardType, NSStringPboardType, NSFilenamesPboardType, nil]


//
#define COLUMNID_NAME		 	@"NameColumn"
#define DragDropSimplePboardType 	@"SCCustomDDPboardType"


// Conveniences for accessing nodes, or the data in the node.
#define NODE(n)			((SimpleTreeNode*)n)
#define NODE_DATA(n) 	((SimpleNodeData*)[NODE((n)) nodeData])
#define SAFENODE(n) 		((SimpleTreeNode*)((n)?(n):(currentData)))


@interface MyDocWindowController : NSWindowController {
	IBOutlet	id			browser;
	IBOutlet id 		textField;
//	IBOutlet id			encryptionPopup;
	IBOutlet id			splitView;
//	IBOutlet id			optionsButton;

	// for the enter passphrase sheet
	IBOutlet id passphraseSheet;
	IBOutlet id passphraseSheetInfoTextField;
	IBOutlet id passphraseSheetPassphraseTextField;

	// for public key settings
	IBOutlet id publicKeySettingsSheet;
	IBOutlet id privateKeyPopup;
	IBOutlet id	publicKeyOKButton;

	// for symmetric settings
	IBOutlet id symmetricSettingsSheet;
	IBOutlet id symmetricPasswordField;
	IBOutlet id symmetricRePasswordField;
	IBOutlet id symmetricHintField;
	IBOutlet id algorithmMatrix;
	IBOutlet id algorithmPopup;
	IBOutlet id statusField;

	// for filter drawer
	IBOutlet id filterDrawer;
	IBOutlet id	filterField;
	IBOutlet id filterShowFoldersCheckBox;
	IBOutlet id filterLabelsOnlyCheckBox;

	// for import options
	IBOutlet id importOptionsSheet;
	IBOutlet id importOptionsFileName;
	IBOutlet id importOptionsFileIcon;
	IBOutlet id importOptionsImportSetting;
	IBOutlet id importOptionsEncodingSetting;

	//
	IBOutlet id exportAuxiliaryView;
	IBOutlet id	exportFormatPopup;

	// for toolbar
	IBOutlet id toolbarPopupMenu;
	
	SimpleNodeData*	currentItem;

	SimpleTreeNode* currentData;

	NSString* currentFilter;

	NSString*		previousEncryptionType;
	NSArray	 		*draggedNodes;
}



- (IBAction) addItem:(id) sender;
- (IBAction) addFolder:(id) sender;
- (IBAction) deleteItem:(id) sender;
- (IBAction) changeSelection:(id) sender;
//- (IBAction) changeText:(id) sender;
- (IBAction) changeEncryptionType:(id) sender;
- (IBAction) showOptions:(id) sender;

- (IBAction) toggleDrawer:(id) sender;
- (IBAction) switchDisplayFolders:(id) sender;
- (IBAction) switchLabelsOnly:(id) sender;
//- (IBAction) changeFilter:(id) sender;

- (void) showSymmetricOptions:(id) sender;
- (void) showPublicKeyOptions:(id) sender;

- (IBAction)changeSymmetricMatrix:(id)sender;
- (IBAction)OKSymmetricSettingsSheet:(id)sender;
- (IBAction)cancelSymmetricSettingsSheet:(id)sender;

- (IBAction)OKPublicKeySheet:(id) sender;
- (IBAction)cancelPublicKeySheet:(id) sender;

- (IBAction)cancelPassphraseSheet:(id)sender;
- (IBAction)OKPassphraseSheet:(id)sender;

- (IBAction)cancelImportSheet:(id)sender;
- (IBAction)OKImportSheet:(id)sender;


- (NSArray*)draggedNodes;
- (NSArray *)selectedNodes;

- (void) changeFilterTo:(NSString*) newFilter;

- (void)_addNewDataToSelection:(SimpleTreeNode *)newChild;
- (void)_performDropOperation:(id <NSDraggingInfo>)info onNode:(TreeNode*)parentNode atIndex:(int)childIndex;

- (NSString*) previousEncryptionType;
- (void) setPreviousEncryptionType:(NSString*) type;

- (void) refreshBrowser:(NSNotification*) aNotification;


//
- (void) setCurrentData:(SimpleTreeNode*) node;
- (SimpleTreeNode*) currentData;

// Toolbar stuff
- (void) setupToolbar;

- (void) touch;
- (void) switchResponders;

@end
