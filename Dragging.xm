#import "HSWidgetPageController.h"
#import "SBIconController.h"
#import "SBIconListView.h"
#import "SBRootFolderController.h"

%hook SBIconController
%property (nonatomic, assign) BOOL isDraggingWidget;

-(void)viewDidLoad {
	%orig();

	self.isDraggingWidget = NO;
}

-(BOOL)_iconCanBeGrabbed:(id)arg1 { // iOS 4 - 12
	if (self.isDraggingWidget)
		return NO; // disable icon grabbing when widget is being dragged
	return %orig(arg1);
}

-(BOOL)_shouldRespondToIconCloseBoxes { // iOS 11 - 12
	if (self.isDraggingWidget)
		return NO; // disable icon deletion when widget is being dragged
	return %orig();
}

-(void)uninstallIcon:(id)arg1 { // iOS 10
	SBIconListView *iconListView = [[self _rootFolderController] currentIconListView];
	HSWidgetPageController *widgetPageController = iconListView.widgetPageController;
	[widgetPageController animateUpdateOfIconChangesExcludingCurrentIcon:YES completion:nil];

	%orig(arg1);
}

-(void)uninstallIcon:(id)arg1 animate:(BOOL)arg2 completion:(id)arg3 { // iOS 11 - 12
	SBIconListView *iconListView = [[self _rootFolderController] currentIconListView];
	HSWidgetPageController *widgetPageController = iconListView.widgetPageController;
	[widgetPageController animateUpdateOfIconChangesExcludingCurrentIcon:YES completion:nil];

	%orig(arg1, arg2, arg3);
}

-(void)iconDragManagerIconDraggingDidChange:(id)arg1 { // iOS 11 - 12
	%orig(arg1); // post a SBIconControllerIconDraggingChangedNotification

	for (SBIconListView *iconListView in [self _rootFolderController].iconListViews) {
		HSWidgetPageController *widgetPageController = iconListView.widgetPageController;
		[widgetPageController animateUpdateOfIconChangesExcludingCurrentIcon:NO completion:nil];
	}
}

-(void)iconDragManagerMultiItemIconDraggingDidChange:(id)arg1 { // iOS 11 - 12
	%orig(arg1);
	
	for (SBIconListView *iconListView in [self _rootFolderController].iconListViews) {
		HSWidgetPageController *widgetPageController = iconListView.widgetPageController;
		[widgetPageController animateUpdateOfIconChangesExcludingCurrentIcon:NO completion:nil];
	}
}
%end

%hook SBHIconManager
-(BOOL)iconViewCanBeginDrags:(id)arg1 { // iOS 13
	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	if (iconController.isDraggingWidget)
		return NO; // disable icon grabbing when widget is being draggged
	return %orig(arg1);
}

-(BOOL)_shouldRespondToIconCloseBoxes { // iOS 13
	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	if (iconController.isDraggingWidget)
		return NO; // disable icon deletion when widget is being dragged
	return %orig();
}

-(void)uninstallIcon:(id)arg1 animate:(BOOL)arg2 completion:(id)arg3 { // iOS 13
	SBIconListView *iconListView = [[self rootFolderController] currentIconListView];
	HSWidgetPageController *widgetPageController = iconListView.widgetPageController;
	[widgetPageController animateUpdateOfIconChangesExcludingCurrentIcon:YES completion:nil];

	%orig(arg1, arg2, arg3);
}

-(void)iconDragManagerIconDraggingDidChange:(id)arg1 { // iOS 13
	%orig(arg1); // post a SBHIconManagerIconDraggingChanged

	for (SBIconListView *iconListView in [self rootFolderController].iconListViews) {
		HSWidgetPageController *widgetPageController = iconListView.widgetPageController;
		[widgetPageController animateUpdateOfIconChangesExcludingCurrentIcon:NO completion:nil];
	}
}

-(void)iconDragManagerMultiItemIconDraggingDidChange:(id)arg1 { // iOS 13
	%orig(arg1);

	for (SBIconListView *iconListView in [self rootFolderController].iconListViews) {
		HSWidgetPageController *widgetPageController = iconListView.widgetPageController;
		[widgetPageController animateUpdateOfIconChangesExcludingCurrentIcon:NO completion:nil];
	}
}
%end
