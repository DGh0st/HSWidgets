@protocol WGWidgetHostingViewControllerDelegate, WGWidgetHostingViewControllerHost;
@class WGWidgetDiscoveryController, WGWidgetHostingViewController;

@interface HSTodayWidgetController : NSObject
@property (nonatomic, retain) WGWidgetDiscoveryController *widgetDiscoveryController;
+(instancetype)sharedInstance;
-(NSUInteger)availableWidgetsCount;
-(NSDictionary *)availableWidgetIdentifiersToWidgetInfos;
-(void)removeWidgetWithIdentifier:(NSString *)widgetIdentifier;
-(WGWidgetHostingViewController *)widgetWithIdentifier:(NSString *)identifier delegate:(id<WGWidgetHostingViewControllerDelegate>)delegate host:(id<WGWidgetHostingViewControllerHost>)host;
@end
