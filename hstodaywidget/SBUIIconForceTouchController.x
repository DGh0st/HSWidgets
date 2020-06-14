@interface SBUIIconForceTouchController // iOS 10 - 12
+(BOOL)_isPeekingOrShowing; // iOS 10 - 12
+(BOOL)_isWidgetVisible:(id)arg1; // iOS 10 - 12
@end

@interface SBIconListView // iOS 7 - 12
-(BOOL)containsWidget:(NSString *)identifier;
@end

@interface SBHIconManager : NSObject
-(BOOL)isScrolling; // iOS 13
-(SBIconListView *)currentRootIconList; // iOS 13
@end

@interface SBIconController : UIViewController // iOS 3 - 13
@property (nonatomic,readonly) SBHIconManager *iconManager; // iOS 13
+(id)sharedInstance; // iOS 3 - 13
-(BOOL)isScrolling; // iOS 3 - 12
-(SBIconListView *)currentRootIconList; // iOS 4 - 12
@end

%hook SBUIIconForceTouchController
+(BOOL)_isWidgetVisible:(id)arg1 {
	BOOL result = %orig;
	if (!result) {
		SBIconController *iconController = [%c(SBIconController) sharedInstance];
		SBIconListView *currentRootIconListView = [iconController respondsToSelector:@selector(currentRootIconList)] ? [iconController currentRootIconList] : [iconController.iconManager currentRootIconList];
		BOOL isScrolling = [iconController respondsToSelector:@selector(isScrolling)] ? [iconController isScrolling] : [iconController.iconManager isScrolling];
		if (![%c(SBUIIconForceTouchController) _isPeekingOrShowing] && !isScrolling && [currentRootIconListView containsWidget:arg1]) {
			result = YES; // to fix widget not launching URLs that open the application
		}
	}
	return result;
}
%end