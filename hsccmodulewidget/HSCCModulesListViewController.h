#import <HSWidgets/HSWidgets-structs.h>
#import <HSWidgets/HSWidgetAdditionalOptionsViewController.h>

@class CCUISettingsModulesController;

@interface HSCCModulesListViewController : HSWidgetAdditionalOptionsViewController {
	NSMutableArray *_moduleInfos;
	CCUISettingsModulesController *_settingsModulesController;
	NSDictionary *_prefsModuleInfo;
}
@end