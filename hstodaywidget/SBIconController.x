#import "HSTodayWidgetController.h"
#import "HSTodayWidgetViewController.h"
#import "WGWidgetHostingViewController.h"
#import "WGWidgetPlatterView.h"

%hook SBIconController
-(void)iconManager:(id)arg1 folderControllerWillBeginScrolling:(id)arg2 {
	%orig(arg1, arg2);

	HSTodayWidgetController *todayWidgetController = [HSTodayWidgetController sharedInstance];
	[todayWidgetController enumerateWidgetsWithBlock:^(HSTodayWidgetController *widgetController, WGWidgetHostingViewController *hostingViewController) {
		HSTodayWidgetViewController *widgetViewController = (HSTodayWidgetViewController *)hostingViewController.host;
		WGWidgetPlatterView *platterView = (WGWidgetPlatterView *)widgetViewController.widgetView;
		[platterView setContentViewHitTestingDisabled:YES];

		if (widgetController.cancelTouchesAssertionsByWidgetID[widgetViewController.widgetIdentifier] == nil)
			widgetController.cancelTouchesAssertionsByWidgetID[widgetViewController.widgetIdentifier] = [hostingViewController _cancelTouches];
	}];
}

-(void)iconManager:(id)arg1 folderControllerDidEndScrolling:(id)arg2 {
	%orig(arg1, arg2);

	HSTodayWidgetController *todayWidgetController = [HSTodayWidgetController sharedInstance];
	[todayWidgetController enumerateWidgetsWithBlock:^(HSTodayWidgetController *widgetController, WGWidgetHostingViewController *hostingViewController) {
		HSTodayWidgetViewController *widgetViewController = (HSTodayWidgetViewController *)hostingViewController.host;
		WGWidgetPlatterView *platterView = (WGWidgetPlatterView *)widgetViewController.widgetView;
		[platterView setContentViewHitTestingDisabled:NO];
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