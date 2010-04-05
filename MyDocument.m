//
//  MyDocument.m
//  Secrets Checker
//
//  Created by Sven-S. Porst on Thu Mar 14 2002.
//  Copyright (c) 2002 earthlingsoft. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

#pragma mark DATA
- (SimpleTreeNode*) treeData { return treeData;}
- (void) setTreeData:(SimpleTreeNode*) node { [treeData release]; treeData = [node retain];}


- (NSString*) encryptionType { return encryptionType;}
- (void) setEncryptionType:(NSString*) type {[encryptionType release]; encryptionType = [type retain];}
- (NSInteger) encryptionTypeAsInt
{
	if ([encryptionType isEqual:SCSymmetricEncryptionKey]) {return SCSymmetricEncryption;}
	else if ([encryptionType isEqual:SCPublicKeyEncryptionKey]) {return SCPublicKeyEncryption;}
	else {return SCNoEncryption;}
}
- (void) setEncryptionTypeByInt:(NSInteger) nr
{
	switch (nr) {
		case SCSymmetricEncryption: [self setEncryptionType:SCSymmetricEncryptionKey]; break;
		case SCPublicKeyEncryption: [self setEncryptionType:SCPublicKeyEncryptionKey]; break;
		default: [self setEncryptionType:SCNoEncryptionKey];
			}
}


- (NSString*) keyID {return keyID;}
- (void) setKeyID:(NSString*) ID
{
	[keyID release];
	keyID = [ID retain];
}


- (BOOL) useCustomSymmetricCipher{return useCustomSymmetricCipher;}
- (void) setUseCustomSymmetricCipher:(BOOL) b{useCustomSymmetricCipher = b;}

- (NSString*) customSymmetricCipher{return customSymmetricCipher;}
- (void) setCustomSymmetricCipher:(NSString*) cipher
{
	[customSymmetricCipher release];
	if (cipher) customSymmetricCipher = [cipher retain];
	else customSymmetricCipher = [@"" retain];
}

- (BOOL) filterSearchLabelsOnly {return filterSearchLabelsOnly;}
- (void) setFilterSearchLabelsOnly:(BOOL) b {
	filterSearchLabelsOnly = b;}

- (BOOL) filterIncludeFolders {return filterIncludeFolders;}
- (void) setFilterIncludeFolders:(BOOL) b {
	filterIncludeFolders = b;}

- (BOOL) filterDrawerIsOpen { return filterDrawerIsOpen;}
- (void) setFilterDrawerIsOpen:(BOOL) b{
	filterDrawerIsOpen = b;}

- (NSString*) windowFrame { return windowFrame;}
- (void) setWindowFrame:(NSString*) frame { [windowFrame release]; windowFrame = [frame retain];}

- (NSString*) passphrase {return passphrase;}
- (void) setPassphrase:(NSString*) phrase
{
	[passphrase release];
	passphrase = [phrase retain];
}

- (NSString*) passphraseHint {return passphraseHint;}
- (void) setPassphraseHint:(NSString*) phrase
{
	[passphraseHint release];
	passphraseHint = [phrase retain];
}


- (double) browserWidth { return browserWidth;}
- (void) setBrowserWidth:(double) width {browserWidth = width;}

/*
- (NSString*) docID {return docID;}
- (void) setDocID:(NSString*) ID
{
	[docID release];
	docID = [ID retain];
}
*/

#pragma mark OVERRIDING
/*
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}
*/

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	[savePanel setCanSelectHiddenExtension:NO];
	
	return YES;
}


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	debugLog(@"[MyDocument windowControllerDidLoadNib]");
    [super windowControllerDidLoadNib:aController];
    // Add any code here that need to be executed once the windowController has loaded the document's window.
}


- (void)makeWindowControllers
{
	debugLog(@"[MyDocument makeWindowControllers]");
	if (![[self windowControllers] count]) {
		debugLog(@"making...");
		[self addWindowController:[[MyDocWindowController alloc] init]];
	}
}



