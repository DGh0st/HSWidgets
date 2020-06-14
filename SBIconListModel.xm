#import "HSWidgetViewController.h"
#import "SBIconListModel.h"

%hook SBIconListModel
%property (nonatomic, assign) PageType pageLayoutType; // PageType enum
%property (nonatomic, retain) NSMutableArray *widgetViewControllers;

-(instancetype)initWithFolder:(id)arg1 maxIconCount:(NSUInteger)arg2 { // iOS 10 - 12
	self = %orig(arg1, arg2);
	if (self != nil) {
		self.pageLayoutType = PageTypeNone;
		self.widgetViewControllers = nil;
	}
	return self;
}

-(instancetype)initWithUniqueIdentifier:(id)arg1 folder:(id)arg2 maxIconCount:(NSUInteger)arg3 { // iOS 13
	self = %orig(arg1, arg2, arg3);
	if (self != nil) {
		self.pageLayoutType = PageTypeNone;
		self.widgetViewControllers = nil;
	}
	return self;
}

-(BOOL)addIcon:(id)arg1 asDirty:(BOOL)arg2 {
	BOOL result = %orig(arg1, arg2);
	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAvailableSpaceDidChangeNotification object:nil userInfo:nil];
	return result;
}

-(void)removeIconAtIndex:(NSUInteger)arg1 {
	%orig(arg1);

	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAvailableSpaceDidChangeNotification object:nil userInfo:nil];
}

-(void)dealloc {
	if (self.widgetViewControllers != nil) {
		for (HSWidgetViewController *widgetViewController in self.widgetViewControllers) {
			[widgetViewController _setDelegate:nil];
			[widgetViewController.view removeFromSuperview];
			[widgetViewController release];
		}
		self.widgetViewControllers = nil;
	}

	%orig();
}
%end