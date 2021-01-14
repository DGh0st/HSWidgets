@class WFTemperature;

@interface WAHourlyForecast : NSObject // iOS 10 - 13
@property (nonatomic, retain) WFTemperature *temperature; // iOS 10 - 13
@property (nonatomic, assign) NSInteger conditionCode; // iOS 10 - 13
@property (nonatomic, copy) NSString *time; // iOS 10 - 13
@property (nonatomic, assign) NSInteger hourIndex; // iOS 10 - 13
@end
