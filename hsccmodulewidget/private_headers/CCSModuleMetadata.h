@interface CCSModuleMetadata : NSObject // iOS 11 - 13
@property (nonatomic, copy, readonly) NSURL *moduleBundleURL;
@property (nonatomic, copy, readonly) NSString *moduleIdentifier;
@end
