#import <HSWidgets/HSWidgetViewController.h>

@protocol WGWidgetHostingViewControllerDelegate <NSObject> // iOS 10 - 12
@optional
-(void)remoteViewControllerDidConnectForWidget:(id)arg1; // iOS 10 - 12
-(void)remoteViewControllerDidDisconnectForWidget:(id)arg1; // iOS 10 - 12
-(void)remoteViewControllerViewDidAppearForWidget:(id)arg1; // iOS 10 - 12
-(void)remoteViewControllerViewDidHideForWidget:(id)arg1; // iOS 10 - 12
-(void)brokenViewDidAppearForWidget:(id)arg1; // iOS 10 - 12
-(id)widget:(id)arg1 didUpdatePreferredHeight:(CGFloat)arg2 completion:(id)arg3; // iOS 10 - 12
-(void)contentAvailabilityDidChangeForWidget:(id)arg1; // iOS 10 - 12
-(void)widget:(id)arg1 didChangeLargestSupportedDisplayMode:(NSInteger)arg2; // iOS 10 - 12
-(BOOL)shouldRequestWidgetRemoteViewControllers; // iOS 10 - 12
-(NSInteger)activeLayoutModeForWidget:(id)arg1; // iOS 10 - 12
-(UIEdgeInsets*)marginInsetsForWidget:(id)arg1; // iOS 10 - 12
-(BOOL)managingContainerIsVisibleForWidget:(id)arg1; // iOS 11 - 12
-(CGRect)visibleFrameForWidget:(id)arg1; // iOS 11 - 12
@required
-(CGSize)maxSizeForWidget:(id)arg1 forDisplayMode:(NSInteger)arg2; // iOS 10 - 12
@end

@protocol WGWidgetHostingViewControllerHost <NSObject> // iOS 10 - 12
@optional
-(NSInteger)userSpecifiedDisplayModeForWidget:(id)arg1; // iOS 10 - 12
-(void)widget:(id)arg1 didChangeUserSpecifiedDisplayMode:(NSInteger)arg2; // iOS 10 - 12
-(NSInteger)largestAvailableDisplayModeForWidget:(id)arg1; // iOS 10 - 12
-(void)widget:(id)arg1 didChangeLargestAvailableDisplayMode:(NSInteger)arg2; // iOS 10 - 12
-(void)widget:(id)arg1 didEncounterProblematicSnapshotAtURL:(id)arg2; // iOS 10 - 12
-(void)widget:(id)arg1 didRemoveSnapshotAtURL:(id)arg2; // iOS 11 - 12
-(BOOL)shouldPurgeArchivedSnapshotsForWidget:(id)arg1; // iOS 10 - 12
-(BOOL)shouldPurgeNonCAMLSnapshotsForWidget:(id)arg1; // iOS 11 - 12
-(BOOL)shouldPurgeNonASTCSnapshotsForWidget:(id)arg1; // iOS 11 - 12
-(BOOL)shouldRemoveSnapshotWhenNotVisibleForWidget:(id)arg1; // iOS 11 - 12
@end

@protocol WGWidgetExtensionVisibilityProviding <NSObject> // iOS 10 - 12
@required
-(BOOL)isWidgetExtensionVisible:(id)arg1; // iOS 10 - 12
@end

@interface NSExtension // iOS 10 - 12
+(id)extensionWithIdentifier:(id)arg1 error:(id*)arg2; // iOS 10 - 12
@end

@interface WGWidgetInfo : NSObject // iOS 10 - 12
+(id)widgetInfoWithExtension:(id)arg1; // iOS 10 - 12
+(CGFloat)maximumContentHeightForCompactDisplayMode; // iOS 10 - 12
@end

