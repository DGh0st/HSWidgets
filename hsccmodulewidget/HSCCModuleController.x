#import "HSCCModuleController.h"
#import "HSCCModuleWidgetViewController.h"
#import "CCSModuleMetadata.h"
#import "CCSModuleRepository.h"
#import "CCUILayoutSize.h"
#import "CCUIModularControlCenterViewController.h"
#import "CCUIModuleCollectionViewController.h"
#import "CCUIModuleInstance.h"
#import "CCUIModuleInstanceManager.h"
#import "CCUIModuleSettings.h"
#import "CCUIModuleSettingsManager.h"

#define CC_SETTINGS_BUNDLE_PATH @"/System/Library/PreferenceBundles/ControlCenterSettings.bundle"

static BOOL IsUnloadableBundle(NSString *identifier) {
	return ![identifier isEqualToString:@"com.apple.replaykit.controlcenter.screencapture"];
}

@implementation HSCCModuleController
+(instancetype)sharedInstance {
	static HSCCModuleController *_sharedController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedController = [[self alloc] init];
	});
	return _sharedController;
}

-(instancetype)init {
	self = [super init];
	if (self != nil) {
		self.settingsManager = [[%c(CCUIModuleSettingsManager) alloc] init];
		self.moduleInstanceManager = [%c(CCUIModuleInstanceManager) sharedInstance];
		self.layoutOptions = [[%c(CCUIModularControlCenterViewController) _sharedCollectionViewController] _currentLayoutOptions];
		self.moduleInstanceByIdentifiers = [NSMutableDictionary dictionary];
		self.dynamicSizedModuleInstanceByIdentifiers = [NSMutableDictionary dictionary];
		self.ccSettingsBundle = nil;
	}
	return self;
}

-(NSSet *)unusedModuleIdentifiers {
	CCSModuleRepository *_repository = [self.moduleInstanceManager valueForKey:@"_repository"];
	[_repository _updateAllModuleMetadata];
	NSMutableSet *unusedModuleIdentifiers = [NSMutableSet setWithSet:_repository.loadableModuleIdentifiers];
	for (NSString *identifier in self.moduleInstanceByIdentifiers) // go through all the keys
		[unusedModuleIdentifiers removeObject:identifier];
	return unusedModuleIdentifiers;
}

-(CCUIModuleSettings *)moduleSettingForIdentifier:(NSString *)identifier {
	CCUIModuleSettings *settings = nil;
	if (identifier != nil) {
		[self.settingsManager _loadSettings];
		settings = [self.settingsManager moduleSettingsForModuleIdentifier:identifier prototypeSize:CCUILayoutSizeMake(1, 1)];

		// CCSupport's dynamic sizing requires the bundles to be loaded for it to get the size
		if ([settings respondsToSelector:@selector(ccs_usesDynamicSize)] && settings.ccs_usesDynamicSize) {
			CCSModuleMetadata *metadata = [self moduleMetadataForIdentifier:identifier];

			// temporarily load bundle to get dynamic size from CCSupport
			[self loadModuleBundleForMetadata:metadata];
			self.dynamicSizedModuleInstanceByIdentifiers[identifier] = [self.moduleInstanceManager _instantiateModuleWithMetadata:metadata];

			settings = [self.settingsManager moduleSettingsForModuleIdentifier:identifier prototypeSize:CCUILayoutSizeMake(1, 1)];

			// unload the bundle that we loaded for CCSupport
			self.dynamicSizedModuleInstanceByIdentifiers[identifier] = nil;
			[self unloadModuleBundleForMetadata:metadata];
		}
	}
	return settings;
}

-(CCSModuleMetadata *)moduleMetadataForIdentifier:(NSString *)identifier {
	CCSModuleRepository *_repository = [self.moduleInstanceManager valueForKey:@"_repository"];
	[_repository _updateAllModuleMetadata];
	return [_repository moduleMetadataForModuleIdentifier:identifier];
}

-(CCUIModuleInstance *)moduleInstanceForIdentifier:(NSString *)identifier {
	if (self.moduleInstanceByIdentifiers[identifier] == nil) {
		// load the module bundle
		CCSModuleMetadata *metadata = [self moduleMetadataForIdentifier:identifier];
		[self loadModuleBundleForMetadata:metadata];

		CCUIModuleInstance *moduleInstance = [self.moduleInstanceManager _instantiateModuleWithMetadata:metadata];
		self.moduleInstanceByIdentifiers[identifier] = moduleInstance;
		return moduleInstance;
	} else {
		return self.moduleInstanceByIdentifiers[identifier];
	}
}

-(void)removeModuleInstanceForIdentifier:(NSString *)identifier {
	self.moduleInstanceByIdentifiers[identifier] = nil;

	// unload module bundle
	CCSModuleMetadata *metadata = [self moduleMetadataForIdentifier:identifier];
	[self unloadModuleBundleForMetadata:metadata];
}

-(void)loadModuleBundleForMetadata:(CCSModuleMetadata *)metadata {
	NSBundle *moduleBundle = [NSBundle bundleWithURL:metadata.moduleBundleURL];
	if (moduleBundle != nil) {
		NSError *error = nil;
		BOOL success = [moduleBundle loadAndReturnError:&error];

		if (!success && error != nil) {
			NSString *reason = [NSString stringWithFormat:@"HSCCModuleController failed to load %@ bundle for reason \"%@\"", metadata.moduleBundleURL, error.localizedDescription];
			@throw [NSException exceptionWithName:@"HSCCModuleUnableToLoadModuleBundleException" reason:reason userInfo:error.userInfo];
		}
	}
}

-(void)unloadModuleBundleForMetadata:(CCSModuleMetadata *)metadata {
	NSBundle *moduleBundle = [NSBundle bundleWithURL:metadata.moduleBundleURL];
	if (moduleBundle != nil && IsUnloadableBundle(metadata.moduleIdentifier)) {
		[moduleBundle unload];
	}
}

-(void)loadCCSettingsBundleIfNeeded {
	if (self.ccSettingsBundle == nil) {
		self.ccSettingsBundle = [NSBundle bundleWithPath:CC_SETTINGS_BUNDLE_PATH];
		[self.ccSettingsBundle load];
	}
}

-(void)unloadSettingsBundle {
	if (self.ccSettingsBundle != nil) {
		[self.ccSettingsBundle unload];
		self.ccSettingsBundle = nil;
	}
}

-(void)dealloc {
	[self.settingsManager release];
	self.settingsManager = nil;

	[self.moduleInstanceManager release];
	self.moduleInstanceManager = nil;

	self.layoutOptions = nil;
	self.moduleInstanceByIdentifiers = nil;
	self.dynamicSizedModuleInstanceByIdentifiers = nil;

	[self unloadSettingsBundle];

	[super dealloc];
}
@end
