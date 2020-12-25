@class CCSModuleMetadata, CCUIModuleInstance;

@interface CCUIModuleInstanceManager : NSObject // iOS 11 - 13
+(instancetype)sharedInstance; // iOS 11 - 13
-(CCUIModuleInstance *)_instantiateModuleWithMetadata:(CCSModuleMetadata *)metadata; // iOS 11 - 13
-(NSArray<NSBundle *> *)_loadBundlesForModuleMetadata:(NSArray<CCSModuleMetadata *> *)arg1; // iOS 13
@end
