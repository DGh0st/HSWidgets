@protocol WGWidgetDiscoveryObserving <NSObject> // iOS 10 - 13
@optional
-(void)widgetDiscoveryController:(id)arg1 widgetWithIdentifier:(id)arg2 shouldBecomeVisibleInGroup:(id)arg3; // iOS 10 - 13
-(void)widgetDiscoveryController:(id)arg1 widgetWithIdentifier:(id)arg2 shouldBecomeHiddenInGroup:(id)arg3; // iOS 10 - 13
-(void)widgetDiscoveryControllerSignificantWidgetsChange:(id)arg1; // iOS 13
-(void)orderOfVisibleWidgetsDidChange:(id)arg1; // iOS 10 - 13
-(void)widgetDiscoveryController:(id)arg1 orderDidChangeForWidgetIdentifiers:(id)arg2; // iOS 13
@end
