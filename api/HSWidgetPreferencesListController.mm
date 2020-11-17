#import "HSWidget-Availability.h"
#import "HSWidgetPreferencesListController.h"
#import "HSWidgetGridPositionConverterCache.h"
#import "NSUserDefaults.h"

#define PREFERENCES_PLIST_PATH_FORMAT @"/var/mobile/Library/Preferences/%@.plist"

@interface PSListController (Private)
-(id)controllerForSpecifier:(PSSpecifier *)specifier; // iOS 6 - 13
@end

static inline NSMutableArray *GetAvailableGridPositionsExcludingWidget(HSWidgetViewController *widgetViewController, NSArray<HSWidgetAvailablePositionObject *> *availablePositions) {
	NSMutableArray<HSWidgetAvailablePositionObject *> *availableGridPositions = [NSMutableArray arrayWithArray:availablePositions];
	for (HSWidgetPositionObject *position in widgetViewController._gridPositions) {
		[availableGridPositions addObject:[HSWidgetAvailablePositionObject objectWithAvailableWidgetPosition:position.position containingIcon:NO]];
	}
	return availableGridPositions;
}

@implementation HSWidgetPreferencesListController
-(instancetype)initWithWidgetViewController:(HSWidgetViewController *)widgetViewController availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	self = [super init];
	self.widgetViewController = widgetViewController;
	self.availablePositions = positions;
	return self;
}

-(UITableViewStyle)tableViewStyle {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
	return isAtLeastiOS13() ? UITableViewStyleInsetGrouped : [super tableViewStyle];
#pragma clang diagnostic pop
}

-(id)controllerForSpecifier:(PSSpecifier *)specifier {
	Class detailClass = [specifier detailControllerClass];
	if ([detailClass conformsToProtocol:@protocol(HSWidgetPreferences)]) {
		return [[[detailClass alloc] initWithWidgetViewController:self.widgetViewController availablePositions:self.availablePositions] autorelease];
	} else {
		return [super controllerForSpecifier:specifier];
	}
}

-(void)resetAllSettings {
	[self resetWidgetOptions];
}

-(id)readPreferenceValue:(PSSpecifier *)specifier {
	return [self readWidgetOptionsValue:specifier];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[self setWidgetOptionsValue:value specifier:specifier];
}

-(void)_postNotificationForSpecifierIfProvided:(PSSpecifier *)specifier {
	NSString *notificationName = specifier.properties[PSValueChangedNotificationKey];
	if (notificationName != nil) {
		// CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)notificationName, NULL, NULL, YES);
		[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:nil];
	}
}

-(void)resetWidgetOptions {
	for (PSSpecifier *specifier in [self specifiers]) {
		NSString *key = specifier.properties[PSKeyNameKey];
		if (key != nil) {
			[self.widgetViewController setWidgetOptionValue:nil forKey:key];
			[self _postNotificationForSpecifierIfProvided:specifier];
		}
	}

	[self reloadSpecifiers];
}

-(id)readWidgetOptionsValue:(PSSpecifier *)specifier {
	return ([self.widgetViewController options][specifier.properties[PSKeyNameKey]]) ?: specifier.properties[PSDefaultValueKey];	
}

-(void)setWidgetOptionsValue:(id)value specifier:(PSSpecifier *)specifier {
	NSString *key = specifier.properties[PSKeyNameKey];
	if (key != nil) {
		[self.widgetViewController setWidgetOptionValue:value forKey:key];
		[self _postNotificationForSpecifierIfProvided:specifier];
	}
}

-(void)resetUserDefaults {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	for (PSSpecifier *specifier in [self specifiers]) {
		NSString *key = specifier.properties[PSKeyNameKey];
		NSString *domainName = specifier.properties[PSDefaultsKey];
		if (key != nil && domainName != nil) {
			[standardUserDefaults setObject:nil forKey:key inDomain:domainName];
			[self _postNotificationForSpecifierIfProvided:specifier];
		}
	}
	
	[self reloadSpecifiers];
}

-(id)readUserDefaultsValue:(PSSpecifier *)specifier {
	id defaultValue = specifier.properties[PSDefaultValueKey];
	NSString *domainName = specifier.properties[PSDefaultsKey];
	if (domainName != nil) {
		return [[NSUserDefaults standardUserDefaults] objectForKey:specifier.properties[PSKeyNameKey] inDomain:domainName] ?: defaultValue;
	}

	return defaultValue;
}

-(void)setUserDefaultsValue:(id)value specifier:(PSSpecifier *)specifier {
	NSString *key = specifier.properties[PSKeyNameKey];
	NSString *domainName = specifier.properties[PSDefaultsKey];
	if (key != nil && domainName != nil) {
		[[NSUserDefaults standardUserDefaults] setObject:value forKey:key inDomain:domainName];
		[self _postNotificationForSpecifierIfProvided:specifier];
	}
}

-(void)resetFileValues {
	for (PSSpecifier *specifier in [self specifiers]) {
		NSString *key = specifier.properties[PSKeyNameKey];
		NSString *domainName = specifier.properties[PSDefaultsKey];
		if (key != nil && domainName != nil) {
			// this has awful performance but need to do open file separately for each specifier in order to support multiple defaults
			NSString *path = [NSString stringWithFormat:PREFERENCES_PLIST_PATH_FORMAT, domainName];
			NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
			[settings removeObjectForKey:key];
			[settings writeToFile:path atomically:YES];
		}

		[self _postNotificationForSpecifierIfProvided:specifier];
	}
	
	[self reloadSpecifiers];
}

-(id)readFileValue:(PSSpecifier *)specifier {
	id defaultValue = specifier.properties[PSDefaultValueKey];
	NSString *domainName = specifier.properties[PSDefaultsKey];
	if (domainName != nil) {
		NSString *path = [NSString stringWithFormat:PREFERENCES_PLIST_PATH_FORMAT, domainName];
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
		return settings[specifier.properties[PSKeyNameKey]] ?: defaultValue;
	}

	return defaultValue;
}

-(void)setFileValue:(id)value specifier:(PSSpecifier *)specifier {
	NSString *key = specifier.properties[PSKeyNameKey];
	NSString *domainName = specifier.properties[PSDefaultsKey];
	if (key != nil && domainName != nil) {
		NSString *path = [NSString stringWithFormat:PREFERENCES_PLIST_PATH_FORMAT, domainName];
		NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:path];
		[settings setObject:value forKey:key];
		[settings writeToFile:path atomically:YES];
	}

	[self _postNotificationForSpecifierIfProvided:specifier];
}

-(BOOL)containsSpaceForGridPositions:(NSArray<HSWidgetPositionObject *> *)positions {
	NSMutableArray *availableGridPositions = GetAvailableGridPositionsExcludingWidget(self.widgetViewController, self.availablePositions);
	return [HSWidgetGridPositionConverterCache canFitWidget:positions inGridPositions:availableGridPositions];
}

-(BOOL)containsSpaceForWidgetSize:(HSWidgetSize)size {
	NSMutableArray *availableGridPositions = GetAvailableGridPositionsExcludingWidget(self.widgetViewController, self.availablePositions);
	return [HSWidgetGridPositionConverterCache canFitWidgetOfSize:size inGridPositions:availableGridPositions];
}

-(void)dealloc {
	self.widgetViewController = nil;
	self.availablePositions = nil;

	[super dealloc];
}
@end