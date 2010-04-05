//
//  GPGTask.m
//  GPG Checker
//
//  Created by Sven-S. Porst on Sat Dec 29 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "GPGTask.h"

@implementation GPGTask


#pragma mark RESPOND TO NOTIFICATIONS


//
// called by Notification when gpg is finished with encrypting; we register for this notification in doGPG_BEGIN_ENCRYPTION
//
- (void) encryptionTaskFinished:(NSNotification *) aNotification
{
	NSLog(@"GPG encryptionTaskFinished, Notification received");

	userResult = [[[resultPipe fileHandleForReading] readDataToEndOfFile] retain];
	if (noMoreOutput)	[self stopProcess:YES];
}




//
// Called when data has been returned from the gpg process.
// initially stolen from Moriarity's getData
//
- (void) newData: (NSNotification *) aNotification
{
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	// Send the data on to the controller; we can't just use +stringWithUTF8String: here because
	// [data bytes] is not necessarily a properly terminated string. -initWithData:encoding: on
	// the other hand checks -[data length]
	NSString * string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSString * command;
	
	// NSLog(@"newData");

	// If the length of the data is zero, then the task is basically over - there is nothing more to get from the handle so we may as well shut down.
	if ([data length]) {
		NSLog(@"<-- %@", string);
		[statusBuffer appendString:string];
		while (command = [self nextCommandInBuffer]) {
			NSLog(command);
			[self processGPGOutput:command];
		}
	}
	else {
		// We're finished here, no more output to be expected.
		noMoreOutput = YES;
		if (![myTask isRunning]) [self stopProcess:YES];
		//[self cancelProcess];
	}

	// if we're not waiting for the final output yet, we want to continue reading in the background. If we're waiting  for the final output we don't as this would steal the first bit of the data we want to read from the NSFileHandle in the when receiving the notification of the task having finished.
	//if (!isInBulkMode) {
		[[statusPipe fileHandleForReading] readInBackgroundAndNotifyForModes:nil];
//	}
}


//
// for receiving the notification sent by the 'controller' after the user has supplied an answer to the 'use unsigned keys?' question
//
- (void) unsignedKeyAnswer: (NSNotification *) aNotification
{
	BOOL	answer = NO;
	NSString * s = [[aNotification userInfo] objectForKey:GPGTaskBOOLItem];

	if (s) {
		answer = [s intValue];
	}

	// write out 
	if (answer) {
		// for YES write Y
		[self writeToCommandPipe:@"Y"];
	}
	else {
		// for NO write N
		[self writeToCommandPipe:@"N"];
	}

	// unregister from notification
	[self stopObservingNotification:GPGTaskTrustUnsignedAnswerNotification];
}


//
// for receiving the notifiation sent by the 'controller' after the user has supplied a passphrase upon request
//
- (void) badPassphraseAnswer: (NSNotification *) aNotification
{
	NSString * s;

	if ([aNotification userInfo]) {
		// there is userInfo, i.e. the User didn't cancel.
		s 	= [[aNotification userInfo] objectForKey:GPGTaskStringItem];

		if (s) {
			// we have a string, so write it out
			[self writeToCommandPipe:s];
		}
		else {
			// we don't have a string, so cancel
			[self cancelProcess];
		}
	}
	else {
		// there is no userInfo => the user cancelled, so do we
		[self cancelProcess];
	}
		
	// deregister from notification
	[self stopObservingNotification:GPGTaskBadPassphraseAnswerNotification];
}





# pragma mark PROCESSING OUTPUT

