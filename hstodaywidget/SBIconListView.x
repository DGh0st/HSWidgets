#import "HSTodayWidgetViewController.h"

@interface SBIconListModel // iOS 4 - 12
@property (nonatomic, retain) NSMutableArray *widgetViewControllers; // added by HSWidgets
@end

%hook SBIconListView
%new
-(BOOL)containsWidget:(NSString *)identifier {
	NSArray *widgetViewControllers = ((SBIconListModel *)[self valueForKey:@"_model"]).widgetViewControllers;
	if (widgetViewControllers != nil) {
		for (HSWidgetViewController *widgetViewController in widgetViewControllers) {
			if ([widgetViewController isKindOfClass:%c(HSTodayWidgetViewController)]) {
				NSString *widgetIdentifier = [(HSTodayWidgetViewController *)widgetViewController widgetIdentifier];
				if ([identifier isEqualToString:widgetIdentifier])
					return YES;
			}
		}
	}
	return NO;
}
%end