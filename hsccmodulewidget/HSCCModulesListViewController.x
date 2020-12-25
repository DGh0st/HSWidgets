#import "HSCCModulesListViewController.h"
#import "HSCCModuleController.h"
#import "CCSModuleMetadata.h"
#import "CCSModuleProviderManager.h"
#import "CCSModuleRepository.h"
#import "CCUILayoutSize.h"
#import "CCUIModuleSettings.h"
#import "CCUISettingsModuleDescription.h"
#import "CCUISettingsModulesController.h"

#import <HSWidgets/HSWidgetResources.h>
#import <HSWidgets/HSWidgetSizeObject.h>
#import <Preferences/PSListController.h>

#define CC_SETTINGS_BUNDLE_PATH @"/System/Library/PreferenceBundles/ControlCenterSettings.bundle"
#define ADD_NAVIGATION_ITEM_TITLE @"Add"

static inline void AddButtonToListController(PSListController *listController, id target, SEL action) {
	// add button
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:ADD_NAVIGATION_ITEM_TITLE style:UIBarButtonItemStyleDone target:target action:action];
	listController.navigationItem.rightBarButtonItems = @[addButton];
	[addButton release];
}

static NSString *FixedDisplayName(NSString *displayName) {
	NSDictionary *displayNamesToFixedNames = @{
		@"MediaControlsAudioModule" : @"Volume",
		@"AudioModule" : @"Volume",
		@"ConnectivityModule" : @"Connectivity",
		@"DisplayModule" : @"Brightness",
		@"DoNotDisturbModule" : @"Do Not Disturb",
		@"MediaControlsModule" : @"Media Controls",
		@"OrientationLockModule" : @"Orientation Lock",

		@"com.apple.mediaremote.controlcenter.audio" : @"Volume",
		@"com.apple.donotdisturb.DoNotDisturbModule" : @"DoNotDisturb",
		@"com.apple.control-center.OrientationLockModule" : @"Orientation Lock",
		@"com.apple.control-center.MuteModule" : @"Mute",
		@"com.apple.control-center.DisplayModule" : @"Brightness",
		@"com.apple.mediaremote.controlcenter.nowplaying" : @"Media Controls",
		@"com.apple.control-center.ConnectivityModule" : @"Connectivity",
		@"com.apple.mediaremote.controlcenter.airplaymirroring" : @"Screen Mirroring"

	};
	return displayNamesToFixedNames[displayName] ?: displayName;
}

