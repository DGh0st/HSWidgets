#import <HSWidgets/HSWidgetViewController.h>

@interface SBFLockscreenDateView : UIView // iOS 7 - 12
@end

@interface SBLockScreenDateViewController : UIViewController { // iOS 7 - 12
	BOOL _disablesUpdates; // iOS 7 - 12
}
-(id)initWithNibName:(id)arg1 bundle:(id)arg2; // iOS 7 - 12
-(void)_updateView; // iOS 7 - 12
-(UIView *)dateView; // iOS 7 - 12
@end

@interface HSClockWidgetViewController : HSWidgetViewController
@property (nonatomic, retain) SBLockScreenDateViewController *dateViewController;
@end