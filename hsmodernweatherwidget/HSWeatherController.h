#import "WATodayModelObserver.h"

@class City, WATodayModel;
@protocol HSWeatherControllerObserver;

extern NSString *const HSWeatherFakeDisplayName;
extern NSString *const HSWeatherFakeDescription;
extern NSString *const HSWeatherFakeTemperature;
extern NSString *const HSWeatherFakeHighLowDescription;

extern NSString *const HSWeatherHourlyForecastIndexKey;
extern NSString *const HSWeatherHourlyForecastTimeKey;
extern NSString *const HSWeatherHourlyForecastConditionImageKey;
extern NSString *const HSWeatherHourlyForecastTemperatureKey;

extern NSString *const HSWeatherDailyForecastIndexKey;
extern NSString *const HSWeatherDailyForecastHighTemperatureKey;
extern NSString *const HSWeatherDailyForecastLowTemperatureKey;
extern NSString *const HSWeatherDailyForecastConditionImageKey;
extern NSString *const HSWeatherDailyForecastDayOfWeekKey;

@interface HSWeatherController : NSObject <WATodayModelObserver>
@property (nonatomic, retain) WATodayModel *todayModel;
@property (nonatomic, retain) NSTimer *updateTimer;
@property (nonatomic, retain) NSDate *lastUpdateTime;
@property (nonatomic, retain) NSMutableArray *observers;
+(instancetype)sharedInstance;
-(NSString *)locationName;
-(NSString *)temperature;
-(UIImage *)conditionsImage;
-(NSString *)conditionsDescription;
-(NSString *)highLowDescription;
-(NSArray<NSDictionary *> *)hourlyForecasts;
-(NSArray<NSDictionary *> *)dailyForecasts;
-(void)startUpdateTimer;
-(void)stopUpdateTimer;
-(void)requestModelUpdate;
-(void)addObserver:(id<HSWeatherControllerObserver>)observer;
-(void)removeObserver:(id<HSWeatherControllerObserver>)observer;
-(City *)currentCity;
@end
