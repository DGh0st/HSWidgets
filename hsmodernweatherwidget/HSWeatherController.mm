#import "HSWeatherController.h"
#import "HSWeatherControllerObserver.h"
#import "City.h"
#import "WACurrentForecast.h"
#import "WADayForecast.h"
#import "WAForecastModel.h"
#import "WAHourlyForecast.h"
#import "WATodayModel.h"
#import "Weather-Externs.h"
#import "WeatherInternalPreferences.h"
#import "WeatherPreferences.h"
#import "WFAQIScaleCategory.h"
#import "WFLocation.h"
#import "WFTemperature.h"
#import "WFTemperatureFormatter.h"
#import "WFTemperatureUnitObserver.h"

#import <CoreLocation/CLLocation.h>
#import <CoreLocation/CLLocationManager.h>

#define FAKE_PAD_WEATHER @"FakePadWeather"
#define FAKE_PAD_WEATHER_LATITUDE @"FakePadWeatherLatitude"
#define FAKE_PAD_WEATHER_LONGITUDE @"FakePadWeatherLongitude"
#define FAKE_PAD_WEATHER_DISPLAY_NAME @"FakePadWeatherDisplayName"
#define FAKE_PAD_WEATHER_CONDITION_TEMPERATURE @"FakePadWeatherConditionTemperature"
#define FAKE_PAD_WEATHER_CONDITION_DESCRIPTION @"FakePadWeatherConditionDescription"
#define FAKE_PAD_WEATHER_CONDITION @"FakePadWeatherCondition"
#define FAKE_LATITUDE 37.3333702
#define FAKE_LONGITUDE -122.029488

#define WEATHER_UPDATE_TIME_INTERVAL 300
#define WEATHER_UPDATE_TIME_THRESHOLD 60

NSString *const HSWeatherFakeDisplayName = @"Cupertino, CA";
NSString *const HSWeatherFakeDescription = @"Sunny";
NSString *const HSWeatherFakeTemperature = @"--";
NSString *const HSWeatherFakeHighLowDescription = @"H:-- L:--";

NSString *const HSWeatherHourlyForecastIndexKey = @"Index";
NSString *const HSWeatherHourlyForecastTimeKey = @"Time";
NSString *const HSWeatherHourlyForecastConditionImageKey = @"Image";
NSString *const HSWeatherHourlyForecastTemperatureKey = @"Temperature";

NSString *const HSWeatherDailyForecastIndexKey = @"Index";
NSString *const HSWeatherDailyForecastHighTemperatureKey = @"HighTemperature";
NSString *const HSWeatherDailyForecastLowTemperatureKey = @"LowTemperature";
NSString *const HSWeatherDailyForecastConditionImageKey = @"Image";
NSString *const HSWeatherDailyForecastDayOfWeekKey = @"DayOfWeek";

@implementation HSWeatherController
+(instancetype)sharedInstance {
	static HSWeatherController *_sharedController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedController = [[self alloc] init];
	});
	return _sharedController;
}

+(WFTemperatureFormatter *)sharedTemperatureFormatter {
	static WFTemperatureFormatter *_temperatureFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_temperatureFormatter = [[WFTemperatureFormatter alloc] init];
	});
	return _temperatureFormatter;
}

+(NSString *)condensedTimeFromFourDigitTime:(NSString *)fourDigitTime {
	NSArray<NSString *> *components = [fourDigitTime componentsSeparatedByString:@":"];
	if (components.count < 2)
		return fourDigitTime;

	NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
	dateComponents.hour = [components[0] integerValue];
	dateComponents.minute = [components[1] integerValue];

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];

	NSString *condensedTime = [dateFormatter stringFromDate:[[NSCalendar currentCalendar] dateFromComponents:dateComponents]];

	[dateComponents release];
	[dateFormatter release];

	return condensedTime;
}

