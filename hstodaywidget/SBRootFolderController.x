#import "HSTodayWidgetController.h"
#import "HSTodayWidgetViewController.h"
#import "WGWidgetHostingViewController.h"
#import "WGWidgetPlatterView.h"

%hook SBRootFolderController
-(void)folderViewWillBeginDragging:(id)arg1 {
	%orig(arg1);

	HSTodayWidgetController *todayWidgetController = [HSTodayWidgetController sharedInstance];
	[todayWidgetController enumerateWidgetsWithBlock:^(HSTodayWidgetController *widgetController, WGWidgetHostingViewController *hostingViewController) {
		if ([hostingViewController.delegate isKindOfClass:%c(HSTodayWidgetViewController)]) {
			HSTodayWidgetViewController *widgetViewController = (HSTodayWidgetViewController *)hostingViewController.delegate;
			WGWidgetPlatterView *platterView = (WGWidgetPlatterView *)widgetViewController.widgetView;
			[platterView setContentViewHitTestingDisabled:YES];

			if (widgetController.cancelTouchesAssertionsByWidgetID[widgetViewController.widgetIdentifier] == nil)
				widgetController.cancelTouchesAssertionsByWidgetID[widgetViewController.widgetIdentifier] = [hostingViewController _cancelTouches];
		}
	}];
}

-(void)folderViewWillEndDragging:(id)arg1 {
	%orig(arg1);

	HSTodayWidgetController *todayWidgetController = [HSTodayWidgetController sharedInstance];
	[todayWidgetController enumerateWidgetsWithBlock:^(HSTodayWidgetController *widgetController, WGWidgetHostingViewController *hostingViewController) {
		if ([hostingViewController.delegate isKindOfClass:%c(HSTodayWidgetViewController)]) {
			HSTodayWidgetViewController *widgetViewController = (HSTodayWidgetViewController *)hostingViewController.delegate;
			WGWidgetPlatterView *platterView = (WGWidgetPlatterView *)widgetViewController.widgetView;
			[platterView setContentViewHitTestingDisabled:NO];
		}
	}];

	for (NSString *widgetIdentifier in todayWidgetController.cancelTouchesAssertionsByWidgetID)
		[todayWidgetController.cancelTouchesAssertionsByWidgetID[widgetIdentifier] invalidate];
	[todayWidgetController.cancelTouchesAssertionsByWidgetID removeAllObjects];
}
%end

%ctor {
	if (%c(SBHIconManager) && %c(WGWidgetPlatterView))
		%init();
}