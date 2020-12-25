@class CCSModuleMetadata;

@interface CCSModuleRepository : NSObject // iOS 11 - 13
@property (nonatomic, copy, readonly) NSSet *loadableModuleIdentifiers; // iOS 11 - 13
-(void)_updateAllModuleMetadata; // iOS 11 - 13
-(void)_updateAvailableModuleMetadata; // iOS 11 - 13
-(CCSModuleMetadata *)moduleMetadataForModuleIdentifier:(NSString *)identifier; // iOS 11 - 13
@end
