@class WFAQIScaleCategory;

@interface City : NSObject // iOS 5 - 13
@property (nonatomic, copy) NSString *name; // iOS 7 - 13
@property (nonatomic, assign) BOOL isLocalWeatherCity; // iOS 7 - 13
@property (nonatomic, retain) WFAQIScaleCategory *airQualityScaleCategory; // iOS 13
@end
