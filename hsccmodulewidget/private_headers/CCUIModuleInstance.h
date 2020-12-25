@protocol CCUIContentModule;
@class CCSModuleMetadata;

@interface CCUIModuleInstance : NSObject // iOS 11 - 13
@property (nonatomic, readonly) CCSModuleMetadata *metadata; // iOS 11 - 13
@property (nonatomic, readonly) id<CCUIContentModule> module; // iOS 11 - 13
@end
