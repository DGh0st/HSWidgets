#import "WGWidgetHostingViewControllerHost.h"

@interface WGWidgetDiscoveryController : NSObject <WGWidgetHostingViewControllerHost> {
	NSMutableDictionary* _identifiersToWidgetInfos; // iOS 10 - 13
}
-(id)debuggingHandler; // iOS 10 - 13
-(void)beginDiscovery; // iOS 10 - 13
-(id)widgetWithIdentifier:(id)arg1 delegate:(id)arg2 forRequesterWithIdentifier:(id)arg3; // iOS 10 - 13
-(void)registerIdentifierForRefreshEvents:(id)arg1; // iOS 13
-(void)unregisterIdentifierForRefreshEvents:(id)arg1; // iOS 13
-(void)addDiscoveryObserver:(id)arg1; // iOS 10 - 13
-(void)removeDiscoveryObserver:(id)arg1; // iOS 10 - 13
-(BOOL)_setEnabled:(BOOL)arg1 forElementWithIdentifier:(id)arg2; // iOS 10 - 13
-(id)_widgetIDsToWidgets; // iOS 12 - 13
@end
