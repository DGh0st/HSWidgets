@class WGWidgetGroupViewController;

@interface SBIconController : UIViewController // iOS 3 - 13
+(instancetype)sharedInstance; // iOS 3 - 13
-(UIInterfaceOrientation)orientation; // iOS 3 - 13
-(CGSize)widgetGroupViewController:(WGWidgetGroupViewController *)groupViewController sizeForInterfaceOrientation:(UIInterfaceOrientation)orientation; // iOS 13
@end
