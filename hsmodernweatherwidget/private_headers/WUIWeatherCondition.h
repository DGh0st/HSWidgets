@class City;

@interface WUIWeatherCondition : NSObject // iOS 9 - 13
@property (nonatomic, assign, weak) City *city;
-(void)pause; // iOS 9 - 13
-(void)resume; // iOS 9 - 13
@end