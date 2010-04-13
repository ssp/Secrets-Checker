//
//  MyDocument.h
//  Secrets Checker
//
//  Created by Sven-S. Porst on Thu Mar 14 2002.
//  Copyright (c) 2002-2010 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocWindowController.h"
#import "SimpleTreeNode.h"
#import "Data.h"
//#import "PrefsController.h"

#define SCNoEncryptionKey @"none"
#define SCSymmetricEncryptionKey @"symmetric"
#define SCPublicKeyEncryptionKey @"public key"

#define SCNoEncryption 0
#define SCSymmetricEncryption 1
#define SCPublicKeyEncryption 2

#define SCDataKey @"data"
#define SCWindowFrameKey @"window position"
#define SCBrowserWidthKey @"split view position"
#define SCEncryptionTypeKey @"encryption"

#define SCKeyIDKey @"public key ID"
#define SCUseCustomSymmetricCipherKey @"use custom symmetric cipher"
#define SCCustomSymmetricCipherKey @"custom symmetric cipher"
#define SCSymmetricPasswordHintKey @"password hint"

#define SCDocIDKey @"Document ID"

#define SCFilterDrawerIsOpenKey @"filter drawer is open"
#define SCFilterSearchLabelsOnlyKey @"filter: search labels only"
#define SCFilterIncludeFolders @"filter: include folders"

#define SCSecretsDocumentType @"Secrets"

@interface MyDocument : NSDocument
{
	SimpleTreeNode		*treeData;

	NSString				*encryptionType;
	NSString				*windowFrame;

	NSString				*keyID;
	BOOL					useCustomSymmetricCipher;
	NSString				*customSymmetricCipher;
	
	NSString				*passphrase;
	NSString				*passphraseHint;
	
	double				browserWidth;

	BOOL					filterDrawerIsOpen;
	BOOL					filterSearchLabelsOnly;
	BOOL					filterIncludeFolders;
}

- (SimpleTreeNode*) treeData;
- (void) setTreeData:(SimpleTreeNode*) node;

- (NSString*) encryptionType;
- (NSInteger) encryptionTypeAsInt;
- (void) setEncryptionType:(NSString*) type;
- (void) setEncryptionTypeByInt:(NSInteger) nr;

- (NSString*) keyID;
- (void) setKeyID:(NSString*) ID;

- (BOOL) useCustomSymmetricCipher;
- (void) setUseCustomSymmetricCipher:(BOOL) b;

- (NSString*) customSymmetricCipher;
- (void) setCustomSymmetricCipher:(NSString*) cipher;

- (BOOL) filterSearchLabelsOnly;
- (void) setFilterSearchLabelsOnly:(BOOL) b;

- (BOOL) filterIncludeFolders;
- (void) setFilterIncludeFolders:(BOOL) b;

- (BOOL) filterDrawerIsOpen;
- (void) setFilterDrawerIsOpen:(BOOL) b;

- (NSString*) windowFrame;
- (void) setWindowFrame:(NSString*) frame;

- (NSString*) passphrase;
- (void) setPassphrase:(NSString*) phrase;

- (NSString*) passphraseHint;
- (void) setPassphraseHint:(NSString*) phrase;

- (double) browserWidth;
- (void) setBrowserWidth:(double) width;

//- (NSString*) docID;
//- (void) setDocID:(NSString*) ID;

// loading and saving
- (void) treeDataFromFileItem:(id) item;

- (id) dataForSaving;
- (NSString *) dataWithPublicKeyEncryption;
- (NSString *) dataWithSymmetricEncryption;

- (BOOL) waitForString:(NSString*) string fromFileHandle:(NSFileHandle*) handle;


@end