//
// process the output of the gpg --status-fd output and take the necessary action(s)
//
- (void) processGPGOutput:(NSString *) output
{
	// we may be receiving multiple lines: seperate them, getting rid of trailing newlines in the process
	NSArray			* lines = [output componentsSeparatedByString:@"\n"];
	// for iterating through these
	NSEnumerator	* lineEnumerator = [lines objectEnumerator];
	NSString 		* line;

	// needed later on
	NSArray			* components;
	SEL				mySelector;
	
	// loop through lines
//	while (!isInBulkMode && (line = [lineEnumerator nextObject])) {
	while (line = [lineEnumerator nextObject]) {
			
		// pseudo-sanity check: lines that contain less than [GNUPG:] can't be good.
		if ([line rangeOfString:@"[GNUPG:]" options:(NSLiteralSearch && NSAnchoredSearch)].location != NSNotFound ) {
			// the line is of form
	 		// [GNUPG:] keyword parameters (see Documentation/DETAILS)
	  		// All components are seperated by spaces, so split up...
			components = [line componentsSeparatedByString:@" "];
			// This array will contain at position 
			// 0   : [GNUPG:]
			// 1   : keyword
			// 2...: parameters or data

			// now construct selector name from keyword:
			mySelector = NSSelectorFromString([NSString stringWithFormat:@"doGPG_%@:",[components objectAtIndex:1]]);
			// Check whether we're prepared to see this message
			if ([self respondsToSelector:mySelector]) {
				// this is a known message so
				NSLog(@"keyword: %@",[components objectAtIndex:1]);
				if (![self performSelector:mySelector withObject:components]) {
					// no error
				}
				else {
					// error
					NSLog(@"Error in GPGTask processGPGOutput after executing %@", [components objectAtIndex:1]);
				}
			}
			else {
				// this is not a known message so log it and hope it wasn't important. Quite a few messages that don't need any action aren't implemented for the time being, so being logged needn't be a bad thing.
				NSLog(@"unknown message: %@",[components objectAtIndex:1]);
			} // end of if ([self respondsToSelector:mySelector])
		}
		else {
			NSLog(@"212");
		} // end of if (line starts with [GNUPG:])
	} // end of while loop
	
	//if (isInBulkMode) {
		// we exited the while loop because we're in bulk mode now. This means that we have to reassemble the remaining lines given by the enumerator to what they were initally and put them into the bulkModeBuffer
//		[bulkModeBuffer appendData:[[[lineEnumerator allObjects] componentsJoinedByString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];

	//}
}


# pragma mark REACTING TO MESSAGES FROM GPG


//
// NODATA  <what>
// No data has been found. Codes for what are:
//	1 - No armored data.
//	2 - Expected a packet but did not found one.
// 3 - Invalid packet found, this may indicate a non OpenPGP message.
//
- (id) doGPG_NODATA: (NSArray *) components
{
	// This is not good.
	// perhaps return error explanation later.
	return components;
}


//
// NEED_PASSPHRASE <long main keyid> <long keyid> <keytype> <keylength>
// Issued whenever a passphrase is needed.
// keytype is the numerical value of the public key algorithm
// or 0 if this is not applicable, keylength is the length
//	of the key or 0 if it is not known (this is currently always the case).
//
- (id) doGPG_NEED_PASSPHRASE: (NSArray *) components
{
	// Store ID of key whose passphrase is needed
	[self setTemporaryKeyID:[components objectAtIndex:2]];
	// the actual passphrase will be written or requested in response to the 'GET_HIDDEN passphrase.enter' keyword
	return nil;
} 


//
// This may be bad...
// when calling gpg for signing and encrypting, the BEGIN_ENCRYPTION message doesn't seem to be issued. But input is accepted after  the GOOD_PASSPHRASE message is issued. So if we're signing _and_ encrypting, redirect this call to BEGIN_ENCRYPTION
//
- (id) doGPG_GOOD_PASSPHRASE: (NSArray *) components
{
	[self setUserStatus:NSLocalizedString(@"Passphrase correct", @"Passphrase correct status messge")];
	hadBadPassphrase = NO;
	
	if (doesSign) {
		// if we're Signing, this is the time to input all the data to be encrypted and close StdIn. However we don't want to switch to bulkMode just yet... this will be done after seeing the BEGIN_ENCRYPTION message
		return [self writeDataAndClosePipe];
	}
	else {
		return nil;
	}
}



//
// BAD_PASSPHRASE <long keyid>
// The supplied passphrase was wrong or not given.  In the latter case
//	you may have seen a MISSING_PASSPHRASE.
//
- (id) doGPG_BAD_PASSPHRASE: (NSArray *)components
{
	
	NSLog(@"Bad gpg passphrase for key id %@", [components objectAtIndex:2]);

	// notify User if necessary
	[self setUserStatus:NSLocalizedString(@"Incorrect passphrase", @"Incorrect passphrase status message")];

	hadBadPassphrase = YES;
	return nil;

}