/*
- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    // Insert code here to write your document from the given data.  You can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    return nil;
}
*/
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
	// Insert code here to read your document from the given data.  You can also choose to override -loadFileWrapperRepresentation:ofType: or -readFromFile:ofType: instead.
	NSString * s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSDictionary * myDict = [s propertyList];
	id					item;

	if (!myDict) return NO;

	// restore other saved values
	item = [myDict objectForKey:SCEncryptionTypeKey];
	if (!item) return NO;
	[self setEncryptionType:item];

//	if (item) [self setDocID:item];
//	item = [myDict objectForKey:SCDocIDKey];
	
	item = [myDict objectForKey:SCUseCustomSymmetricCipherKey];
	if (item) [self setUseCustomSymmetricCipher:[item boolValue]];

	item = [myDict objectForKey:SCSymmetricPasswordHintKey];
	if (item) [self setPassphraseHint:item];
	
	item = [myDict objectForKey:SCCustomSymmetricCipherKey];
	if (item) [self setCustomSymmetricCipher:item];

	item = [myDict objectForKey:SCKeyIDKey];
	if (item) [self setKeyID:item];
	
	// read data itself
	item = [myDict objectForKey:SCDataKey];
	if (!item) return NO;
	[self treeDataFromFileItem:item];
	// can't do this check as decryption has to be async...
	//	if (!treeData) return NO;

	item = [myDict objectForKey:SCFilterDrawerIsOpenKey];
	if (item) [self setFilterDrawerIsOpen:[item boolValue]];

	item = [myDict objectForKey:SCFilterSearchLabelsOnlyKey];
	if (item) [self setFilterSearchLabelsOnly:[item boolValue]];

	item = [myDict objectForKey:SCFilterIncludeFolders];
	if (item) [self setFilterIncludeFolders:[item boolValue]];

	item = [myDict objectForKey:SCWindowFrameKey];
	if (item) [self setWindowFrame:item];

	item = [myDict objectForKey:SCBrowserWidthKey];
	if (item) [self setBrowserWidth:[item doubleValue]];

	return YES;
}


- (void) treeDataFromFileItem:(id) item
{
	GPGTask 	*myTask;
	MyDocWindowController * wCon;
	
	if ([encryptionType isEqualToString:SCNoEncryptionKey]) {
		[self setTreeData:[[[SimpleTreeNode alloc] initWithArray:item] autorelease]];
		[NOTCENTER postNotificationName:SCRefreshBrowserNotification object:self];
	}
	else if([encryptionType isEqualToString:SCPublicKeyEncryptionKey] || [encryptionType isEqualToString:SCSymmetricEncryptionKey]) {

		[self makeWindowControllers];
		wCon = [[self windowControllers] objectAtIndex:0];

		myTask = [[GPGTask alloc] initForDecrypting:item withPassphrase:nil forController:wCon];

			// sign up for notification that is sent on completion of myTask
			[NOTCENTER addObserver:self selector:@selector(receiveDataFromGPGProcessing:) name:GPGTaskFinishedNotification object:myTask];

			// sign up for the other GPGTask related Notifications
			[NOTCENTER addObserver:wCon selector:@selector(askForPassphrase:) name:GPGTaskBadPassphraseNotification object:myTask];			
	} 
}


//
// called by the notification that is sent when the result is ready
//
- (void) receiveDataFromGPGProcessing:(NSNotification *)aNotification
{
	NSData *data = [[aNotification userInfo] objectForKey:GPGTaskResult];
	NSString * string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSArray* myArray = [string propertyList];

	[self setTreeData:[[[SimpleTreeNode alloc] initWithArray:myArray] autorelease]];

	[NOTCENTER postNotificationName:SCRefreshBrowserNotification object:self userInfo:[NSDictionary dictionaryWithObject:@"" forKey:@"newData"]];
}




#pragma mark OPENING AND SAVING


- (NSData *)dataRepresentationOfType:(NSString *)aType
{
	debugLog(@"[MyDocument dataRepresentationOfType]");
	return([super dataRepresentationOfType:aType]);
}


- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type
{
	NSMutableDictionary * myDict = [NSMutableDictionary dictionaryWithCapacity:11];
	NSString * encType = [self encryptionType];

	debugLog(@"[MyDocument writeToFile:ofType:]");

	// make sure the data is up-to-date
	[[[self windowControllers] objectAtIndex:0] switchResponders];


	// kind of encryption
	[myDict setObject:encType forKey:SCEncryptionTypeKey];
	if ([encType isEqualToString:SCSymmetricEncryptionKey]) {
		// for symmetic encryption
		[myDict setObject:[NSNumber numberWithBool:[self useCustomSymmetricCipher]] forKey:SCUseCustomSymmetricCipherKey];
		[myDict setObject:[self customSymmetricCipher] forKey:SCCustomSymmetricCipherKey];
		[myDict setObject:[self passphraseHint] forKey:SCSymmetricPasswordHintKey];
	}
	else if ([encType isEqualToString:SCPublicKeyEncryptionKey]) {
		// for public key encryption
		[myDict setObject:[self keyID] forKey:SCKeyIDKey];
	}	
			
	// window settings
	[myDict setObject:[self windowFrame] forKey:SCWindowFrameKey];
	if ([self browserWidth] != 0) {
		[myDict setObject:[NSNumber numberWithDouble:[self browserWidth]] forKey:SCBrowserWidthKey];
	}

	// filter drawer settings
	[myDict setObject:[NSNumber numberWithBool:[self filterDrawerIsOpen]] forKey:SCFilterDrawerIsOpenKey];
	[myDict setObject:[NSNumber numberWithBool:[self filterSearchLabelsOnly]] forKey:SCFilterSearchLabelsOnlyKey];
	[myDict setObject:[NSNumber numberWithBool:[self filterIncludeFolders]] forKey:SCFilterIncludeFolders];

	// DocID
//	[myDict setObject:[self docID] forKey:SCDocIDKey];
	
	// save data
	[myDict setObject:[self dataForSaving] forKey:SCDataKey];

	return [myDict writeToFile:fileName atomically:NO];	
}



- (id) dataForSaving
{
	if ([encryptionType isEqualToString:SCPublicKeyEncryptionKey]) {
		return [self dataWithPublicKeyEncryption];
	}
	else if ( [encryptionType isEqualToString:SCSymmetricEncryptionKey]){
		return [self dataWithSymmetricEncryption];
	}
	else /*([encryptionType isEqual:SCNoEncryptionKey])*/ {
		// just return array
		return [treeData arrayForTree];
	}
	
}




