@class SBWidgetController;

@interface SpringBoard : UIApplication
+(instancetype)sharedApplication;
-(SBWidgetController *)widgetController; // iOS 10 - 13
-(BOOL)homeScreenSupportsRotation; // iOS 8 - 13
@end