@implementation HSCCModulesListViewController
-(instancetype)initWithWidgetsOptionsToExclude:(NSArray *)optionsToExclude withDelegate:(id<HSWidgetAddNewAdditionalOptionsDelegate>)delegate availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	self = [super initWithWidgetsOptionsToExclude:optionsToExclude withDelegate:delegate availablePositions:positions];
	if (self != nil) {
		HSCCModuleController *moduleController = [HSCCModuleController sharedInstance];
		[moduleController loadCCSettingsBundleIfNeeded];
		NSSet *identifiers = [moduleController unusedModuleIdentifiers];
		
		_settingsModulesController = [[%c(CCUISettingsModulesController) alloc] init];
		[_settingsModulesController _repopulateModuleData];

		_moduleInfos = [[NSMutableArray alloc] initWithCapacity:identifiers.count];
		for (NSString *identifier in identifiers) {
			CCUIModuleSettings *settings = [moduleController moduleSettingForIdentifier:identifier];
			CCUILayoutSize portraitSize = [settings layoutSizeForInterfaceOrientation:UIInterfaceOrientationPortrait];
			CCUILayoutSize landscapeSize =[settings layoutSizeForInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
			HSWidgetSize widgetSize = HSWidgetSizeMake(MAX(portraitSize.height, landscapeSize.height), MAX(portraitSize.width, landscapeSize.width));
			if ([super containsSpaceForWidgetSize:widgetSize]) {
				[_moduleInfos addObject:@{
					@"identifier" : identifier,
					@"widgetSize" : [HSWidgetSizeObject objectWithWidgetSize:widgetSize]
				}];
			}
		}

		[_moduleInfos sortUsingComparator:^(NSDictionary *firstWidgetInfo, NSDictionary *secondWidgetInfo) {
			NSString *firstIdentifier = firstWidgetInfo[@"identifier"];
			NSString *secondIdentififer = secondWidgetInfo[@"identifier"];
			NSString *firstDisplayName = FixedDisplayName([[_settingsModulesController _descriptionForIdentifier:firstIdentifier] displayName] ?: firstIdentifier);
			NSString *secondDisplayName = FixedDisplayName([[_settingsModulesController _descriptionForIdentifier:secondIdentififer] displayName] ?: secondIdentififer);
			return [firstDisplayName localizedStandardCompare:secondDisplayName];
		}];

		_prefsModuleInfo = nil;
	}
	return self;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_moduleInfos count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *const ReusableCellIdentifier = @"HSCustomCCModuleCell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReusableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReusableCellIdentifier] autorelease];
	}

	NSDictionary *moduleInfo = [_moduleInfos objectAtIndex:indexPath.row];
	NSString *identifier = moduleInfo[@"identifier"];
	CCUISettingsModuleDescription *description = [_settingsModulesController _descriptionForIdentifier:identifier];
	cell.textLabel.text = FixedDisplayName([description displayName] ?: identifier);
	cell.imageView.image = [description iconImage] ?: [HSWidgetResources imageNamed:HSWidgetPlaceholderImageName];

	// if CCSupport module supports custom preferences
	if ([_settingsModulesController respondsToSelector:@selector(preferenceClassForModuleIdentifiers)] && [[_settingsModulesController preferenceClassForModuleIdentifiers] objectForKey:identifier] != nil) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
	}

	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *moduleInfo = [_moduleInfos objectAtIndex:indexPath.row];
	NSString *identifier = moduleInfo[@"identifier"];

	// TODO: the preference stuff may need a rewrite
	NSString *rootListControllerClassName = [_settingsModulesController respondsToSelector:@selector(preferenceClassForModuleIdentifiers)] ? [[_settingsModulesController preferenceClassForModuleIdentifiers] objectForKey:identifier] : nil;
	if (rootListControllerClassName != nil) {
		if ([rootListControllerClassName isEqualToString:@"CCSProvidedListController"]) {
			CCSModuleProviderManager *providerManager = [%c(CCSModuleProviderManager) sharedInstance];
			PSListController *listController = [providerManager listControllerForModuleIdentifier:identifier];
			[self.navigationController pushViewController:listController animated:YES];

			_prefsModuleInfo = moduleInfo;
			AddButtonToListController(listController, self, @selector(addWidgetFromPrefs));
		} else {
			CCSModuleRepository *moduleRepository = [_settingsModulesController valueForKey:@"_moduleRepository"];
			NSBundle* moduleBundle = [NSBundle bundleWithURL:[moduleRepository moduleMetadataForModuleIdentifier:identifier].moduleBundleURL];

			Class rootListControllerClass = NSClassFromString(rootListControllerClassName);

			if (!rootListControllerClass) {
				[moduleBundle load];
				rootListControllerClass = NSClassFromString(rootListControllerClassName);
			}

			if (rootListControllerClass) {
				PSListController *listController = [[rootListControllerClass alloc] init];
				[self.navigationController pushViewController:listController animated:YES];

				_prefsModuleInfo = moduleInfo;
				AddButtonToListController(listController, self, @selector(addWidgetFromPrefs));
				[listController release];
			}
		}
	} else {
		_prefsModuleInfo = nil;
		[self addWidgetWithModuleInfo:moduleInfo];
	}
}

-(void)addWidgetFromPrefs {
	[self addWidgetWithModuleInfo:_prefsModuleInfo];
}

-(void)addWidgetWithModuleInfo:(NSDictionary *)moduleInfo {
	self.widgetOptions[@"moduleIdentifier"] = moduleInfo[@"identifier"];
	self.requestWidgetSize = ((HSWidgetSizeObject *)moduleInfo[@"widgetSize"]).size;
	[self addWidget]; // this begins the dismiss animation so its better to do it at the end	
}

-(void)dealloc {
	_prefsModuleInfo = nil;

	[_moduleInfos release];
	_moduleInfos = nil;

	[_settingsModulesController release];
	_settingsModulesController = nil;

	[super dealloc];
}
@end