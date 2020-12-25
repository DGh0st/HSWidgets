@interface CCUIContentModuleContainerView : UIView // iOS 11 - 13
@property (assign,nonatomic) BOOL ignoreFrameUpdates; // iOS 11 - 13
@property (nonatomic,readonly) UIView *containerView; // iOS 11 - 13
-(instancetype)initWithModuleIdentifier:(NSString *)identifier options:(NSUInteger)options; // iOS 11 - 13
@end