//
// asking for hidden information, eg for passphrase
//
- (id) doGPG_GET_HIDDEN: (NSArray *) components
{
	NSDictionary * myDict =nil;

	// asking for passphrase is
	// [GNUPG:] GET_HIDDEN passphrase.enter
	if ([[components objectAtIndex:2] isEqualToString:@"passphrase.enter"]){
		// This needs to be given the passphrase provided by the User
		if (!hadBadPassphrase && userPassphrase) {
			debugLog(@"GPGTask doGPG_GET_HIDDEN write original passphrase")
			[self writeToCommandPipe:userPassphrase];
		}
		else {
			// we've already used up the initial passphrase - so it must've been wrong if we're back here again => if appropriate, invoke dialogue asking for new passphrase
			if ([self questionNotificationsWillBeAnswered]){
				// somebody is listeing to our notifications, so send them - this depends on someone actually answering them - otherwise the app is stuck!
				[self registerForNotification:GPGTaskBadPassphraseAnswerNotification withSelector:@selector(badPassphraseAnswer:)];
				if (temporaryKeyID) {
					// do we have a keyID (public key case)
					myDict =  [NSDictionary dictionaryWithObject:temporaryKeyID forKey:GPGTaskKeyID];
				}
				[self sendNotification:GPGTaskBadPassphraseNotification withUserInfo:myDict];


				debugLog(@"GPGTask doGPG_GET_HIDDEN sent Notification for passphrase ")
			}
			else {
				// nobody is listening to us, so we better stop doing thigs now - the hard way
				[self cancelProcess];
			}
		}
	}
	// haven't seen any other cases yet.

	return nil;
}


//
// asking for a boolean variable.
//
- (id) doGPG_GET_BOOL: (NSArray *) components
{
	//BOOL answer = NO;


	// [GNUPG:] GET_BOOL untrusted_key.override
	// when trying to use an untrusted key
	if ([[components objectAtIndex:2] isEqualToString:@"untrusted_key.override"]) {
		// do we have a controller ? Otherwise don't override.
		//if (myController) {
			// we do, so make the Controller ask the User
			//answer = [myController askUserForUntrustedKey];
	//		}
		// set status message
		[self setUserStatus:NSLocalizedString(@"Encountered untrusted key",@"Encountered untrusted key status message") ];
		if ([self questionNotificationsWillBeAnswered]){
			// someone _is_ listening, so ask... and be ready to receive an answer
			[self registerForNotification:GPGTaskTrustUnsignedAnswerNotification withSelector:@selector(unsignedKeyAnswer:)];
			[self sendNotification:GPGTaskTrustUnsignedNotification withUserInfo:nil];
			// if we don't receive an answer, we're stuck...
		}
		else {
			// we don't expect anybody to listen, so don't tell them and go for 'no' by default
			[self writeToCommandPipe:@"N"];
		}

	}

	return nil;
}




//
// BEGIN_ENCRYPTION seems to be the crucial keyword.
// This is the time to provide the text to be encrypted and close the input pipe. The rest of the Output should be the encrypted message terminated by a line with the message END_ENCRYPTION
//
- (id) doGPG_BEGIN_ENCRYPTION: (NSArray *) components
{
	[self setUserStatus:NSLocalizedString(@"Beginning encryption",@"Beginning encryption status message")];
	
	if (doesEncrypt &! doesSign) {
		// if we're encryptting only, this is the time to write our message and close StdIn
		// [self switchToBulkMode];
		return [self writeDataAndClosePipe];
	}
	else if (doesEncrypt && doesSign) {
		// if we're encrypting and signing, we've already written the message at the GOOD_PASSPHRASE message and only need to catch this to start bulk mode.
		// [self switchToBulkMode];
		return nil;
	}
	// whatever ??! we shouldn't be here...
	return self;
}


//
// BEGIN_DECRYPTION seems to be the crucial keyword then decrypting. Time to close the input pipe so the task can finish and we can collect the output.
//
- (id) doGPG_BEGIN_DECRYPTION: (NSArray *) components
{
	[[commandPipe fileHandleForWriting] closeFile];
	return nil;
}


