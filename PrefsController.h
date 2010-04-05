/* PrefsController */

#import <Cocoa/Cocoa.h>
#import "GPGTask.h"
#import "Key.h"
#import "Data.h"
//#import "MyDocWindowController.h"


@interface PrefsController : NSWindowController
{
    IBOutlet id locationRadioButtons;
	 IBOutlet id locationEasyGPGRadioButton;
	 IBOutlet id locationFinkRadioButton;
	 IBOutlet id locationCustomRadioButton;
    IBOutlet id locationTextField;
    IBOutlet id privateKeyPopupMenu;
	 IBOutlet id showIconsCheckbox;
}

/*
- (IBAction)Apply:(id)sender;
- (IBAction)cancel:(id)sender;
*/


- (IBAction)setGPGPath:(id)sender;
- (IBAction)changeCheckboxes:(id) sender;
- (IBAction)poupMenuChange:(id) sender;
- (IBAction)showIconsChange:(id)sender;

/*
- (void) prefsNotification:(NSNotification*) aNotification;
- (IBAction)runPrefs:(id)sender;
*/

- (void) dealloc;

@end
