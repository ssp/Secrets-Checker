//
//  Data.h
//  GPG Checker
//
//  Created by Sven-S. Porst on Thu Dec 27 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GPGTask.h"
//#import "PrefsController.h"


#define GPGMadeEasyPath @"/usr/local/bin/gpg"
#define GPGFinkPath @"/sw/bin/gpg"
#define GPGPathKey GPGPathDefault

#define SCEncryptToKey @"encrypt to key"
#define SCDisplayIcons @"use icons"
#define SCExportWithTabs @"export with tabs"

#define SCNewFolderName NSLocalizedString(@"New Folder", @"New Folder")
#define SCNewSecretName NSLocalizedString(@"New Secret", @"New Secret")
#define SCNoSelection 	NSLocalizedString(@"Nothing selected.", @"Nothing selected")
#define SCMultipleSelection NSLocalizedString(@"Multiple selection", @"Multiple selection")
#define SCNodeSelection NSLocalizedString(@"Folder selected",@"Folder selected")

#define SCRefreshBrowserNotification @"SCBrowserRefresh"
#define SCErrorMessageNotification @"SCErrorMessage"

#define SCCouldntImportKey @"SCCouldntImport"


// 256 KB 
#define SCMaxImportFileSize 262144 

#define PREFS [NSUserDefaults standardUserDefaults]
#define NOTCENTER [NSNotificationCenter defaultCenter]




// some string constants for the Preference Keys
// Class containing the global Data for the Application
@interface Data : NSObject {
	NSArray * 	privateKeys;
	NSArray * 	cipherAlgorithms;

	NSImage *	documentMiniIcon;
	NSImage *	folderMiniIcon;
}

- (NSArray*) privateKeys;
- (void) setPrivateKeys:(NSArray*) keys;

- (NSArray*) cipherAlgorithms;
- (void) setCipherAlgorithms:(NSArray*) algorithms;

- (NSImage*) documentMiniIcon;
- (NSImage*) folderMiniIcon;

+ (Data *)Data;
- (Data *) init;
- (void) dealloc;
@end
