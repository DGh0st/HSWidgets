#import "HSCustomWidgetPreferencesViewController.h"

@implementation HSCustomWidgetPreferencesViewController
-(NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}
@end
