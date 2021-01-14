@interface WFTemperatureUnitObserver : NSObject // iOS 10 - 13
@property (nonatomic, readonly) int temperatureUnit; // iOS 10 - 13
+(instancetype)sharedObserver; // iOS 10 - 13
@end