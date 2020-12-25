@class CCSModuleMetadata, CCUILayoutOptions, CCUIModuleInstance, CCUIModuleInstanceManager, CCUIModuleSettings, CCUIModuleSettingsManager, HSCCModuleWidgetViewController;

@interface HSCCModuleController : NSObject
@property (nonatomic, retain) CCUIModuleSettingsManager *settingsManager;
@property (nonatomic, retain) CCUIModuleInstanceManager *moduleInstanceManager;
@property (nonatomic, retain) CCUILayoutOptions *layoutOptions;
@property (nonatomic, retain) NSMutableDictionary<NSString *, CCUIModuleInstance *> *moduleInstanceByIdentifiers;
@property (nonatomic, retain) NSMutableDictionary<NSString *, CCUIModuleInstance *> *dynamicSizedModuleInstanceByIdentifiers;
@property (nonatomic, retain) NSBundle *ccSettingsBundle;
@property (nonatomic, retain) HSCCModuleWidgetViewController *expandedModuleViewController;
+(instancetype)sharedInstance;
-(NSSet *)unusedModuleIdentifiers;
-(CCUIModuleSettings *)moduleSettingForIdentifier:(NSString *)identifier;
-(CCSModuleMetadata *)moduleMetadataForIdentifier:(NSString *)identifier;
-(CCUIModuleInstance *)moduleInstanceForIdentifier:(NSString *)identifier;
-(void)removeModuleInstanceForIdentifier:(NSString *)identifier;
-(void)loadCCSettingsBundleIfNeeded;
-(void)unloadSettingsBundle;
@end
