@protocol WATodayModelObserver;
@class WATodayAutoupdatingLocationModel, WeatherPreferences, WFLocation;

@interface WATodayModel : NSObject // iOS 10 - 13
@property (nonatomic, retain) WAForecastModel *forecastModel; // iOS 10 - 13
+(WATodayAutoupdatingLocationModel *)autoupdatingLocationModelWithPreferences:(WeatherPreferences *)preferences effectiveBundleIdentifier:(id)identifier; // iOS 10 - 13
+(instancetype)modelWithLocation:(WFLocation *)location; // iOS 10 - 13
-(void)addObserver:(id<WATodayModelObserver>)observer; // iOS 10 - 13
-(void)removeObserver:(id<WATodayModelObserver>)observer; // iOS 10 - 13
-(BOOL)executeModelUpdateWithCompletion:(id)completion; // iOS 10 - 13
@end

@interface WATodayAutoupdatingLocationModel : WATodayModel // iOS 10 - 13
@property (nonatomic, assign) BOOL isLocationTrackingEnabled; // iOS 10 -  13
-(void)setLocationServicesActive:(BOOL)active; // iOS 10 - 13
-(BOOL)updateLocationTrackingStatus; // iOS 12 - 13
@end
