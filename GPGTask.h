//
//  GPGTask.h
//  GPG Checker
//
//  Created by Sven-S. Porst on Sat Dec 29 2001.
//  Copyright (c) 2001 earthlingsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "debug.h"

// @protocol GPGTaskController;

// Constants for Notifications
#define GPGTaskBadPassphraseNotification @"GPGTBPN"
#define GPGTaskBadPassphraseAnswerNotification @"GPGTBPAN"
#define GPGTaskTrustUnsignedNotification @"GPGTTUN"
#define GPGTaskTrustUnsignedAnswerNotification @"GPGTTUAN"
#define GPGTaskNewStatusNotification @"GPGTNSN"
#define GPGTaskFinishedNotification @"GPGTFN"
#define GPGTaskGoodSignatureNotification @"GPGTGSN"
#define GPGTaskBadSignatureNotification @"GPGTBSN"
#define GPGTaskDecryptionOKNotification @"GPGTDOKN"

// Keys for dictionaries
#define GPGTaskKeyID @"KeyID"
#define GPGTaskBOOLItem @"BOOL"
#define GPGTaskStringItem @"NSString"
#define GPGTaskResult @"GPGTaskResult"

// and for prefs
#define GPGPathDefault @"path to gpg application"
#define GPGUsesOwnOptionsKey @"don't use --no-options"


@interface GPGTask : NSObject {

	// Pipes and Task
	NSPipe	* resultPipe;
	NSPipe	* commandPipe;
	NSPipe	* statusPipe;
	NSTask	* myTask;

	NSMutableArray	* optionsArray;

	id			myController;
	
	// user Data
	id			userMessage;
	NSString * userPassphrase;
	NSData 	* userResult;
	NSString	* signKeyIDString;
	NSArray	* recipientKeyIDArray;

	// Buffers and short term memory
	NSMutableString	* statusBuffer;
	NSString				* temporaryKeyID;

	// status Flags
	BOOL		isRunning;
	BOOL		noMoreOutput;

	BOOL		doesEncrypt;
	BOOL 		doesSign;
	BOOL		doesDecrypt;
	BOOL		doesVerify;
	
	BOOL		doesList;
	BOOL		doesListWithColons;
	BOOL 		doesListPrivateKeys;

	BOOL		hadBadPassphrase;
	

	BOOL		questionNotificationsWillBeAnswered;
}


- (BOOL) questionNotificationsWillBeAnswered;
- (void) setQuestionNotificationsWillBeAnswered:(BOOL) b;

- (NSString *) temporaryKeyID;
- (void) setTemporaryKeyID:(NSString *) s;

- (void) cancelProcess;
- (void) stopProcess:(BOOL)success;
- (void) startProcess;

- (void) newData: (NSNotification*) aNotification;
- (void) encryptionTaskFinished:(NSNotification *) aNotification;
- (void) unsignedKeyAnswer: (NSNotification *) aNotification;
- (void) badPassphraseAnswer: (NSNotification *) aNotification;

- (void) processGPGOutput: (NSString *)output;
- (id) doGPG_NODATA: (NSArray *) components;
- (id) doGPG_NEED_PASSPHRASE: (NSArray *) components;
- (id) doGPG_GOOD_PASSPHRASE: (NSArray *) components;
- (id) doGPG_GET_HIDDEN: (NSArray *) components;
- (id) doGPG_GET_BOOL: (NSArray *) components;
- (id) doGPG_BAD_PASSPHRASE: (NSArray *)components;
- (id) doGPG_BEGIN_ENCRYPTION: (NSArray *) components;
- (id) doGPG_BEGIN_DECRYPTION: (NSArray *) components;
- (id) doGPG_DECRYPTION_OKAY: (NSArray *) components;

- (id) writeDataAndClosePipe;

- (void) setUserStatus:(NSString *)string;
- (NSString*) nextCommandInBuffer;
- (void) writeToCommandPipe:(NSString *) string;
- (void) sendNotification:(NSString *) name withUserInfo:(NSDictionary *) userInfo;
- (void) registerForNotification:(NSString *) name withSelector:(SEL) selector;
- (void) stopObservingNotification:(NSString *) name;
- (NSString*) gpgPath;


- (id) initForListingKeysPrivate:(BOOL) private withColons:(BOOL) colons onlyMainKeys:(BOOL) mainKeys;
- (void) keyDataReady:(NSNotification*) theNotification;

- (id) initWithController:(id) controller encryptingMessage: (NSObject *) message toRecipients: (NSArray *) recipientKeyIDs  signingWithKey:(NSString *) signKeyID usingPassphrase:(NSString *) passphrase useASCIIArmor:(BOOL) withArmor;
- (id) initForDecrypting:(id)message withPassphrase:(NSString *) passphrase forController:(id)controller;
- (id) init;
- (void) dealloc;
- (NSString *) description;

@end

//@protocol GPGTaskController
//- (void) GPGFinished:(GPGTask *) task withResult:(NSData *) result;
//- (BOOL) askUserForUntrustedKey;
//- (void) notifyUserOfBadPassphraseForKeyID:(NSString *) keyID;
//- (void) setGPGStatus:(NSString *) message;
//@end
