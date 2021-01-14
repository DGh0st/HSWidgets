#import <HSWidgets/HSModernWidgetViewController.h>
#import "HSWeatherControllerObserver.h"

@class WUIDynamicWeatherBackground, HSModernWeatherDailyForecastView, HSModernWeatherHourlyForecastView;

typedef NS_ENUM(NSUInteger, HSModernWeatherWidgetBackgroundStyle) {
	HSModernWeatherWidgetBackgroundStyleGradient = 0,
	HSModernWeatherWidgetBackgroundStyleAnimated
};

typedef NS_ENUM(NSUInteger, HSModernWeatherWidgetDisplayMode) {
	HSModernWeatherWidgetDisplayModeSmall = 0,
	HSModernWeatherWidgetDisplayModeMedium,
	// HSModernWeatherWidgetDisplayModeLarge,
	HSModernWeatherWidgetDisplayModeExtraLarge
};

@interface HSModernWeatherWidgetViewController : HSModernWidgetViewController <HSWeatherControllerObserver>
@property (nonatomic, retain) UILabel *location;
@property (nonatomic, retain) UILabel *temperature;
@property (nonatomic, retain) UIImageView *conditionImageView;
@property (nonatomic, retain) UILabel *conditionDescription;
@property (nonatomic, retain) UILabel *highLowTemperature;
@property (nonatomic, retain) WUIDynamicWeatherBackground *dynamicWeatherBackground;
@property (nonatomic, retain) UIStackView *hourlyForecastContainerView;
@property (nonatomic, retain) NSMutableArray<HSModernWeatherHourlyForecastView *> *hourlyForecastViews;
@property (nonatomic, retain) UIStackView *dailyForecastContainerView;
@property (nonatomic, retain) NSMutableArray<HSModernWeatherDailyForecastView *> *dailyForecastViews;
@property (nonatomic, assign, setter=_setDisplayMode:) HSModernWeatherWidgetDisplayMode displayMode;
@property (nonatomic, assign) HSModernWeatherWidgetBackgroundStyle backgroundStyle;
@property (nonatomic, assign, setter=_setEdgePadding:) CGFloat edgePadding;
@end