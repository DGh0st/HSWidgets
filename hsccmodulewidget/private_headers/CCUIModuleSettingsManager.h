struct CCUILayoutSize;
@class CCUIModuleSettings;

@interface CCUIModuleSettingsManager : NSObject // iOS 11 - 13
-(instancetype)init; // iOS 11 - 13
-(CCUIModuleSettings *)moduleSettingsForModuleIdentifier:(NSString *)identifier prototypeSize:(CCUILayoutSize)size; // iOS 11 - 13
-(void)_loadSettings; // iOS 11 - 13
@end
