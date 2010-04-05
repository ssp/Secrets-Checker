#import "PrefsController.h"

@implementation PrefsController

// called when checkbox is clicked
- (IBAction)showIconsChange:(id)sender
{
	[PREFS setBool:[sender intValue] forKey:SCDisplayIcons];
	[NOTCENTER postNotificationName:SCRefreshBrowserNotification object:self];
	[PREFS synchronize];
}


- (IBAction)changeCheckboxes:(id) sender
{
	switch ([[sender selectedCell] tag]) {
		case 0:	// (gpg made Easy)
			[locationTextField setEnabled:NO];
			[PREFS setObject:GPGMadeEasyPath forKey:GPGPathKey];
			[PREFS synchronize];
			break;
		case 1:  // (gpg Fink)
			[locationTextField setEnabled:NO];
			[PREFS setObject:GPGFinkPath forKey:GPGPathKey];
			[PREFS synchronize];
			break;
		case 2:	// (custom)
			[locationTextField setEnabled:YES];
			break;
		default:	break;
	}
				
}

// called when text in custom path box is changed
- (IBAction)setGPGPath:(id)sender
{
	if ([[locationRadioButtons selectedCell] tag] == 2){
		// made sure we're still on the correct radio button
		[PREFS setObject:[sender stringValue] forKey:GPGPathKey];
		[PREFS synchronize];
	}
}

- (IBAction)poupMenuChange:(id) sender
{
	[PREFS setObject:[[sender selectedItem] representedObject] forKey:SCEncryptToKey];
	[PREFS synchronize];
}


- (void) showWindow:(id) sender
{
	GPGTask * secKeyTask;
	NSString * path = [PREFS stringForKey:GPGPathKey];

	// set up 'show icons'
	[showIconsCheckbox setIntValue:[PREFS boolForKey:SCDisplayIcons]];
	
	// set up popup buttons
	if (path) {
		if ([path isEqual:GPGMadeEasyPath]) {
			[locationRadioButtons selectCellWithTag:0];
		}
		else if ([path isEqual:GPGFinkPath]) {
			[locationRadioButtons selectCellWithTag:1];
		}
		else {
			[locationRadioButtons selectCellWithTag:2];
			[locationTextField setStringValue:path];
			[locationTextField setEnabled:YES];
		}
	}

	// kick off gathering of secret keys
 	// ... and be notified once they're done
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keysAreReady:)
			name:@"GPGKeysReady"
				 object:nil];

	secKeyTask = [[GPGTask alloc] initForListingKeysPrivate:YES withColons:YES onlyMainKeys:NO];

	[super showWindow:sender];
}

//
// called by notification of GPGTask when Keys are ready
//
- (void) keysAreReady:(NSNotification*)aNotification
{
	NSDictionary 	* info = [aNotification userInfo];
	NSString			* keys = [info objectForKey:@"keys"];
	NSArray			* stringArray = [keys componentsSeparatedByString:@"\nsec:"];
	NSEnumerator	* myEnumerator = [stringArray objectEnumerator];
	NSString			* s;
	Key				* myKey;
	NSString			* prefID = [PREFS stringForKey:SCEncryptToKey];

	// the first two lines of the output are
	// /Users/ssp/.gnupg/secring.gpg

	NSLog([stringArray description]);

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	
	if ([[info objectForKey:@"usingWithColons"] intValue] && [[info objectForKey:@"keysArePrivate"] intValue] && [stringArray count]) {

		// empty Menu and activate the control
		[privateKeyPopupMenu setEnabled:YES];
		[privateKeyPopupMenu removeAllItems];

		
		// skip over the first entry as this is nothing but
  		// /Users/ssp/.gnupg/secring.gpg
	 	// -----------------------------
		[myEnumerator nextObject];
		

		while (s = [myEnumerator nextObject]){
			// ignore empty lines
			if ([s length] > 10 ) {
				myKey = [[Key alloc] initWithWithColonsString:s];
				if (myKey) {
					[privateKeyPopupMenu addItemWithTitle:[myKey longDescription]];
					[[privateKeyPopupMenu lastItem] setRepresentedObject:[myKey keyid]];
					if ([[myKey keyid] isEqual: prefID]) {
						[privateKeyPopupMenu selectItem:[privateKeyPopupMenu lastItem]];
					}
				}
			}
		}
	}
}


	/*
 could use this to check the path...
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
*/


/*
- (IBAction)runPrefs:(id)sender
{
	NSUserDefaults* pref = [NSUserDefaults standardUserDefaults];
	NSString* s;
	NSEnumerator* myKeyEnumerator;
	Key* defaultKey;
	Key* myKey;
	NSWindow *	parentWindow;
	
	// set all the correct values
	// for setting the path
	s = [pref stringForKey:GPGPathDefault];
	if ([s isEqual:GPGEasyGPGPath]) {
		[locationEasyGPGRadioButton setIntValue:1];
	}
	else if ([s isEqual:GPGFinkGPGPath]) {
		[locationFinkRadioButton setIntValue:1];
	}
	else {
		[locationCustomRadioButton setIntValue:1];
		[locationTextField setStringValue:s];
	}

	// for the keys
	// first fill the secret key popup button
	[privateKeyPopupMenu removeAllItems];
	myKeyEnumerator = [[[Data Data] privateKeys] objectEnumerator];

	while (myKey = [myKeyEnumerator nextObject]) {
		[privateKeyPopupMenu addItemWithTitle:[myKey longDescription]];
	}
		  
	// do we have any private keys ?
	if ([privateKeyPopupMenu numberOfItems]) {
		// yes there are private Keys
		// get the default Key (which will be non-nil)
		defaultKey = [[Data Data] getDefaultKey];
		// select it
		[privateKeyPopupMenu selectItemWithTitle:[defaultKey longDescription]];
	}
	else {
		// there are no private keys
		[privateKeyPopupMenu addItemWithTitle:NSLocalizedString(@"No secret keys available", @"No secret keys available")];
	}
	
	// ... and the checkboxes
	[alwaysAddMainKeyCheckBox setIntValue:[pref integerForKey:GPGAlwaysAddDefault]];
	[encryptToUntrustedCheckBox setIntValue:[pref integerForKey:GPGEncryptToUntrusted]];

	// just look at Object first..
	if ([sender isKindOfClass:[NSWindow class]]) {
		parentWindow = sender;
	}
	else if ([sender isKindOfClass:[NSView class]]) {
		parentWindow = [sender window];
	}
	else return;

	// start off the Sheet
	[NSApp beginSheet:myPanel modalForWindow:parentWindow modalDelegate:self didEndSelector:NULL contextInfo:NULL];
}
*/
/*
- (void) awakeFromNib
{
	[super awakeFromNib];
}
*/

-(void) dealloc
{
	[super dealloc];
}



@end
