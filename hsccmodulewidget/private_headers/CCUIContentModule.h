@protocol CCUIContentModule <NSObject> // iOS 11 - 13
@property (nonatomic, readonly) id contentViewController; // iOS 10 - 13
@property (nonatomic, readonly) id backgroundViewController; // iOS 10 - 13
@optional
-(void)setContentModuleContext:(id)context; // iOS 11 - 13
-(id)contentViewControllerForContext:(id)context; // iOS 13
-(id)backgroundViewControllerForContext:(id)context; // iOS 13
@required
-(id)contentViewController; // requierd on iOS 11 - 12, optional in 13
@end
