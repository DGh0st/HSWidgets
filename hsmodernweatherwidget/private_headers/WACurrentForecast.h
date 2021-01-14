@class WFTemperature;

@interface WACurrentForecast : NSObject // iOS 10 - 13
@property (nonatomic, retain) WFTemperature *temperature; // iOS 10 - 13
@property (nonatomic, assign) NSInteger conditionCode; // iOS 10 - 13
@end
