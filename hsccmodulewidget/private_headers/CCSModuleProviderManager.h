@interface CCSModuleProviderManager : NSObject // iOS 11 - 13
+(instancetype)sharedInstance; // iOS 11 - 13
-(id)listControllerForModuleIdentifier:(NSString *)identifier; // iOS 11 - 13
@end