- (NSString *) dataWithPublicKeyEncryption
{
	NSTask			* task;
	NSPipe			* inPipe = [NSPipe pipe];
	NSPipe			* outPipe = [NSPipe pipe];
	NSFileHandle	* fHandle;
	NSString			* key = [self keyID];
	NSString			* path = [PREFS stringForKey:GPGPathDefault];

	NSString * result = nil;
	
	if (key && path) {
		task = [[NSTask alloc] init];
		[task setArguments:[NSArray arrayWithObjects:
		@"--no-options", @"--encrypt", @"--recipient", key, @"--armor", @"--batch", @"--yes", @"--charset", @"utf-8", @"--no-version", @"--no-comment", nil]];
		[task setStandardInput:inPipe];
		[task setStandardOutput:outPipe];
		[task setLaunchPath:path];
		
		[task launch];
		
		fHandle = [inPipe fileHandleForWriting];
		[fHandle writeData:[[[treeData arrayForTree] description] dataUsingEncoding:NSUTF8StringEncoding]];
		[fHandle closeFile];
		
		[task waitUntilExit];
		if ([task terminationStatus] == 0) {
			result = [[[NSString alloc] initWithData:[[outPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];			
		}
		[task release];
	}
	
	return result;	
}




- (NSString *) dataWithSymmetricEncryption {
	NSTask*			task = [[NSTask alloc] init];
	NSPipe*			inPipe = [NSPipe pipe];
	NSPipe* 			outPipe = [NSPipe pipe];
	NSPipe*			errPipe = [NSPipe pipe];
	NSFileHandle*	fHandle;
	NSString			* path = [PREFS stringForKey:GPGPathDefault];
	NSMutableArray	*options = [NSMutableArray arrayWithObjects:@"--symmetric",  @"--command-fd", @"0", @"--charset", @"utf-8", @"--no-version", @"--no-comment", @"--armor", @"--no-tty", nil];

	debugLog(@"[MyDocWindowController dataWithSymmetricEncryption]");
	
	if (![PREFS boolForKey:GPGUsesOwnOptionsKey]) {
		[options addObject:@"--no-options"];
	}

	if ([self useCustomSymmetricCipher]) {
		[options addObject:@"--cipher-algo"];
		[options addObject:[self customSymmetricCipher]];
	}

	[task setArguments:options];
	[task setLaunchPath:path];
	[task setStandardInput:inPipe];
	[task setStandardOutput:outPipe];
	[task setStandardError:errPipe];

	[task launch];
	fHandle = [inPipe fileHandleForWriting];

	[fHandle writeData:[[NSString stringWithFormat:@"%@\n",[self passphrase]] dataUsingEncoding:NSUTF8StringEncoding]];
	[fHandle writeData:[[[treeData arrayForTree] description] dataUsingEncoding:NSUTF8StringEncoding]];
	[fHandle closeFile];
	
	[task waitUntilExit];
	[task release];
	
	return [[[NSString alloc] initWithData:[[outPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
	
}



// Kick Cocoa to use proper file types/creators
- (NSDictionary *)fileAttributesToWriteToFile:(NSString *)fullDocumentPath ofType:(NSString *)documentTypeName saveOperation:(NSSaveOperationType)saveOperationType
{
	NSMutableDictionary *myDict= [NSMutableDictionary dictionaryWithDictionary:[super fileAttributesToWriteToFile:fullDocumentPath ofType:documentTypeName saveOperation:saveOperationType]];
	
	if ([documentTypeName isEqual:SCSecretsDocumentType]) {
		[myDict setObject:[NSNumber numberWithLong:'SecC'] forKey:NSFileHFSCreatorCode];
		[myDict setObject:[NSNumber numberWithLong:'SecS'] forKey:NSFileHFSTypeCode];
	}
	
	return myDict;
}



- (BOOL) waitForString:(NSString*) string fromFileHandle:(NSFileHandle*) handle
{
	NSMutableString*		s = [NSMutableString string];
	NSData*					d;

	while(s) {
		d = [handle availableData];
		if ([d length]) {
			[s appendString:[[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease]];

			if ([s rangeOfString:string options:NSLiteralSearch].length) {
				// length of the range is non-zero so we found it
				return YES;
			}
		}
		
	}
	return NO;
}




#pragma mark HOUSEKEEPING

- (id) init
{
	self = [super init];
	treeData = [[SimpleTreeNode alloc] initWithArray:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"To Secrets Checker",@"To Secrets Checker"), SCDataSecretKey, NSLocalizedString(@"Welcome",@"Welcome"), SCDataNameKey,nil]]];

	[self setFilterIncludeFolders:NO];
	[self setFilterSearchLabelsOnly:YES];
	[self setFilterDrawerIsOpen:NO];
	
	[self setEncryptionType:SCNoEncryptionKey];
	[self setWindowFrame:@""];
	[self setKeyID:@""];
	[self setCustomSymmetricCipher:@""];
	[self setPassphrase:@""];
	[self setPassphraseHint:@""];

//	[self setDocID:[[NSDate date] description]];
	
	return self;
}

- (void) dealloc
{
	[treeData release];

	[encryptionType release];
	[windowFrame release];
	[keyID release];
	[customSymmetricCipher release];
	[passphrase release];
	[passphraseHint release];
//	[docID release];
	
	[super dealloc];
}



@end
