#import <HSWidgets/HSWidgetPreferencesListController.h>

@interface HSTodayWidgetRootPreferencesViewController : HSWidgetPreferencesListController {
	PSSpecifier *_descriptorSpecifier;
	PSSpecifier *_pickerSpecifier;
	PSSpecifier *_widthSpecifier;
	PSSpecifier *_spacesRowSpecifier;
	PSSpecifier *_spacesColSpecifier;
}
@end