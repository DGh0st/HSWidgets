#import <HSWidgets/HSWidgetViewController.h>

#import "WGWidgetHostingViewControllerDelegate.h"
#import "WGWidgetHostingViewControllerHost.h"
#import "WGWidgetExtensionVisibilityProviding.h"

#define HSTodayWidgetMinNumRows 2U // today widgets takes up atleast 2 row
#define HSTodayWidgetMinNumCols 4U // today widgets takes up atleast 4 col

// widget width style
typedef NS_ENUM(NSUInteger, WidthStyle) {
	WidthStyleAuto = 0,
	WidthStyleFillSpace,
	WidthStyleCustom,
};

@class WGWidgetHostingViewController;

@interface HSTodayWidgetViewController : HSWidgetViewController <WGWidgetHostingViewControllerDelegate, WGWidgetHostingViewControllerHost, WGWidgetExtensionVisibilityProviding> {
	BOOL _isExpandedMode;
	BOOL _isWidgetVisible;
}
@property (nonatomic, retain) UIView *widgetView;
@property (nonatomic, retain) WGWidgetHostingViewController *hostingViewController;
@property (nonatomic, retain, readonly) NSString *widgetIdentifier;
@end