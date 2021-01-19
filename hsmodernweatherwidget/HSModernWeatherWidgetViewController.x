#import "HSModernWeatherWidgetViewController.h"
#import "City.h"
#import "HSModernWeatherDailyForecastView.h"
#import "HSModernWeatherHourlyForecastView.h"
#import "HSWeatherController.h"
#import "SpringBoard.h"
#import "UIImage+Private.h"
#import "WUIDynamicWeatherBackground.h"
#import "WUIGradientLayer.h"
#import "WUIWeatherCondition.h"

#import <HSWidgets/HSWidgetResources.h>

#define LOCATION_FONT_SIZE 16
#define LOCATION_HEIGHT 18
#define TEMPERATURE_FONT_SIZE 48
#define MIN_TEMPERATURE_HEIGHT 36
#define MIN_TEMPERATURE_FONT_SIZE 42
#define IMAGE_HEIGHT 40
#define CONDITION_DESCRIPTION_FONT_SIZE 14
#define HIGH_LOW_TEMPERATURE_FONT_SIZE 14

#define MAX_CONTENT_PADDING 16
#define CONTENT_PADDING 10
#define MIN_EDGE_PADDING 12
#define EDGE_PADDING 16
#define IMAGE_PADDING 6

#define NUM_HOURLY_FORECAST 6
#define HOURLY_FORECAST_HEIGHT 56
#define HOURLY_FORECAST_PADDING 5

#define NUM_DAILY_FORECAST 6
#define DAILY_FORECAST_HEIGHT 168
#define DAILY_FORECAST_PADDING 0

#define DISPLAY_MODE_KEY @"DisplayMode"
#define BACKGROUND_STYLE_KEY @"BackgroundStyle"

#define WEATHER_APP_IDENTIFIER @"com.apple.weather"

@implementation HSModernWeatherWidgetViewController
+(BOOL)isAvailable {
	return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}

+(NSDictionary *)widgetDisplayInfo {
	UIImage *iconImage = [UIImage _applicationIconImageForBundleIdentifier:WEATHER_APP_IDENTIFIER format:0 scale:[UIScreen mainScreen].scale];
	return @{
		HSWidgetDisplayNameKey : @"Weather (Modern)",
		HSWidgetDisplayIconKey : iconImage ?: [HSWidgetResources imageNamed:HSWidgetPlaceholderImageName],
		HSWidgetDisplayCreatorKey : @"DGh0st"
	};
}

