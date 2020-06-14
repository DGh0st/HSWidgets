@interface SBUIPreciseClockTimer : NSObject // iOS 12 - 13
+(id)sharedInstance; // iOS 12 - 13
+(id)now; // iOS 12 - 13
-(NSNumber *)startMinuteUpdatesWithHandler:(id)arg1; // iOS 12 - 13
-(void)stopMinuteUpdatesForToken:(NSNumber *)arg1; // iOS 12 - 13
@end
