@class SBWidgetController;

@interface SpringBoard : UIApplication
+(instancetype)sharedApplication;
-(SBWidgetController *)widgetController; // iOS 10 - 13
@end