-(instancetype)initForWidgetFrame:(HSWidgetFrame)frame withOptions:(NSDictionary *)options {
	self = [super initForWidgetFrame:frame withOptions:options];
	if (self != nil) {
		_displayMode = widgetOptions[DISPLAY_MODE_KEY] ? [widgetOptions[DISPLAY_MODE_KEY] unsignedIntegerValue] : HSModernWeatherWidgetDisplayModeSmall;
		_edgePadding = EDGE_PADDING;

		self.backgroundStyle = widgetOptions[BACKGROUND_STYLE_KEY] ? [widgetOptions[BACKGROUND_STYLE_KEY] unsignedIntegerValue] : HSModernWeatherWidgetBackgroundStyleGradient;
	}
	return self;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	BOOL isMediumOrLarger = (self.displayMode == HSModernWeatherWidgetDisplayModeMedium || self.displayMode == HSModernWeatherWidgetDisplayModeExtraLarge);
	CGRect calculatedFrame = [self calculatedFrame];

	self.titleLabel.text = @"Weather";

	self.dynamicWeatherBackground = [[WUIDynamicWeatherBackground alloc] initWithFrame:calculatedFrame];
	self.dynamicWeatherBackground.userInteractionEnabled = NO;
	if (self.backgroundStyle == HSModernWeatherWidgetBackgroundStyleGradient) {
		self.dynamicWeatherBackground.gradientLayer.bounds = calculatedFrame;
		[self.contentView.layer addSublayer:self.dynamicWeatherBackground.gradientLayer];
	} else if (self.backgroundStyle == HSModernWeatherWidgetBackgroundStyleAnimated) {
		// TODO: find why animated background doesn't start animating when first adding widgets
		[self.contentView addSubview:self.dynamicWeatherBackground];
	}

	self.location = [[UILabel alloc] init];
	self.location.userInteractionEnabled = NO;
	self.location.text = HSWeatherFakeDisplayName;
	self.location.font = [UIFont systemFontOfSize:LOCATION_FONT_SIZE weight:UIFontWeightSemibold];
	self.location.numberOfLines = 1;
	self.location.textAlignment = NSTextAlignmentLeft;
	self.location.textColor = [UIColor whiteColor];
	self.location.backgroundColor = [UIColor clearColor];
	self.location.lineBreakMode = NSLineBreakByTruncatingTail;
	[self.contentView addSubview:self.location];

	self.temperature = [[UILabel alloc] init];
	self.temperature.userInteractionEnabled = NO;
	self.temperature.text = HSWeatherFakeTemperature;
	self.temperature.font = [UIFont systemFontOfSize:isMediumOrLarger ? MIN_TEMPERATURE_FONT_SIZE : TEMPERATURE_FONT_SIZE weight:UIFontWeightLight];
	self.temperature.numberOfLines = 1;
	self.temperature.textAlignment = NSTextAlignmentLeft;
	self.temperature.textColor = [UIColor whiteColor];
	self.temperature.backgroundColor = [UIColor clearColor];
	self.temperature.adjustsFontSizeToFitWidth = YES;
	[self.contentView addSubview:self.temperature];

	self.conditionImageView = [[UIImageView alloc] init];
	self.conditionImageView.userInteractionEnabled = NO;
	self.conditionImageView.image = nil;
	self.conditionImageView.contentMode = isMediumOrLarger ? UIViewContentModeBottomRight : UIViewContentModeBottomLeft;
	self.conditionImageView.backgroundColor = [UIColor clearColor];
	[self.contentView addSubview:self.conditionImageView];

	self.conditionDescription = [[UILabel alloc] init];
	self.conditionDescription.userInteractionEnabled = NO;
	self.conditionDescription.text = HSWeatherFakeDescription;
	self.conditionDescription.font = [UIFont systemFontOfSize:CONDITION_DESCRIPTION_FONT_SIZE weight:UIFontWeightMedium];
	self.conditionDescription.numberOfLines = 1;
	self.conditionDescription.textAlignment = isMediumOrLarger ? NSTextAlignmentRight : NSTextAlignmentLeft;
	self.conditionDescription.textColor = [UIColor whiteColor];
	self.conditionDescription.backgroundColor = [UIColor clearColor];
	[self.contentView addSubview:self.conditionDescription];

	self.highLowTemperature = [[UILabel alloc] init];
	self.highLowTemperature.userInteractionEnabled = NO;
	self.highLowTemperature.text = HSWeatherFakeHighLowDescription;
	self.highLowTemperature.font = [UIFont systemFontOfSize:HIGH_LOW_TEMPERATURE_FONT_SIZE weight:UIFontWeightMedium];
	self.highLowTemperature.numberOfLines = 1;
	self.highLowTemperature.textAlignment = isMediumOrLarger ? NSTextAlignmentRight : NSTextAlignmentLeft;
	self.highLowTemperature.textColor = [UIColor whiteColor];
	self.highLowTemperature.backgroundColor = [UIColor clearColor];
	[self.contentView addSubview:self.highLowTemperature];

	self.hourlyForecastViews = [NSMutableArray arrayWithCapacity:NUM_HOURLY_FORECAST];
	for (NSUInteger i = 0; i < NUM_HOURLY_FORECAST; ++i) {
		HSModernWeatherHourlyForecastView *hourlyForecastView = [[HSModernWeatherHourlyForecastView alloc] init];
		[self.hourlyForecastViews addObject:hourlyForecastView];
		[hourlyForecastView release];
	}

	self.hourlyForecastContainerView = [[UIStackView alloc] initWithArrangedSubviews:self.hourlyForecastViews];
	self.hourlyForecastContainerView.userInteractionEnabled = NO;
	self.hourlyForecastContainerView.axis = UILayoutConstraintAxisHorizontal;
	self.hourlyForecastContainerView.distribution = UIStackViewDistributionFillEqually;
	self.hourlyForecastContainerView.spacing = HOURLY_FORECAST_PADDING;
	if (isMediumOrLarger)
		[self.contentView addSubview:self.hourlyForecastContainerView];

	self.dailyForecastViews = [NSMutableArray arrayWithCapacity:NUM_DAILY_FORECAST];
	for (NSUInteger i = 0; i < NUM_DAILY_FORECAST; ++i) {
		HSModernWeatherDailyForecastView *dailyForecastView = [[HSModernWeatherDailyForecastView alloc] init];
		[self.dailyForecastViews addObject:dailyForecastView];
		[dailyForecastView release];
	}

	self.dailyForecastContainerView = [[UIStackView alloc] initWithArrangedSubviews:self.dailyForecastViews];
	self.dailyForecastContainerView.userInteractionEnabled = NO;
	self.dailyForecastContainerView.axis = UILayoutConstraintAxisVertical;
	self.dailyForecastContainerView.distribution = UIStackViewDistributionFillEqually;
	self.dailyForecastContainerView.spacing = DAILY_FORECAST_PADDING;
	if (self.displayMode == HSModernWeatherWidgetDisplayModeExtraLarge)
		[self.contentView addSubview:self.dailyForecastContainerView];

	[self _setupConstraints:self.displayMode];

	UITapGestureRecognizer *openAppGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openApp)];
	self.contentView.userInteractionEnabled = YES;
	[self.contentView addGestureRecognizer:openAppGesture];
	[openAppGesture release];

	HSWeatherController *weatherController = [HSWeatherController sharedInstance];
	[weatherController addObserver:self];
	[weatherController requestModelUpdate];
	[weatherController startUpdateTimer];
}

