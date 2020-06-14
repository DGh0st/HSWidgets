#import <HSWidgets/HSWidgetViewController.h>

#import "SBDateTimeOverrideObserver.h"
#import "_UISettingsKeyObserver.h"

@class SBFLockScreenDateView, _UILegibilitySettings;

@interface HSClockWidgetViewController : HSWidgetViewController <SBDateTimeOverrideObserver, _UISettingsKeyObserver> {
	_UILegibilitySettings* _legibilitySettings;
	NSNumber *_timerToken;
}
@property (nonatomic, retain) SBFLockScreenDateView *dateView;
@end