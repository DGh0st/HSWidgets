#import <HSWidgets/HSWidgetViewController.h>

@interface NSExtension // iOS 10 - 12
+(id)extensionWithIdentifier:(id)arg1 error:(id*)arg2; // iOS 10 - 12
@end

@interface WGWidgetInfo : NSObject // iOS 10 - 12
+(id)widgetInfoWithExtension:(id)arg1; // iOS 10 - 12
+(CGFloat)maximumContentHeightForCompactDisplayMode; // iOS 10 - 12
@end

@interface WGWidgetHostingViewController : UIViewController // iOS 10 - 12
-(void)_updateWidgetWithCompletionHandler:(id)arg1; // iOS 10 - 12
-(void)setActiveDisplayMode:(NSInteger)arg1; // iOS 10 - 12
// -(void)_updatePreferredContentSizeWithHeight:(CGFloat)arg1; // iOS 10 - 12
-(void)_requestRemoteViewControllerForSequence:(id)arg1 completionHander:(id)arg2; // iOS 10 - 12
-(void)_connectRemoteViewControllerForReason:(id)arg1 sequence:(id)arg2 completionHandler:(id)arg3; // iOS 10 - 12
-(void)_disconnectRemoteViewControllerForSequence:(id)arg1 completion:(/*^block*/id)arg2 ; // iOS 10 - 12
-(void)_requestInsertionOfRemoteViewAfterViewWillAppearForSequence:(id)arg1 completionHandler:(id)arg2 ; // iOS 10 - 12
-(id)_activeLifeCycleSequence; // iOS 10 - 12
-(void)_initiateNewSequenceIfNecessary; // iOS 10 - 12
-(BOOL)isRemoteViewVisible; // iOS 10 - 12
-(id)host; // iOS 10 - 12
@end

@interface WGWidgetViewController : UIViewController // iOS 10 - 12
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
@end

@interface WGWidgetShortLookView : UIView // iOS 10
@property (assign,getter=isAddWidgetButtonVisible,nonatomic) BOOL addWidgetButtonVisible; // iOS 10
@property (assign,nonatomic) CGFloat cornerRadius; // inherited
-(CGSize)sizeThatFits:(CGSize)arg1; // iOS 10
-(id)initWithFrame:(CGRect)arg1 andCornerRadius:(CGFloat)arg2; // iOS 10
@end

@interface WGWidgetPlatterView : UIView // iOS 11 - 12
@property (assign,getter=isAddWidgetButtonVisible,nonatomic) BOOL addWidgetButtonVisible; // iOS 11 - 12
@property (assign,nonatomic) CGFloat cornerRadius; // inherited
-(CGSize)sizeThatFits:(CGSize)arg1; // iOS 11 - 12
-(id)initWithFrame:(CGRect)arg1 andCornerRadius:(CGFloat)arg2; // iOS 11 - 12
@end

@interface NCMaterialView : UIView // iOS 10
@property (assign,nonatomic) CGFloat cornerRadius;
+(id)materialViewWithStyleOptions:(NSUInteger)arg1 materialSettings:(id)arg2; // iOS 10
@end

@interface NCMaterialSettings : NSObject // iOS 10
-(void)setDefaultValues; // iOS 10
@end

@interface HSTodayWidgetViewController : HSWidgetViewController {
	BOOL _didAddMaterialView;
	BOOL _isExpandedMode;
	BOOL _requestedWidgetUpdate;
	BOOL _isNewlyAdded;
	BOOL _isFirstLoadAfterRespring;
	BOOL _didViewFinishAppearing;
}
@property (nonatomic, retain) WGWidgetViewController *widgetViewController;
@property (nonatomic, retain, readonly) NSString *widgetIdentifier;
-(BOOL)isExpandedMode;
-(void)requestWidgetConnect;
// -(void)requestWidgetUpdate;
-(void)connectRemoteViewController;
@end