@interface WGWidgetHostingViewController : UIViewController // iOS 10 - 12
-(id)initWithWidgetInfo:(id)arg1 delegate:(id)arg2 host:(id)arg3; // iOS 10 - 12
// -(void)_updateWidgetWithCompletionHandler:(id)arg1; // iOS 10 - 12
// -(void)setActiveDisplayMode:(NSInteger)arg1; // iOS 10 - 12
// -(void)_updatePreferredContentSizeWithHeight:(CGFloat)arg1; // iOS 10 - 12
-(void)_requestRemoteViewControllerForSequence:(id)arg1 completionHander:(id)arg2; // iOS 10 - 12
-(void)_connectRemoteViewControllerForReason:(id)arg1 sequence:(id)arg2 completionHandler:(id)arg3; // iOS 10 - 12
-(void)_requestInsertionOfRemoteViewAfterViewWillAppearForSequence:(id)arg1 completionHandler:(id)arg2 ; // iOS 10 - 12
-(void)_disconnectRemoteViewControllerForSequence:(id)arg1 completion:(id)arg2; // iOS 10 - 12
-(id)_activeLifeCycleSequence; // iOS 10 - 12
-(void)_initiateNewSequenceIfNecessary; // iOS 10 - 12
-(id)host; // iOS 10 - 12
-(id)delegate; // iOS 10 - 12
-(void)_removeAllSnapshotsForActiveDisplayMode; // iOS 10
-(void)_removeAllSnapshotFilesForActiveDisplayMode; // iOS 11 - 12
// -(void)_performUpdateForSequence:(id)arg1 withCompletionHandler:(id)arg2; // iOS 10 - 12
-(void)_setLargestAvailableDisplayMode:(NSInteger)arg1;
@end

/*@interface WGWidgetViewController : UIViewController // iOS 10 - 12
@property (nonatomic,retain) WGWidgetHostingViewController *widgetHost; // iOS 10 - 12
-(id)initWithWidgetInfo:(id)arg1; // iOS 10 - 12
-(void)setDelegate:(id)arg1; // iOS 10 - 12
-(id)delegate; // iOS 10 - 12
-(void)remoteViewControllerDidConnectForWidget:(id)arg1; // iOS 10 - 12
-(void)remoteViewControllerViewDidAppearForWidget:(id)arg1; // iOS 10 - 12
-(CGSize)maxSizeForWidget:(id)arg1 forDisplayMode:(NSInteger)arg2; // iOS 10 - 12
-(NSInteger)userSpecifiedDisplayModeForWidget:(id)arg1; // iOS 10 - 12
-(BOOL)isWidgetExtensionVisible:(id)arg1; // iOS 10 - 12
-(id)_shortLookViewLoadingIfNecessary:(BOOL)arg1; // iOS 10
-(id)_platterViewLoadingIfNecessary:(BOOL)arg1; // iOS 11 - 12
-(NSInteger)largestAvailableDisplayModeForWidget:(id)arg1; // iOS 10 - 12
// -(CGSize)sizeForChildContentContainer:(id)arg1 withParentContainerSize:(CGSize)arg2; // iOS 10 - 12
@end*/

@interface WGWidgetShortLookView : UIView // iOS 10
-(id)initWithFrame:(CGRect)arg1 andCornerRadius:(CGFloat)arg2; // iOS 10
-(void)setWidgetHost:(id)arg1; // iOS 10
-(WGWidgetHostingViewController *)widgetHost; // iOS 10
-(void)setShowMoreButtonVisible:(BOOL)arg1; // iOS 10
@end

@interface WGWidgetPlatterView : UIView // iOS 11 - 12
-(id)initWithFrame:(CGRect)arg1 andCornerRadius:(CGFloat)arg2; // iOS 11 - 12
-(void)setWidgetHost:(id)arg1; // iOS 11 - 12
-(WGWidgetHostingViewController *)widgetHost; // iOS 11 - 12
-(void)setShowMoreButtonVisible:(BOOL)arg1; // iOS 11 - 12
@end

@interface NCMaterialSettings : NSObject // iOS 10
-(void)setDefaultValues; // iOS 10
@end

@interface MTMaterialView : UIView // iOS 11 - 12
+(id)materialViewWithRecipe:(NSInteger)arg1 options:(NSUInteger)arg2; // iOS 11 - 12
-(void)_setCornerRadius:(CGFloat)arg1; // iOS 11 - 12
-(void)setFinalRecipe:(NSInteger)arg1 options:(NSUInteger)arg2 ; // iOS 11 - 12
@end

@interface HSTodayWidgetViewController : HSWidgetViewController <WGWidgetHostingViewControllerDelegate, WGWidgetHostingViewControllerHost, WGWidgetExtensionVisibilityProviding> {
	BOOL _isExpandedMode;
	BOOL _requestedWidgetUpdate;
	BOOL _shouldRequestWidgetRemoteViewController;
}
@property (nonatomic, retain) UIView *widgetView;
@property (nonatomic, retain) WGWidgetHostingViewController *hostingViewController;
@property (nonatomic, retain, readonly) NSString *widgetIdentifier;
-(void)requestWidgetConnect;
// -(void)requestWidgetUpdate;
-(void)connectRemoteViewController;
-(void)disconnectRemoteViewControllerWithCompletion:(void(^)())completion;
@end