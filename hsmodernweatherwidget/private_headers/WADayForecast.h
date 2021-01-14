@class WFTemperature;

@interface WADayForecast : NSObject // iOS 10 - 13
@property (nonatomic, copy) WFTemperature *high; // iOS 10 - 13
@property (nonatomic, copy) WFTemperature *low; // iOS 10 - 13
@property (nonatomic, assign) NSUInteger icon; // iOS 10 - 13
@property (nonatomic, assign) NSUInteger dayOfWeek; // iOS 10 - 13
@property (nonatomic, assign) NSUInteger dayNumber; // iOS 10 - 13
@end