//
//  DECRYPTION_OKAY
// The decryption process succeeded.  This means, that either the correct secret key has been used or the correct passphrase for a conventional encrypted message was given.  The program itself may return an errorcode because it may not be possible to verify a signature for some reasons.
//
- (id) doGPG_DECRYPTION_OKAY: (NSArray *) components
{
	// tell everybody who's interested about our success
	[self sendNotification:GPGTaskDecryptionOKNotification withUserInfo:nil];
	return nil;
}



//
// GOODSIG indicates a good signature, syntax is:
// GOODSIG	<long keyid>  <username>
// The signature with the keyid is good. For each signature only one of the three codes GOODSIG, BADSIG or ERRSIG will be emitted and they may be used as a marker for a new signature.
//
- (id) doGPG_GOODSIG:(NSArray *) components
{
	// if we see a good signature, we tell everybody who's interested...
	NSDictionary 	* myDict = [NSDictionary dictionaryWithObjectsAndKeys:[components objectAtIndex:2], GPGTaskKeyID, [components objectAtIndex:3], GPGTaskStringItem, nil];
	
	[self sendNotification:GPGTaskGoodSignatureNotification withUserInfo:myDict];

	return nil;
}



//
// writes the data to the pipe and closes it
//
- (id) writeDataAndClosePipe
{
	//NSLog(@"doGPG_BEGIN_ENCRYPTION\r%@",[self description]);
	if ([userMessage isKindOfClass:[NSString class]]){
		//NSLog(@"write message to command pipe");
		[self writeToCommandPipe:userMessage];
	}
	// close pipe, ie send ^D
	[[commandPipe fileHandleForWriting] closeFile];
	// NSLog(@"File Closed");
	
	return nil;	
}



#pragma mark UTILITIES

//
// Utility call for writing to the command pipe
//
- (void) writeToCommandPipe:(NSString *) string
{
	NSFileHandle	* myFile = [commandPipe fileHandleForWriting];
	NSString 		* myString = [NSString stringWithFormat:@"%@\n",string];
	NSData			* myData = [myString dataUsingEncoding:NSUTF8StringEncoding];

	//Careful with this NSLog...
#ifdef debugbuild
	NSLog(@"--> %@", string);
#endif
	
	[myFile writeData:myData];
}



//
// display status text if Controller is available
//
- (void) setUserStatus:(NSString *)string
{
	NSDictionary * myDict = [NSDictionary dictionaryWithObject:string forKey:GPGTaskStringItem];
	// only do something if we have a controller
	//if (myController) {
		//[myController setGPGStatus:string];
	//}
#ifdef debug
	NSLog(@"changeStatus: %@", string);
#endif
	[self sendNotification:GPGTaskNewStatusNotification withUserInfo:myDict];
}


//
// Send notification with given name and user info
//
- (void) sendNotification:(NSString *) name withUserInfo:(NSDictionary *) userInfo
{
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

//
// register for receiving a specific notification from myController
//
- (void) registerForNotification:(NSString *) name withSelector: (SEL) selector
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:selector name:name object:myController];
}

//
// unregister from a specific notification
//
- (void) stopObservingNotification:(NSString *) name
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:name object:nil];
}



//
// go through command buffer, check whether there's a complete line, return and delete it
//
- (NSString*) nextCommandInBuffer
{
	//unsigned *	start;
	//unsigned *	end;
	NSString *	s;
	NSRange		r;
	int			a;

	a = [statusBuffer rangeOfString:@"\n" options:NSBackwardsSearch].location;
	
	if ( a != NSNotFound) {
		// we've got complete lines
		r = NSMakeRange(0,a+1);
		s = [statusBuffer substringWithRange:r];
		[statusBuffer deleteCharactersInRange:r];

		return s;
	}
	else {
		return nil;
	}
}


//
// store path to gpg
// Try to read gpgPath from UserDefaults, otherwise try /usr/local/bin/gpg
//
- (NSString*) gpgPath
{
	NSString *val = [[NSUserDefaults standardUserDefaults] stringForKey:GPGPathDefault];
	if (!val) {
		return @"/usr/local/bin/gpg";
	}
	else {
		return val;
	}
}



#pragma mark VARIABLES