-(void)setRequestedSize:(CGSize)requestedSize {
	[super setRequestedSize:requestedSize];

	CGRect calculatedFrame = [self calculatedFrame];
	if (self.backgroundStyle == HSModernWeatherWidgetBackgroundStyleGradient) {
		CGRect presentationBounds = self.dynamicWeatherBackground.gradientLayer.presentationLayer.bounds;
		CGRect previousBounds = (presentationBounds.size.height > 0 && presentationBounds.size.width > 0) ? presentationBounds : self.dynamicWeatherBackground.gradientLayer.bounds;

		CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
		boundsAnimation.fromValue = [NSValue valueWithCGRect:previousBounds];
		boundsAnimation.toValue = [NSValue valueWithCGRect:calculatedFrame];
		self.dynamicWeatherBackground.gradientLayer.frame = calculatedFrame;
		[self.dynamicWeatherBackground.gradientLayer addAnimation:boundsAnimation forKey:@"bounds"];
	} else if (self.backgroundStyle == HSModernWeatherWidgetBackgroundStyleAnimated) {
		self.dynamicWeatherBackground.frame = calculatedFrame;
	}

	BOOL isSmallOrMedium = (self.displayMode == HSModernWeatherWidgetDisplayModeSmall || self.displayMode == HSModernWeatherWidgetDisplayModeMedium);
	BOOL isLarger = (self.displayMode == HSModernWeatherWidgetDisplayModeExtraLarge);
	if ((isSmallOrMedium && calculatedFrame.size.height >= 156) || (isLarger && calculatedFrame.size.height >= 328)) {
		self.edgePadding = EDGE_PADDING;

		if (isLarger)
			[self.dailyForecastContainerView addArrangedSubview:self.dailyForecastViews.lastObject];
	} else {
		self.edgePadding = MIN_EDGE_PADDING;

		if (isLarger)
			[self.dailyForecastViews.lastObject removeFromSuperview];
	}
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	HSWeatherController *weatherController = [HSWeatherController sharedInstance];
	[weatherController addObserver:self];
	[weatherController requestModelUpdate];
	[weatherController startUpdateTimer];
	[self _updateViews];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	if (self.backgroundStyle == HSModernWeatherWidgetBackgroundStyleAnimated)
		[self.dynamicWeatherBackground.condition resume];
}

-(void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	if (self.backgroundStyle == HSModernWeatherWidgetBackgroundStyleAnimated)
		[self.dynamicWeatherBackground.condition pause];
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	HSWeatherController *weatherController = [HSWeatherController sharedInstance];
	[weatherController removeObserver:self];
	[weatherController stopUpdateTimer];
}