+(NSString *)stringFromWeekDay:(NSUInteger)day {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEE" options:0 locale:[NSLocale currentLocale]];

	NSArray<NSString *> *weekdaySymbols = [dateFormatter weekdaySymbols];
	NSString *weekDay = weekdaySymbols.count >= day ? weekdaySymbols[day - 1] : @"";

	[dateFormatter release];

	return weekDay;
}

-(instancetype)init {
	self = [super init];
	if (self != nil) {
		self.todayModel = nil;
		[self _setupWeatherModel];

		self.updateTimer = nil;
		self.lastUpdateTime = [NSDate date];

		self.observers = [NSMutableArray array];

		// TODO: find out if this notification is ever posted or if updating location tracking is enough
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_cityDidUpdate:) name:kCityNotificationNameDidUpdate object:nil];
	}
	return self;
}

-(NSString *)locationName {
	if ([self _shouldFakeWeather]) {
		return [[WeatherInternalPreferences sharedInternalPreferences] objectForKey:FAKE_PAD_WEATHER_DISPLAY_NAME] ?: HSWeatherFakeDisplayName;
	} else {
		NSString *name = self.todayModel.forecastModel.city.name;
		if (name)
			return name;
		return self.todayModel.forecastModel.location.displayName ?: HSWeatherFakeDisplayName;
	}
}

-(NSString *)temperature {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[WFTemperatureUnitObserver sharedObserver].temperatureUnit];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:!WAIsChinaSKUAndSimplifiedChinese()];

	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	id fakeConditionTemperature = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION_TEMPERATURE];

	NSString *temperatureString = nil;
	if ([self _shouldFakeWeather] && fakeConditionTemperature != nil)
		temperatureString = [temperatureFormatter stringForObjectValue:fakeConditionTemperature];
	else
		temperatureString = [temperatureFormatter stringForObjectValue:self.todayModel.forecastModel.currentConditions.temperature];
	return temperatureString ?: HSWeatherFakeTemperature;
}

-(UIImage *)conditionsImage {
	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	if ([self _shouldFakeWeather]) {
		NSNumber *condition = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION];
		if (condition != nil)
			return WAImageForLegacyConditionCode([condition intValue]);
	}

	if (self.todayModel.forecastModel.currentConditions != nil)
		return WAImageForLegacyConditionCode(self.todayModel.forecastModel.currentConditions.conditionCode);
	return nil;
}

-(NSString *)conditionsDescription {
	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	if ([self _shouldFakeWeather])
		return [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION_DESCRIPTION] ?: HSWeatherFakeDescription;

	if ([internalPreferences respondsToSelector:@selector(isV3Enabled)] && [internalPreferences isV3Enabled]) {
		WFAQIScaleCategory *airQualityScaleCategory = self.todayModel.forecastModel.city.airQualityScaleCategory;
		NSString *longDescription = airQualityScaleCategory.longDescription;		
		if (longDescription != nil && airQualityScaleCategory.categoryIndex > airQualityScaleCategory.warningLevel)
			return longDescription;
	}

	if (self.todayModel.forecastModel.currentConditions != nil)
		return WAConditionsLineStringFromCurrentForecasts(self.todayModel.forecastModel.currentConditions) ?: HSWeatherFakeDescription;
	return HSWeatherFakeDescription;
}

-(NSString *)highLowDescription {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[WFTemperatureUnitObserver sharedObserver].temperatureUnit];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:!WAIsChinaSKUAndSimplifiedChinese()];

	NSString *highTemperature = @"--";
	NSString *lowTemperature = @"--";

	WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
	id fakeConditionTemperature = [internalPreferences objectForKey:FAKE_PAD_WEATHER_CONDITION_TEMPERATURE];
	if ([self _shouldFakeWeather] && fakeConditionTemperature != nil) {
		highTemperature = [temperatureFormatter stringForObjectValue:fakeConditionTemperature];
		lowTemperature = highTemperature;
	} else {
		NSArray *dailyForecasts = self.todayModel.forecastModel.dailyForecasts;
		if (dailyForecasts != nil && dailyForecasts.count > 0) {
			WADayForecast *todayForecast = dailyForecasts.firstObject;
			highTemperature = [temperatureFormatter stringForObjectValue:todayForecast.high];
			lowTemperature = [temperatureFormatter stringForObjectValue:todayForecast.low];
		}
	}

	return [NSString stringWithFormat:@"H:%@ L:%@", highTemperature, lowTemperature];
}