// questionNotificationsWillBeAnswered
- (BOOL) questionNotificationsWillBeAnswered { return questionNotificationsWillBeAnswered;}
- (void) setQuestionNotificationsWillBeAnswered:(BOOL) b {questionNotificationsWillBeAnswered = b;}
// temporaryKeyID
- (NSString *) temporaryKeyID { return temporaryKeyID;}
- (void) setTemporaryKeyID:(NSString *) s {
	NSLog(@"GPGTask setTemporaryKeyID: %@",s);
	if (temporaryKeyID) { [temporaryKeyID release];}
	temporaryKeyID = [s retain];
}


#pragma mark FOR LISTING KEYS ONLY

//
// initialise for listing public keys
// this mode of operation is completely different and more simple than the others
//
- (id) initForListingKeysPrivate:(BOOL) private withColons:(BOOL) colons onlyMainKeys:(BOOL) mainKeys
{
	NSPipe				* outPipe = [[[NSPipe alloc] init] autorelease];
	NSMutableString	* gpgCommand = [NSMutableString stringWithString:[self gpgPath]];

	// initialise superxlass
	[super init];

	// remember parameters for later use
	doesList = YES;
	doesListWithColons = colons;
	doesListPrivateKeys = private;

	// set up things
	myTask = [[NSTask alloc] init];
	[myTask setStandardOutput: outPipe];
	[myTask setLaunchPath:@"/bin/tcsh"];

	// set up option
	if (private) {
		[gpgCommand appendString:@" --list-secret-keys"];
	}
	else {
		[gpgCommand appendString:@" --list-public-keys"];
	}

	if (colons) {
		[gpgCommand appendString:@" --with-colons"];
	}

	if (mainKeys) {
		// only use main keys, i.e. lines starting with pub or sec
		if (private) {
			[gpgCommand appendString:@" | grep ^sec"];
		}
		else {
			[gpgCommand appendString:@" | grep ^pub"];
		}
	}

	// set up
	[myTask setArguments:[NSArray arrayWithObjects:@"-c", gpgCommand,nil]];

	// we want to be notified once the task is finished
	[[NSNotificationCenter defaultCenter]
			addObserver:self
				selector:@selector(keyDataReady:)
					 name:NSTaskDidTerminateNotification
				  object:myTask];

	// there we go
	[myTask launch];
	

	return self;
}


