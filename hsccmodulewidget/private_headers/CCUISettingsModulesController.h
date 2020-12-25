#import <Preferences/PSViewController.h>

@class CCUISettingsModuleDescription;

@interface CCUISettingsModulesController : PSViewController // iOS 11 - 13
-(NSDictionary *)preferenceClassForModuleIdentifiers; // added by CCSupport
-(void)_repopulateModuleData; // iOS 11 - 13
-(CCUISettingsModuleDescription *)_descriptionForIdentifier:(NSString*)identifier; // iOS 11 - 13
@end
