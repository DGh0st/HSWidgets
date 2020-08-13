@protocol WGWidgetHostingViewControllerHost;
@class WGWidgetInfo;

@interface WGWidgetHostingViewController : UIViewController // iOS 10 - 13
@property (nonatomic, readonly) WGWidgetInfo *widgetInfo; // iOS 10 - 13
@property (assign, nonatomic, weak) id<WGWidgetHostingViewControllerDelegate> delegate; // iOS 10 - 13
@property (assign, nonatomic, weak) id<WGWidgetHostingViewControllerHost> host; // iOS 10 - 13
@property (assign, nonatomic) NSInteger userSpecifiedDisplayMode; // iOS 10 - 13
// @property (nonatomic,readonly) NSInteger activeDisplayMode; // iOS 10 - 13
-(instancetype)initWithWidgetInfo:(id)arg1 delegate:(id)arg2 host:(id)arg3; // iOS 10 - 13
// -(void)_updateWidgetWithCompletionHandler:(id)arg1; // iOS 10 - 13
// -(void)setActiveDisplayMode:(NSInteger)arg1; // iOS 10 - 13
// -(void)_updatePreferredContentSizeWithHeight:(CGFloat)arg1; // iOS 10 - 13
// -(void)_requestRemoteViewControllerForSequence:(id)arg1 completionHander:(id)arg2; // iOS 10 - 13
// -(void)_connectRemoteViewControllerForReason:(id)arg1 sequence:(id)arg2 completionHandler:(id)arg3; // iOS 10 - 13
// -(void)_requestInsertionOfRemoteViewAfterViewWillAppearForSequence:(id)arg1 completionHandler:(id)arg2 ; // iOS 10 - 13
// -(void)_disconnectRemoteViewControllerForSequence:(id)arg1 completion:(id)arg2; // iOS 10 - 13
// -(id)_activeLifeCycleSequence; // iOS 10 - 13
// -(void)_initiateNewSequenceIfNecessary; // iOS 10 - 13
// -(void)_abortActiveSequence; // iOS 10 - 13
// -(id)host; // iOS 10 - 13
// -(id)delegate; // iOS 10 - 13
-(void)_removeAllSnapshotsForActiveDisplayMode; // iOS 10
-(void)_removeAllSnapshotFilesForActiveDisplayMode; // iOS 11 - 13
// -(void)_performUpdateForSequence:(id)arg1 withCompletionHandler:(id)arg2; // iOS 10 - 13
-(void)_setLargestAvailableDisplayMode:(NSInteger)arg1; // iOS 10 - 13
-(void)managingContainerWillAppear:(id)arg1; // iOS 11 - 13
-(void)managingContainerDidDisappear:(id)arg1; // iOS 11 - 13
-(void)setDisconnectsImmediately:(BOOL)arg1; // iOS 10 - 13
-(id)_cancelTouches; // iOS 10 - 13
@end