//
// keyDataReady
// called by notification, once the task reading the gpg keys is finished
//
- (void) keyDataReady:(NSNotification*) theNotification
{
	NSDictionary * myDict;


	//now that we're notified, simply get all the Data collected in the StdOut pipe
	NSString*  output = [[[NSString alloc] initWithData:[[[myTask standardOutput] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
	
	// notify whoever is interested of result
	myDict = [NSDictionary dictionaryWithObjectsAndKeys:
		output, @"keys",
		[NSString stringWithFormat:@"%d",doesListPrivateKeys], @"keysArePrivate",
		[NSString stringWithFormat:@"%d",doesListWithColons], @"usingWithColons",nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"GPGKeysReady"	object:self	userInfo:myDict];

	[self autorelease];

}






#pragma mark INITIALISING / STARTING / STOPPING

//
// for kicking off the process
//
- (void) startProcess
{
	[myTask launch];
	// get notified of output
	[[NSNotificationCenter defaultCenter]
			addObserver:self
				  selector:@selector(newData:)
						  name:NSFileHandleReadCompletionNotification
					 object:[statusPipe fileHandleForReading]];

	[[statusPipe fileHandleForReading] readInBackgroundAndNotifyForModes:nil];

	isRunning = YES;
}


//
// will stop the gpg process, notify people of failure and commit suicide - all without crashing the app
//
- (void) cancelProcess
{
	debugLog(@"cancelProcess");
}




//
// If the task ends, there is no more data coming through the file handle even when the notification is sent, or the process object is released, then this method is called.
//
- (void) stopProcess:(BOOL) success
{
	NSLog(@"GPGTask stopProcess");
	// Make sure the task has actually stopped!
	if (isRunning) {
		if ([myTask isRunning]){
			// make sure the Task quits
			[myTask terminate];
		}

		// stop being notified of new status messages
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:[statusPipe fileHandleForReading]];

		// if appropriate tell everybody about the result
		if (success) {
			// We operated successfully so there's something to return via a notification
			[[NSNotificationCenter defaultCenter] postNotificationName:GPGTaskFinishedNotification object:self userInfo:[NSDictionary dictionaryWithObject:[[userResult copy] autorelease] forKey:GPGTaskResult]];
		}
		else {
			// we didn't succeed, so don't notify
		}
			
		// ... and we won't do anything after this
		[self autorelease];
	}

	isRunning = NO;
	
}




// HORRIBLE TO BE REWRITTEN WITH PROPER VARIABLES ETC:
//
// initialise
// BIIIG Initialiser taking all kinds of options
// NSObject <GPGTaskController : in case we have a controller
// (id) message : the object to be ecrypted, NSString or a file (onle NSString works now)
// (NSArray *) recipientKeyIDs : it is assumed that this is an array of objects giving Key IDs for their 'description', for no Encryption pass nil
// (NSString *) signKeyID : An NSString containing the id of the Key used for signing, for no Signature pass nil
// (BOOL) withArmor : Do we want ASCII armor?
//
-(id) initWithController:(id)controller
		encryptingMessage: (NSObject *)message 
		toRecipients: (NSArray *) recipientKeyIDs 
		signingWithKey:(NSString *) signKeyID
		usingPassphrase:(NSString *) passphrase
		useASCIIArmor:(BOOL) withArmor
{
	NSEnumerator	* recipientKeyIDEnumerator;
	NSString			* recipientKeyID;

	// initialise self => does basic initialisation
	[self init];

	// evaluate parameters
	// store message and passphrase for later use
	userMessage = [message retain];
	userPassphrase = [passphrase retain];
	
	// if we have a controller, activate notifications, ie. controller _has_ to listen
	if (controller) {
		[self setQuestionNotificationsWillBeAnswered:YES];
		myController = controller;
	}


	// set arguments
		
		// do we want to encrypt ?
		if (recipientKeyIDs) {
			// we want to encrypt
			doesEncrypt = YES;
			[optionsArray addObject:@"--encrypt"];
			// set recipients
			recipientKeyIDArray = [recipientKeyIDs copy];
			recipientKeyIDEnumerator = [recipientKeyIDs objectEnumerator];
			while (recipientKeyID = [recipientKeyIDEnumerator nextObject]) {
				[optionsArray addObject: @"--recipient"];
				[optionsArray addObject: recipientKeyID];
			}
		}

		// do we want to sign the message ?
		if (signKeyID) {
			// we want to sign to the key specified
			doesSign = YES;
			signKeyIDString = [signKeyID copy];
			if (recipientKeyIDs) {
				// we are encrypting, so we just add --sign
				[optionsArray addObject: @"--sign"];
			}
			else {
				// we aren't encrypting, so we add the message in full
				[optionsArray addObject: @"--clearsign"];
			}
			// sign wrt the key passed
			[optionsArray addObject: @"--default-key"];
			[optionsArray addObject: signKeyID];
		}
			
		// Do we want ASCII Armor?
		if (withArmor) {
			[optionsArray addObject:@"--armor"];
		}
			
	// finally pass Options....
	[myTask setArguments:optionsArray];

	// make sure we're notified of task termination
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encryptionTaskFinished:) name:NSTaskDidTerminateNotification object:myTask];	

	//NSLog(@"GPGTask init finished: self retainCount: %d", [self retainCount]);
	return self;
}


/*
//
-(id) initWithController:(id)controller
			  encryptingMessage: (NSObject *)message
					   withCipher: (NSString *) cipher
				 usingPassphrase:(NSString *) passphrase
					useASCIIArmor:(BOOL) withArmor
{
	NSMutableArray * options = [NSMutableArray arrayWithCapacity:10];

	// initialise self => does basic initialisation
	[self init];

	[options addObjects:@"--symmetric", @"--command-fd", @"0", @"--charset", @"utf-8", @"--no-version", @"--no-comment", @"--armor", nil];

	if (![PREFS boolForKey:GPGUsesOwnOptionsKey]) {
		[options addObject:@"--no-options"];
	}

	if ([self useCustomSymmetricCipher]) {
		[options addObject:@"--cipher-algo"];
		[options addObject:[self customSymmetricCipher]];
	}

	[task setArguments:options];
	
	
	// evaluate parameters
	// store message and passphrase for later use
	userMessage = [message retain];
	userPassphrase = [passphrase retain];

	// if we have a controller, activate notifications, ie. controller _has_ to listen
	if (controller) {
		[self setQuestionNotificationsWillBeAnswered:YES];
		myController = controller;
	}


	// set arguments
	doesEncrypt = YES;
	[optionsArray addObject:@"--symmetric"];

	[optionsArray addObject:@"--cipher-algo"];
	[optionsArray addObject:cipher];

	// Do we want ASCII Armor?
	if (withArmor) {
		[optionsArray addObject:@"--armor"];
	}

	// finally pass Options....
	[myTask setArguments:optionsArray];

	// make sure we're notified of task termination
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encryptionTaskFinished:) name:NSTaskDidTerminateNotification object:myTask];

	//NSLog(@"GPGTask init finished: self retainCount: %d", [self retainCount]);
	return self;
}

*/



//
//
//
// initialise for decrypting a given message
//
- (id) initForDecrypting:(id)message withPassphrase:(NSString *) passphrase forController:(id)controller
{
	// do basic initialisation
	[self init];

	// evaluate parameters
	userMessage = [message retain];
	if (passphrase) {userPassphrase = [passphrase retain];}
	if (controller) {
		[self setQuestionNotificationsWillBeAnswered:YES];
		myController = controller;
	}

	// pass Options....
	[myTask setArguments:optionsArray];

	// start the proceedings...
	[self startProcess];
	[self writeToCommandPipe:message];
	
	// make sure we're notified of task termination
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encryptionTaskFinished:) name:NSTaskDidTerminateNotification object:myTask];

	return self;	
}


