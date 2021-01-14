@class City, WUIGradientLayer, WUIWeatherCondition;

@interface WUIDynamicWeatherBackground : UIView // iOS 9 - 13
@property (nonatomic, retain) WUIGradientLayer *gradientLayer; // iOS 9 - 13
@property (nonatomic, retain) WUIWeatherCondition *condition; // iOS 9 - 13
-(void)setCity:(City *)city; // iOS 9 - 13
@end