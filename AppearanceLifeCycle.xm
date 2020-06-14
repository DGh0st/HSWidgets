#import "HSWidgetPageController.h"
#import "HSWidgetViewController.h"
#import "SBIconController.h"
#import "SBIconListModel.h"
#import "SBIconListView.h"
#import "SBRootFolderController.h"
#import "SpringBoard.h"

%group SimulateAppearanceMethods
%hook SBIconContentView
-(void)setHidden:(BOOL)arg1 {
	BOOL didHiddenChange = arg1 != [self isHidden];
	%orig(arg1);

	if (didHiddenChange) {
		SBIconController *iconController = [%c(SBIconController) sharedInstance];
		BOOL isShowingHomescreen = [[%c(SpringBoard) sharedApplication] isShowingHomescreen];
		[iconController bs_beginAppearanceTransition:(!arg1 || isShowingHomescreen) animated:YES];
		[iconController bs_endAppearanceTransition];
	}
}
%end

%hook SpringBoard
-(void)_updateHomeScreenPresenceNotification:(id)arg1 {
	%orig();

	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	[iconController bs_beginAppearanceTransition:[self isShowingHomescreen] animated:YES];
	[iconController bs_endAppearanceTransition];
}
%end
%end

%hook SBIconController
-(void)viewWillAppear:(BOOL)arg1 {
	%orig(arg1);

	SBRootFolderController *rootFolderController = [self _rootFolderController];
	for (SBIconListView *iconListView in rootFolderController.iconListViews) {
		SBIconListModel *model = [iconListView valueForKey:@"_model"];
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			[widgetViewController beginAppearanceTransition:YES animated:arg1];
		}
	}
}

-(void)viewDidAppear:(BOOL)arg1 {
	%orig(arg1);

	SBRootFolderController *rootFolderController = [self _rootFolderController];
	for (SBIconListView *iconListView in rootFolderController.iconListViews) {
		SBIconListModel *model = [iconListView valueForKey:@"_model"];
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			[widgetViewController endAppearanceTransition];
		}
	}
}

-(void)viewWillDisappear:(BOOL)arg1 {
	%orig(arg1);

	SBRootFolderController *rootFolderController = [self _rootFolderController];
	for (SBIconListView *iconListView in rootFolderController.iconListViews) {
		SBIconListModel *model = [iconListView valueForKey:@"_model"];
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			[widgetViewController beginAppearanceTransition:NO animated:arg1];
		}
	}
}

-(void)viewDidDisappear:(BOOL)arg1 {
	%orig(arg1);

	SBRootFolderController *rootFolderController = [self _rootFolderController];
	for (SBIconListView *iconListView in rootFolderController.iconListViews) {
		SBIconListModel *model = [iconListView valueForKey:@"_model"];
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			[widgetViewController endAppearanceTransition];
		}
	}
}

-(void)viewWillTransitionToSize:(CGSize)arg1 withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)arg2 {
	%orig(arg1, arg2);

	SBRootFolderController *rootFolderController = [self _rootFolderController];
	for (SBIconListView *iconListView in rootFolderController.iconListViews) {
		// mananges its children view controllers manually so we need to forward the events ourself
		[iconListView.widgetPageController viewWillTransitionToSize:arg1 withTransitionCoordinator:arg2];
	}
}
%end

%ctor {
	%init();

	// iOS 13+ simulates appearance methods from setIconControllerHidden, for pre iOS 13 we want to do that through hook
	if (![%c(SBHomeScreenViewController) instancesRespondToSelector:@selector(setIconControllerHidden:)]) {
		%init(SimulateAppearanceMethods);
	}
}
