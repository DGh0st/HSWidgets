#import "HSWidgetAvailablePositionObject.h"
#import "HSWidgetPreferences.h"
#import "HSWidgetViewController.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface HSWidgetPreferencesListController : PSListController <HSWidgetPreferences>
@property (nonatomic, retain) HSWidgetViewController *widgetViewController;
@property (nonatomic, retain) NSArray<HSWidgetAvailablePositionObject *> *availablePositions;
-(void)resetAllSettings;
-(id)readPreferenceValue:(PSSpecifier *)specifier;
-(void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
-(void)resetWidgetOptions;
-(id)readWidgetOptionsValue:(PSSpecifier *)specifier;
-(void)setWidgetOptionsValue:(id)value specifier:(PSSpecifier *)specifier;
-(void)resetUserDefaults;
-(id)readUserDefaultsValue:(PSSpecifier *)specifier;
-(void)setUserDefaultsValue:(id)value specifier:(PSSpecifier *)specifier;
-(void)resetFileValues;
-(id)readFileValue:(PSSpecifier *)specifier;
-(void)setFileValue:(id)value specifier:(PSSpecifier *)specifier;
-(BOOL)containsSpaceForGridPositions:(NSArray<HSWidgetPositionObject *> *)positions;
-(BOOL)containsSpaceForWidgetSize:(HSWidgetSize)size;
@end