//
// basic initialiser, doing all the common work
//
- (id) init
{
	// initialise superclass
	[super init];

	// initialize output buffer
	statusBuffer = [[NSMutableString string] retain];

	// initialise NSTask
	myTask = [[NSTask alloc] init];

	// set up pipes
	resultPipe = [[NSPipe alloc] init];
	commandPipe = [[NSPipe alloc] init];
	statusPipe = [[NSPipe alloc] init];

	// and use for StdIn and StdOut
	[myTask setStandardOutput: resultPipe];
	[myTask setStandardInput: commandPipe];
	[myTask setStandardError: statusPipe];

	// begin setting up the optionsArray and set coomon arguments
	optionsArray = [[NSMutableArray arrayWithObjects:@"--command-fd",@"0",@"--status-fd", @"2", @"--no-tty", nil] retain];
	// for further commands to gpg
	//[optionsArray addObject:@"--command-fd"];
	//[optionsArray addObject:[NSString stringWithFormat:@"%d", 0]];
	// for further output from gpg
	//[optionsArray addObject:@"--status-fd"];
	//[optionsArray addObject:[NSString stringWithFormat:@"%d", 2]];

	// set path to gpg application
	[myTask setLaunchPath:[self gpgPath]];

	
	
	return self;
}



//
// deallocate
//
- (void) dealloc {
	debugLog(@"GPGTask dealloc start");

	// make sure the task has terminated...
	if (isRunning) {[self stopProcess:YES];}
	
	// unregister from Notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	// release passphrase and other data
	if (userPassphrase) {[userPassphrase release];}
	if (userMessage) {[userMessage release];}
	if (userResult) {[userResult release];}
	if (signKeyIDString) {[signKeyIDString release];}
	if (recipientKeyIDArray) {[recipientKeyIDArray release];}
	if (statusBuffer) {[statusBuffer release];}

	if (temporaryKeyID) {[temporaryKeyID release];}
	
	// release task & pipes
	if (myTask) {[myTask release];}
	
	// get rid of pipes
	if (resultPipe) {[resultPipe release];}
	if (commandPipe) {[commandPipe release];}
	if (statusPipe) {[statusPipe release];}
	if (optionsArray) {[optionsArray release];}
	
	// 
	[super dealloc];

	debugLog(@"GPGTask dealloc finished");
}



//
// description
//
- (NSString *) description {
	return [NSString stringWithFormat:@"GPGTask description\r(commandPipe: %@ (%d)\rresultPipe: %@ (%d)\rmyTask: %@ (%d)\ruserMessage: %@ (%d)\ruserResult length: %d (%d))",commandPipe,[commandPipe retainCount],resultPipe,[resultPipe retainCount],myTask,[myTask retainCount],userMessage,[userMessage retainCount],[userResult length],[userResult retainCount]];
}


@end
