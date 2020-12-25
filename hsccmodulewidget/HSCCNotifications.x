#import "HSCCNotifications.h"
#import "HSCCModuleController.h"
#import "HSCCModuleWidgetViewController.h"
#import "SpringBoard.h"

%hook SBMainSwitcherViewController
-(void)viewWillAppear:(BOOL)animated {
	%orig(animated);

	if ([[%c(SpringBoard) sharedApplication] hasFinishedLaunching])
		[[HSCCModuleController sharedInstance].expandedModuleViewController dismissExpandedModule];
}
%end

%hook SBIconController
-(void)handleHomeButtonTap {
	if ([[%c(SpringBoard) sharedApplication] hasFinishedLaunching]) {
		HSCCModuleController *moduleController = [HSCCModuleController sharedInstance];
		if (moduleController.expandedModuleViewController != nil) {
			[moduleController.expandedModuleViewController dismissExpandedModule];
			return;
		}
	}

	%orig();
}
%end

static void DisplayTurnedOffNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[NSNotificationCenter defaultCenter] postNotificationName:HSCCDisplayTurnOffNotification object:nil userInfo:nil];
}

%ctor {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)DisplayTurnedOffNotification, CFSTR("SBDidTurnOffDisplayNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CFSTR("SBDidTurnOffDisplayNotification"), NULL);
}