-(NSArray<NSDictionary *> *)hourlyForecasts {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[WFTemperatureUnitObserver sharedObserver].temperatureUnit];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:!WAIsChinaSKUAndSimplifiedChinese()];

	NSArray *hourlyForecasts = self.todayModel.forecastModel.hourlyForecasts;
	NSMutableArray *forecastsInfo = [NSMutableArray arrayWithCapacity:hourlyForecasts.count];
	for (WAHourlyForecast *hourlyForecast in hourlyForecasts) {
		[forecastsInfo addObject:@{
			HSWeatherHourlyForecastIndexKey : @(hourlyForecast.hourIndex),
			HSWeatherHourlyForecastTimeKey : ([[self class] condensedTimeFromFourDigitTime:hourlyForecast.time] ?: @""),
			HSWeatherHourlyForecastConditionImageKey : WAImageForLegacyConditionCode(hourlyForecast.conditionCode), // hope this never fails
			HSWeatherHourlyForecastTemperatureKey : ([temperatureFormatter stringForObjectValue:hourlyForecast.temperature] ?: HSWeatherFakeTemperature)
		}];
	}

	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:HSWeatherHourlyForecastIndexKey ascending:YES];
	[forecastsInfo sortUsingDescriptors:@[sort]];

	return forecastsInfo;
}

-(NSArray<NSDictionary *> *)dailyForecasts {
	WFTemperatureFormatter *temperatureFormatter = [[self class] sharedTemperatureFormatter];
	[temperatureFormatter setOutputUnit:[WFTemperatureUnitObserver sharedObserver].temperatureUnit];
	if ([temperatureFormatter respondsToSelector:@selector(setIncludeDegreeSymbol:)])
		[temperatureFormatter setIncludeDegreeSymbol:!WAIsChinaSKUAndSimplifiedChinese()];

	NSArray *dailyForecasts = self.todayModel.forecastModel.dailyForecasts;
	NSMutableArray *forecastsInfo = [NSMutableArray arrayWithCapacity:dailyForecasts.count];
	for (WADayForecast *dayForecast in dailyForecasts) {
		[forecastsInfo addObject:@{
			HSWeatherDailyForecastIndexKey : @(dayForecast.dayNumber),
			HSWeatherDailyForecastHighTemperatureKey : [temperatureFormatter stringForObjectValue:dayForecast.high],
			HSWeatherDailyForecastLowTemperatureKey : [temperatureFormatter stringForObjectValue:dayForecast.low],
			HSWeatherDailyForecastConditionImageKey : WAImageForLegacyConditionCode(dayForecast.icon), // hope this never fails
			HSWeatherDailyForecastDayOfWeekKey : [[self class] stringFromWeekDay:dayForecast.dayOfWeek]
		}];
	}

	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:HSWeatherDailyForecastIndexKey ascending:YES];
	[forecastsInfo sortUsingDescriptors:@[sort]];

	return forecastsInfo;
}

-(void)startUpdateTimer {
	if (self.updateTimer == nil && self.observers.count > 0) {
		NSTimeInterval updateTimeInterval = WEATHER_UPDATE_TIME_INTERVAL + [self.lastUpdateTime timeIntervalSinceNow];
		if (updateTimeInterval > 0) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateTimeInterval target:self selector:@selector(requestModelUpdate) userInfo:nil repeats:NO];
			self.updateTimer.tolerance = WEATHER_UPDATE_TIME_THRESHOLD;
		} else {
			[self requestModelUpdate];
		}
	}
}

-(void)stopUpdateTimer {
	if (self.updateTimer != nil) {
		[self.updateTimer invalidate];
		self.updateTimer = nil;
	}
}