-(BOOL)isAccessoryTypeEnabled:(AccessoryType)accessory {
	if (accessory == AccessoryTypeExpand) {
		if (self.displayMode == HSModernWeatherWidgetDisplayModeSmall)
			return [super containsSpaceToExpandOrShrinkToWidgetSize:HSWidgetSizeMake(2, 4)];
		else if (self.displayMode == HSModernWeatherWidgetDisplayModeMedium)
			return [super containsSpaceToExpandOrShrinkToWidgetSize:HSWidgetSizeMake(4, 4)];
		return NO;
	} else if (accessory == AccessoryTypeShrink) {
		if (self.displayMode == HSModernWeatherWidgetDisplayModeExtraLarge)
			return [super containsSpaceToExpandOrShrinkToWidgetSize:HSWidgetSizeMake(2, 4)];
		else if (self.displayMode == HSModernWeatherWidgetDisplayModeMedium)
			return [super containsSpaceToExpandOrShrinkToWidgetSize:HSWidgetSizeMake(2, 2)];
		return NO;
	}
	return [super isAccessoryTypeEnabled:accessory];
}

-(void)accessoryTypeTapped:(AccessoryType)accessory {
	if (accessory == AccessoryTypeExpand) {
		if (self.displayMode == HSModernWeatherWidgetDisplayModeSmall) {
			HSWidgetSize expandSize = HSWidgetSizeMake(2, 4);
			if ([super containsSpaceToExpandOrShrinkToWidgetSize:expandSize]) {
				self.displayMode = HSModernWeatherWidgetDisplayModeMedium;
				[self _updateViewsToMedium];
				[super updateForExpandOrShrinkToWidgetSize:expandSize];
			}
		} else if (self.displayMode == HSModernWeatherWidgetDisplayModeMedium) {
			HSWidgetSize expandSize = HSWidgetSizeMake(4, 4);
			if ([super containsSpaceToExpandOrShrinkToWidgetSize:expandSize]) {
				self.displayMode = HSModernWeatherWidgetDisplayModeExtraLarge;
				[self _updateViewsToExtraLarge];
				[super updateForExpandOrShrinkToWidgetSize:expandSize];
			}
		}
	} else if (accessory == AccessoryTypeShrink) {
		if (self.displayMode == HSModernWeatherWidgetDisplayModeExtraLarge) {
			HSWidgetSize shrinkSize = HSWidgetSizeMake(2, 4);
			if ([super containsSpaceToExpandOrShrinkToWidgetSize:shrinkSize]) {
				self.displayMode = HSModernWeatherWidgetDisplayModeMedium;
				[self _updateViewsToMedium];
				[super updateForExpandOrShrinkToWidgetSize:shrinkSize];
			}
		} else if (self.displayMode == HSModernWeatherWidgetDisplayModeMedium) {
			HSWidgetSize shrinkSize = HSWidgetSizeMake(2, 2);
			if ([super containsSpaceToExpandOrShrinkToWidgetSize:shrinkSize]) {
				self.displayMode = HSModernWeatherWidgetDisplayModeSmall;
				[self _updateViewsToSmall];
				[super updateForExpandOrShrinkToWidgetSize:shrinkSize];
			}
		}
	}
}

-(void)weatherModelUpdatedForController:(HSWeatherController *)weatherController {
	if (self.viewLoaded)
		[self _updateViews];
}

-(void)openApp {
	[(SpringBoard *)[%c(SpringBoard) sharedApplication] launchApplicationWithIdentifier:WEATHER_APP_IDENTIFIER suspended:NO];
}

-(void)_updateViewsToSmall {
	[self.hourlyForecastContainerView removeFromSuperview];
	[self.dailyForecastContainerView removeFromSuperview];
	self.conditionImageView.contentMode = UIViewContentModeBottomLeft;
	self.conditionDescription.textAlignment = NSTextAlignmentLeft;
	self.highLowTemperature.textAlignment = NSTextAlignmentLeft;

	[UIView transitionWithView:self.temperature duration:HSWidgetAnimationDuration options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
		self.temperature.font = [UIFont systemFontOfSize:TEMPERATURE_FONT_SIZE weight:UIFontWeightLight];
	} completion:nil];

	[self _setupConstraints:self.displayMode];
}

-(void)_updateViewsToMedium {
	[self.contentView addSubview:self.hourlyForecastContainerView];
	[self.dailyForecastContainerView removeFromSuperview];
	self.conditionImageView.contentMode = UIViewContentModeTopRight;
	self.conditionDescription.textAlignment = NSTextAlignmentRight;
	self.highLowTemperature.textAlignment = NSTextAlignmentRight;

	[UIView transitionWithView:self.temperature duration:HSWidgetAnimationDuration options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
		self.temperature.font = [UIFont systemFontOfSize:MIN_TEMPERATURE_FONT_SIZE weight:UIFontWeightLight];
	} completion:nil];

	[self _setupConstraints:self.displayMode];
}

