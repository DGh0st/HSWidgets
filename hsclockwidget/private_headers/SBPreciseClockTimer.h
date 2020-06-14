@interface SBPreciseClockTimer : NSObject // iOS 9 - 11
+(id)sharedInstance; // iOS 9 - 11
+(id)now; // iOS 9 - 11
-(NSNumber *)startMinuteUpdatesWithHandler:(id)arg1; // iOS 9 - 11
-(void)stopMinuteUpdatesForToken:(NSNumber *)arg1; // iOS 9 - 11
@end