-(void)requestModelUpdate {
	[self stopUpdateTimer];

	[self _updateLocationTracking];
	__block typeof(self) widgetController = self;
	[self.todayModel executeModelUpdateWithCompletion:^{
		[widgetController _todayModelWasUpdated];
	}];

	self.lastUpdateTime = [NSDate date];
	[self startUpdateTimer];
}

-(void)addObserver:(id<HSWeatherControllerObserver>)observer {
	[self.observers addObject:observer];
}

-(void)removeObserver:(id<HSWeatherControllerObserver>)observer {
	[self.observers removeObject:observer];
}

-(City *)currentCity {
	return self.todayModel.forecastModel.city;
}

-(void)_todayModelWasUpdated {
	for (id<HSWeatherControllerObserver> observer in self.observers)
		[observer weatherModelUpdatedForController:self];
}

-(void)_setupWeatherModel {
	if ([self _shouldFakeWeather]) {
		WeatherInternalPreferences *internalPreferences = [WeatherInternalPreferences sharedInternalPreferences];
		NSNumber *fakeLatitude = [internalPreferences objectForKey:FAKE_PAD_WEATHER_LATITUDE];
		NSNumber *fakeLongitude = [internalPreferences objectForKey:FAKE_PAD_WEATHER_LONGITUDE];
		
		CGFloat latitude;
		CGFloat longitude;
		if (fakeLatitude != nil && fakeLongitude != nil) {
			latitude = [fakeLatitude floatValue];
			longitude = [fakeLongitude floatValue];
		} else {
			latitude = FAKE_LATITUDE;
			longitude = FAKE_LONGITUDE;
		}

		CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
		WFLocation *weatherLocation = [[WFLocation alloc] init];
		[weatherLocation setGeoLocation:location];

		NSString *displayName = [internalPreferences objectForKey:FAKE_PAD_WEATHER_DISPLAY_NAME] ?: HSWeatherFakeDisplayName;
		[weatherLocation setDisplayName:displayName];

		self.todayModel = [WATodayModel modelWithLocation:weatherLocation];
		[self requestModelUpdate];

		[weatherLocation release];
		[location release];
	} else {
		WeatherPreferences *preferences = [[WeatherPreferences alloc] init];
		WATodayAutoupdatingLocationModel *todayModel = [WATodayModel autoupdatingLocationModelWithPreferences:preferences effectiveBundleIdentifier:nil];
		[todayModel setLocationServicesActive:[self _locationServicesActive]];
		self.todayModel = todayModel;
		[self requestModelUpdate];

		[preferences release];
	}

	[self.todayModel addObserver:self];
}

-(BOOL)_shouldFakeWeather {
	return [[[WeatherInternalPreferences sharedInternalPreferences] objectForKey:FAKE_PAD_WEATHER] boolValue];
}

-(BOOL)_locationServicesActive {
	return YES;
}

-(void)_updateLocationTracking {
	if ([self.todayModel isKindOfClass:[WATodayAutoupdatingLocationModel class]]) {
		WATodayAutoupdatingLocationModel *autoUpdatingTodayModel = (WATodayAutoupdatingLocationModel *)self.todayModel;
		if ([autoUpdatingTodayModel respondsToSelector:@selector(updateLocationTrackingStatus)]) {
			[autoUpdatingTodayModel updateLocationTrackingStatus];
		} else {
			autoUpdatingTodayModel.isLocationTrackingEnabled = [CLLocationManager locationServicesEnabled];
		}
	}
}

-(void)todayModelWantsUpdate:(WATodayModel *)model {
	[self requestModelUpdate];
}

-(void)todayModel:(WATodayModel *)model forecastWasUpdated:(id)forecast {
	[self _todayModelWasUpdated];
}

-(void)_cityDidUpdate:(id)object {
	[self requestModelUpdate];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kCityNotificationNameDidUpdate object:nil];

	[self stopUpdateTimer];

	if (self.todayModel != nil) {
		[self.todayModel removeObserver:self];
		self.todayModel = nil;
	}

	self.observers = nil;

	[super dealloc];
}
@end