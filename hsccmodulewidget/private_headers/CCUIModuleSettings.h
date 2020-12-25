struct CCUILayoutSize;

@interface CCUIModuleSettings : NSObject // iOS 11 - 13
@property (nonatomic, assign) BOOL ccs_usesDynamicSize; // CCSupport 1.2.3
-(CCUILayoutSize)layoutSizeForInterfaceOrientation:(UIInterfaceOrientation)orientation; // iOS 11 - 13
@end