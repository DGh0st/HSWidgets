@class WATodayModel;

@protocol WATodayModelObserver <NSObject> // iOS 10 - 13
@required
-(void)todayModelWantsUpdate:(WATodayModel *)model; // iOS 10 - 13
-(void)todayModel:(WATodayModel *)model forecastWasUpdated:(id)forecast; // iOS 10 - 13
@end
