@interface WeatherInternalPreferences : NSObject // iOS 10 - 13
+(instancetype)sharedInternalPreferences; // iOS 10 - 13
-(BOOL)isV3Enabled; // iOS 13;
-(id)objectForKey:(id)key; // iOS 10 - 13
@end