-(void)_updateViewsToExtraLarge {
	[self.contentView addSubview:self.hourlyForecastContainerView];
	[self.contentView addSubview:self.dailyForecastContainerView];
	self.conditionImageView.contentMode = UIViewContentModeTopRight;
	self.conditionDescription.textAlignment = NSTextAlignmentRight;
	self.highLowTemperature.textAlignment = NSTextAlignmentRight;

	[UIView transitionWithView:self.temperature duration:HSWidgetAnimationDuration options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
		self.temperature.font = [UIFont systemFontOfSize:MIN_TEMPERATURE_FONT_SIZE weight:UIFontWeightLight];
	} completion:nil];

	[self _setupConstraints:self.displayMode];
}

-(void)_updateViews {
	HSWeatherController *weatherController = [HSWeatherController sharedInstance];
	[UIView transitionWithView:self.contentView duration:HSWidgetAnimationDuration options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
		// fill the basic weather info
		self.location.text = [weatherController locationName];
		self.temperature.text = [weatherController temperature];
		self.conditionImageView.image = [weatherController conditionsImage];
		self.conditionDescription.text = [weatherController conditionsDescription];
		self.highLowTemperature.text = [weatherController highLowDescription];

		// fill the hourly forecast info
		NSArray<NSDictionary *> *hourlyForecasts = [weatherController hourlyForecasts];
		NSUInteger hourlyForecastIndex = 0;

		if (hourlyForecasts.count > 0) {
			NSUInteger numHourlyForecasts = MIN(hourlyForecasts.count, self.hourlyForecastViews.count);
			for (; hourlyForecastIndex < numHourlyForecasts; ++hourlyForecastIndex) {
				HSModernWeatherHourlyForecastView *hourlyForecastView = self.hourlyForecastViews[hourlyForecastIndex];
				NSDictionary *hourlyForecast = hourlyForecasts[hourlyForecastIndex];
				
				hourlyForecastView.timeLabel.text = hourlyForecast[HSWeatherHourlyForecastTimeKey];
				hourlyForecastView.imageView.image = hourlyForecast[HSWeatherHourlyForecastConditionImageKey];
				hourlyForecastView.temperatureLabel.text = hourlyForecast[HSWeatherHourlyForecastTemperatureKey];
			}
		}

		for (; hourlyForecastIndex < self.hourlyForecastViews.count; ++hourlyForecastIndex) {
			HSModernWeatherHourlyForecastView *hourlyForecastView = self.hourlyForecastViews[hourlyForecastIndex];
			hourlyForecastView.timeLabel.text = @"";
			hourlyForecastView.imageView.image = nil;
			hourlyForecastView.temperatureLabel.text = HSWeatherFakeTemperature;
		}

		// fill the daily forecast info
		NSArray<NSDictionary *> *dailyForecasts = [weatherController dailyForecasts];
		NSUInteger dailyForecastIndex = 0;

		if (dailyForecasts.count > 0) {
			NSUInteger numDailyForecasts = MIN(dailyForecasts.count - 1, self.dailyForecastViews.count);
			for (; dailyForecastIndex < numDailyForecasts; ++dailyForecastIndex) {
				HSModernWeatherDailyForecastView *dailyForecastView = self.dailyForecastViews[dailyForecastIndex];
				NSDictionary *dailyForecast = dailyForecasts[dailyForecastIndex + 1];
				
				dailyForecastView.weekDayLabel.text = dailyForecast[HSWeatherDailyForecastDayOfWeekKey];
				dailyForecastView.imageView.image = dailyForecast[HSWeatherDailyForecastConditionImageKey];
				dailyForecastView.highTemperatureLabel.text = dailyForecast[HSWeatherDailyForecastHighTemperatureKey];
				dailyForecastView.lowTemperatureLabel.text = dailyForecast[HSWeatherDailyForecastLowTemperatureKey];
			}
		}

		for (; dailyForecastIndex < self.dailyForecastViews.count; ++dailyForecastIndex) {
			HSModernWeatherDailyForecastView *dailyForecastView = self.dailyForecastViews[dailyForecastIndex];
			dailyForecastView.weekDayLabel.text = @"";
			dailyForecastView.imageView.image = nil;
			dailyForecastView.highTemperatureLabel.text = HSWeatherFakeTemperature;
			dailyForecastView.lowTemperatureLabel.text = HSWeatherFakeTemperature;
		}

		// update the dynamic background
		WUIDynamicWeatherBackground *dynamicWeatherBackground = self.dynamicWeatherBackground;
		WUIWeatherCondition *condition = dynamicWeatherBackground.condition;
		City *currentCity = [weatherController currentCity];
		if (condition.city != currentCity) {
			bool backgroundStyleIsAnimated = (self.backgroundStyle == HSModernWeatherWidgetBackgroundStyleAnimated);
			if (backgroundStyleIsAnimated)
				[condition pause];

			[dynamicWeatherBackground setCity:currentCity];
			condition.city = currentCity;

			if (backgroundStyleIsAnimated)
				[condition resume];
		}
		[dynamicWeatherBackground setNeedsDisplay];
	} completion:nil];
}

