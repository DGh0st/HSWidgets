@class HSWeatherController;

@protocol HSWeatherControllerObserver <NSObject>
@required
-(void)weatherModelUpdatedForController:(HSWeatherController *)weatherController;
@end
