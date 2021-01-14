@class CLLocation;

@interface WFLocation : NSObject // iOS 10 - 13
@property (nonatomic, copy) NSString *displayName; // iOS 10 - 13
@property (nonatomic, copy) CLLocation *geoLocation; // iOS 10 - 13
@end