-(void)_setupConstraints:(HSModernWeatherWidgetDisplayMode)mode {
	// remove all previous constraints
	[self.contentView removeConstraints:self.contentView.constraints];

	CGFloat edgePadding = self.edgePadding;
	CGFloat imageEdgePadding = edgePadding - IMAGE_PADDING;

	// setup constraints again
	if (mode == HSModernWeatherWidgetDisplayModeExtraLarge) {
		self.location.translatesAutoresizingMaskIntoConstraints = NO;
		[self.location.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.location.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.conditionImageView.leadingAnchor constant:-IMAGE_PADDING].active = YES;
		[self.location.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:edgePadding].active = YES;
		[self.location.heightAnchor constraintEqualToConstant:LOCATION_HEIGHT].active = YES;

		self.temperature.translatesAutoresizingMaskIntoConstraints = NO;
		[self.temperature.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.temperature.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.conditionDescription.leadingAnchor constant:-edgePadding].active = YES;
		[self.temperature.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.highLowTemperature.leadingAnchor constant:-edgePadding].active = YES;
		[self.temperature.topAnchor constraintEqualToAnchor:self.location.bottomAnchor constant:2].active = YES;
		[self.temperature.heightAnchor constraintGreaterThanOrEqualToConstant:MIN_TEMPERATURE_HEIGHT].active = YES;
		[self.temperature.bottomAnchor constraintLessThanOrEqualToAnchor:self.hourlyForecastContainerView.topAnchor constant:-CONTENT_PADDING].active = YES;
		[self.temperature.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.hourlyForecastContainerView.topAnchor constant:-MAX_CONTENT_PADDING].active = YES;
		[self.temperature.bottomAnchor constraintEqualToAnchor:self.highLowTemperature.bottomAnchor].active = YES;

		self.conditionImageView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.conditionImageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.location.trailingAnchor constant:-IMAGE_PADDING].active = YES;
		[self.conditionImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-imageEdgePadding].active = YES;
		[self.conditionImageView.heightAnchor constraintEqualToConstant:IMAGE_HEIGHT].active = YES;
		[self.conditionImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:imageEdgePadding].active = YES;
		[self.conditionImageView.bottomAnchor constraintLessThanOrEqualToAnchor:self.conditionDescription.topAnchor constant:IMAGE_PADDING].active = YES;

		self.conditionDescription.translatesAutoresizingMaskIntoConstraints = NO;
		[self.conditionDescription.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.temperature.trailingAnchor constant:-edgePadding].active = YES;
		[self.conditionDescription.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding].active = YES;
		[self.conditionDescription.heightAnchor constraintEqualToConstant:CONDITION_DESCRIPTION_FONT_SIZE].active = YES;
		[self.conditionDescription.bottomAnchor constraintEqualToAnchor:self.highLowTemperature.topAnchor constant:-2].active = YES;

		self.highLowTemperature.translatesAutoresizingMaskIntoConstraints = NO;
		[self.highLowTemperature.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.temperature.trailingAnchor constant:-edgePadding].active = YES;
		[self.highLowTemperature.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding].active = YES;
		[self.highLowTemperature.topAnchor constraintEqualToAnchor:self.conditionDescription.bottomAnchor constant:2].active = YES;
		[self.highLowTemperature.heightAnchor constraintEqualToConstant:HIGH_LOW_TEMPERATURE_FONT_SIZE].active = YES;
		[self.highLowTemperature.bottomAnchor constraintLessThanOrEqualToAnchor:self.hourlyForecastContainerView.topAnchor constant:-CONTENT_PADDING].active = YES;
		[self.highLowTemperature.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.hourlyForecastContainerView.topAnchor constant:-MAX_CONTENT_PADDING].active = YES;
		[self.highLowTemperature.bottomAnchor constraintEqualToAnchor:self.temperature.bottomAnchor].active = YES;

		self.hourlyForecastContainerView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.hourlyForecastContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding / 2.0].active = YES;
		[self.hourlyForecastContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding / 2.0].active = YES;
		[self.hourlyForecastContainerView.heightAnchor constraintEqualToConstant:HOURLY_FORECAST_HEIGHT].active = YES;
		[self.hourlyForecastContainerView.bottomAnchor constraintEqualToAnchor:self.dailyForecastContainerView.topAnchor constant:-CONTENT_PADDING].active = YES;

		self.dailyForecastContainerView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.dailyForecastContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.dailyForecastContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding].active = YES;
		[self.dailyForecastContainerView.heightAnchor constraintGreaterThanOrEqualToConstant:DAILY_FORECAST_HEIGHT].active = YES;
		[self.dailyForecastContainerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-imageEdgePadding].active = YES;
	} else if (mode == HSModernWeatherWidgetDisplayModeMedium) {
		self.location.translatesAutoresizingMaskIntoConstraints = NO;
		[self.location.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.location.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.conditionImageView.leadingAnchor constant:-IMAGE_PADDING].active = YES;
		[self.location.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:edgePadding].active = YES;
		[self.location.heightAnchor constraintEqualToConstant:LOCATION_HEIGHT].active = YES;

		self.temperature.translatesAutoresizingMaskIntoConstraints = NO;
		[self.temperature.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.temperature.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.conditionDescription.leadingAnchor constant:-edgePadding].active = YES;
		[self.temperature.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.highLowTemperature.leadingAnchor constant:-edgePadding].active = YES;
		[self.temperature.topAnchor constraintEqualToAnchor:self.location.bottomAnchor constant:2].active = YES;
		[self.temperature.heightAnchor constraintGreaterThanOrEqualToConstant:MIN_TEMPERATURE_HEIGHT].active = YES;
		[self.temperature.bottomAnchor constraintLessThanOrEqualToAnchor:self.hourlyForecastContainerView.topAnchor constant:-CONTENT_PADDING].active = YES;
		[self.temperature.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.hourlyForecastContainerView.topAnchor constant:-MAX_CONTENT_PADDING].active = YES;
		[self.temperature.bottomAnchor constraintEqualToAnchor:self.highLowTemperature.bottomAnchor].active = YES;

		self.conditionImageView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.conditionImageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.location.trailingAnchor constant:-IMAGE_PADDING].active = YES;
		[self.conditionImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-imageEdgePadding].active = YES;
		[self.conditionImageView.heightAnchor constraintEqualToConstant:IMAGE_HEIGHT].active = YES;
		[self.conditionImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:imageEdgePadding].active = YES;
		[self.conditionImageView.bottomAnchor constraintLessThanOrEqualToAnchor:self.conditionDescription.topAnchor constant:IMAGE_PADDING].active = YES;

		self.conditionDescription.translatesAutoresizingMaskIntoConstraints = NO;
		[self.conditionDescription.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.temperature.trailingAnchor constant:-edgePadding].active = YES;
		[self.conditionDescription.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding].active = YES;
		[self.conditionDescription.heightAnchor constraintEqualToConstant:CONDITION_DESCRIPTION_FONT_SIZE].active = YES;
		[self.conditionDescription.bottomAnchor constraintEqualToAnchor:self.highLowTemperature.topAnchor constant:-2].active = YES;

		self.highLowTemperature.translatesAutoresizingMaskIntoConstraints = NO;
		[self.highLowTemperature.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.temperature.trailingAnchor constant:-edgePadding].active = YES;
		[self.highLowTemperature.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding].active = YES;
		[self.highLowTemperature.topAnchor constraintEqualToAnchor:self.conditionDescription.bottomAnchor constant:2].active = YES;
		[self.highLowTemperature.heightAnchor constraintEqualToConstant:HIGH_LOW_TEMPERATURE_FONT_SIZE].active = YES;
		[self.highLowTemperature.bottomAnchor constraintLessThanOrEqualToAnchor:self.hourlyForecastContainerView.topAnchor constant:-CONTENT_PADDING].active = YES;
		[self.highLowTemperature.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.hourlyForecastContainerView.topAnchor constant:-MAX_CONTENT_PADDING].active = YES;
		[self.highLowTemperature.bottomAnchor constraintEqualToAnchor:self.temperature.bottomAnchor].active = YES;

		self.hourlyForecastContainerView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.hourlyForecastContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding / 2.0].active = YES;
		[self.hourlyForecastContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding / 2.0].active = YES;
		[self.hourlyForecastContainerView.heightAnchor constraintEqualToConstant:HOURLY_FORECAST_HEIGHT].active = YES;
		[self.hourlyForecastContainerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-edgePadding].active = YES;
	} else {
		self.location.translatesAutoresizingMaskIntoConstraints = NO;
		[self.location.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.location.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:edgePadding].active = YES;
		[self.location.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:edgePadding].active = YES;
		[self.location.heightAnchor constraintEqualToConstant:LOCATION_HEIGHT].active = YES;

		self.temperature.translatesAutoresizingMaskIntoConstraints = NO;
		[self.temperature.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.temperature.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding].active = YES;
		[self.temperature.topAnchor constraintEqualToAnchor:self.location.bottomAnchor].active = YES;
		[self.temperature.heightAnchor constraintGreaterThanOrEqualToConstant:TEMPERATURE_FONT_SIZE].active = YES;

		self.conditionImageView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.conditionImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:imageEdgePadding].active = YES;
		[self.conditionImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-imageEdgePadding].active = YES;
		[self.conditionImageView.heightAnchor constraintEqualToConstant:IMAGE_HEIGHT].active = YES;
		[self.conditionImageView.topAnchor constraintGreaterThanOrEqualToAnchor:self.temperature.bottomAnchor constant:-IMAGE_PADDING].active = YES;
		[self.conditionImageView.bottomAnchor constraintEqualToAnchor:self.conditionDescription.topAnchor constant:IMAGE_PADDING].active = YES;

		self.conditionDescription.translatesAutoresizingMaskIntoConstraints = NO;
		[self.conditionDescription.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.conditionDescription.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding].active = YES;
		[self.conditionDescription.heightAnchor constraintEqualToConstant:CONDITION_DESCRIPTION_FONT_SIZE].active = YES;
		[self.conditionDescription.bottomAnchor constraintEqualToAnchor:self.highLowTemperature.topAnchor constant:-2].active = YES;

		self.highLowTemperature.translatesAutoresizingMaskIntoConstraints = NO;
		[self.highLowTemperature.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:edgePadding].active = YES;
		[self.highLowTemperature.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-edgePadding].active = YES;
		[self.highLowTemperature.heightAnchor constraintEqualToConstant:HIGH_LOW_TEMPERATURE_FONT_SIZE].active = YES;
		[self.highLowTemperature.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-edgePadding].active = YES;
	}

	// update the layout of the views
	[self.contentView setNeedsUpdateConstraints];
}

-(void)_setDisplayMode:(HSModernWeatherWidgetDisplayMode)mode {
	_displayMode = mode;
	[self setWidgetOptionValue:@(mode) forKey:DISPLAY_MODE_KEY];
}

-(void)_setEdgePadding:(CGFloat)edgePadding {
	BOOL edgePaddingChanged = (_edgePadding != edgePadding);
	_edgePadding = edgePadding;

	if (edgePaddingChanged)
		[self _setupConstraints:self.displayMode];
}

-(void)dealloc {
	[self.dynamicWeatherBackground release];
	self.dynamicWeatherBackground = nil;

	[self.location release];
	self.location = nil;

	[self.temperature release];
	self.temperature = nil;

	[self.conditionImageView release];
	self.conditionImageView = nil;

	[self.conditionDescription release];
	self.conditionDescription = nil;

	[self.highLowTemperature release];
	self.highLowTemperature = nil;

	[self.hourlyForecastContainerView release];
	self.hourlyForecastContainerView = nil;

	self.hourlyForecastViews = nil;

	[self.dailyForecastContainerView release];
	self.dailyForecastContainerView = nil;

	self.dailyForecastViews = nil;

	[super dealloc];
}
@end
