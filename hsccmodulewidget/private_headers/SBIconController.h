@interface SBFloatingDockViewController : UIViewController // iOS 13
@property (nonatomic, assign) CGFloat dockOffscreenProgress; // iOS 13
@end

@interface SBHIconManager : NSObject // iOS 13
@property (nonatomic, retain) SBFloatingDockViewController *floatingDockViewController; // iOS 13
@end

@interface SBIconController : UIViewController // iOS 3 - 13
@property (nonatomic, readonly) SBHIconManager *iconManager; // iOS 13
+(instancetype)sharedInstance; // iOS 3 - 13
-(UIInterfaceOrientation)orientation; // iOS 3 - 13
@end
