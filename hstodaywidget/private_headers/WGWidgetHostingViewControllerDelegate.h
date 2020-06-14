@protocol WGWidgetHostingViewControllerDelegate <NSObject> // iOS 10 - 13
@optional
-(void)remoteViewControllerDidConnectForWidget:(id)arg1; // iOS 10 - 13
-(void)remoteViewControllerDidDisconnectForWidget:(id)arg1; // iOS 10 - 13
-(void)remoteViewControllerViewDidAppearForWidget:(id)arg1; // iOS 10 - 13
-(void)remoteViewControllerViewDidHideForWidget:(id)arg1; // iOS 10 - 13
-(void)brokenViewDidAppearForWidget:(id)arg1; // iOS 10 - 13
-(id)widget:(id)arg1 didUpdatePreferredHeight:(CGFloat)arg2 completion:(id)arg3; // iOS 10 - 13
-(void)contentAvailabilityDidChangeForWidget:(id)arg1; // iOS 10 - 13
-(void)widget:(id)arg1 didChangeLargestSupportedDisplayMode:(NSInteger)arg2; // iOS 10 - 13
-(BOOL)shouldRequestWidgetRemoteViewControllers; // iOS 10 - 13
-(NSInteger)activeLayoutModeForWidget:(id)arg1; // iOS 10 - 13
-(UIEdgeInsets*)marginInsetsForWidget:(id)arg1; // iOS 10 - 13
-(UIEdgeInsets*)layoutMarginForWidget:(id)arg1; // iOS 13
-(BOOL)managingContainerIsVisibleForWidget:(id)arg1; // iOS 11 - 13
-(CGRect)visibleFrameForWidget:(id)arg1; // iOS 11 - 13
@required
-(CGSize)maxSizeForWidget:(id)arg1 forDisplayMode:(NSInteger)arg2; // iOS 10 - 13
-(void)registerWidgetForRefreshEvents:(id)arg1; // iOS 13
-(void)unregisterWidgetForRefreshEvents:(id)arg1; // iOS 13
@end
