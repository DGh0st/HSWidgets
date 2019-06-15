#import "HSTodayWidgetViewController.h"
#import <HSWidgets/HSAdditionalOptionsTableViewController.h>

#define kNumRows 2 // today widgets take atleast 2 rows
#define kExpandedNumRows 3 // expanded display mode takes up 3 rows
#define kDisplayName @"Today Widgets"
#define kIconImageName @"HSCustom"
#define kReupdateWaitTime 3.0 // wait for 3 seconds before reattempting to update
// #define kUpdateAfterRespringWaitTime 1.0 // wait for 1 second before attempting to update after respring
#define kHeaderHeight 36 // height of the header bar
#define kScreenPadding 16 // padding on the sides of the width

// display modes
#define kDisplayModeCompact 0
#define kDisplayModeExpanded 1

@interface WGWidgetInfo (Private) // iOS 10 - 12
@property (setter=_setDisplayName:, nonatomic, copy) NSString *displayName; // iOS 10 - 12
@property (nonatomic,copy,readonly) NSString *widgetIdentifier; // iOS 10 - 12
-(UIImage *)icon; // iOS 10 - 11
-(id)_icon; // iOS 12
@end

@interface WGWidgetDiscoveryController : NSObject {
	NSMutableDictionary* _identifiersToWidgetInfos; // iOS 10 - 12
}
@end

static WGWidgetDiscoveryController *widgetDiscoveryController = nil;

// for some reason SpringBoard -> SBWidgetController -> WGWidgetDiscoveryController doesn't work on some iOS
%hook WGWidgetDiscoveryController
-(id)init {
	self = %orig;
	if (self != nil)
		widgetDiscoveryController = self;
	return self;
}
%end

@interface SBIconListModel // iOS 4 - 12
@property (nonatomic, retain) NSMutableArray *widgetViewControllers; // added by HSWidgets
@end

%hook SBRootIconListView
%new
-(BOOL)containsWidget:(NSString *)identifier {
	NSArray *widgetViewControllers = MSHookIvar<SBIconListModel *>(self, "_model").widgetViewControllers;
	if (widgetViewControllers != nil) {
		for (HSWidgetViewController *widgetViewController in widgetViewControllers) {
			if ([widgetViewController isKindOfClass:%c(HSTodayWidgetViewController)]) {
				NSString *widgetIdentifier = [(HSTodayWidgetViewController *)widgetViewController widgetIdentifier];
				if ([identifier isEqualToString:widgetIdentifier])
					return YES;
			}
		}
	}
	return NO;
}
%end

@interface SBUIIconForceTouchController // iOS 10 - 12
+(BOOL)_isPeekingOrShowing; // iOS 10 - 12
+(BOOL)_isWidgetVisible:(id)arg1; // iOS 10 - 12
@end

@interface SBRootIconListView // iOS 7 - 12
-(BOOL)containsWidget:(NSString *)identifier;
@end

@interface SBIconController // IOS 3 - 12
+(id)sharedInstance; // iOS 3 - 12
-(BOOL)isScrolling; // iOS 3 - 12
-(id)currentRootIconList; // iOS 4 - 12
@end

%hook SBUIIconForceTouchController
+(BOOL)_isWidgetVisible:(id)arg1 {
	BOOL result = %orig;
	if (!result) {
		SBIconController *iconController = [%c(SBIconController) sharedInstance];
		id currentRootIconListView = [iconController currentRootIconList];
		if (![%c(SBUIIconForceTouchController) _isPeekingOrShowing] && ![iconController isScrolling] && [currentRootIconListView isKindOfClass:%c(SBRootIconListView)] && [(SBRootIconListView *)currentRootIconListView containsWidget:arg1])
			result = YES; // to fix widget not launching URLs that open the application
	}
	return result;
}
%end

@interface HSTodayWidgetsListViewController : HSAdditionalOptionsTableViewController {
	NSArray *_widgetInfos;
}
@property (nonatomic, retain) NSString *selectedWidgetIdentifier;
@end

@implementation HSTodayWidgetsListViewController
-(id)initWithDelegate:(id)delegate withWidgetsOptionsToExclude:(NSArray *)optionsToExclude {
	self = [super initWithDelegate:delegate withWidgetsOptionsToExclude:optionsToExclude];
	if (self != nil) {
		if (widgetDiscoveryController != nil) {
			NSMutableDictionary *_identifiersToWidgetInfos = [[widgetDiscoveryController valueForKey:@"_identifiersToWidgetInfos"] mutableCopy];

			for (NSDictionary *option in optionsToExclude)
				[_identifiersToWidgetInfos removeObjectForKey:option[@"widgetIdentifier"]];

			NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
			if (_identifiersToWidgetInfos != nil)
				_widgetInfos = [[[_identifiersToWidgetInfos allValues] sortedArrayUsingDescriptors:@[sort]] retain];
			else
				_widgetInfos = [[NSArray alloc] init];

			[_identifiersToWidgetInfos release];
		} else {
			_widgetInfos = [[NSArray alloc] init];
		}

		self.selectedWidgetIdentifier = nil;
	}
	return self;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelWidget)];
	self.navigationItem.rightBarButtonItems = @[cancelButton];
	[cancelButton release];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_widgetInfos count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *reusableCellIdentifier = @"HSCustomTodayWidgetsCell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellIdentifier];
	if (cell == nil)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reusableCellIdentifier] autorelease];

	WGWidgetInfo *widgetInfo = [_widgetInfos objectAtIndex:indexPath.row];
	cell.textLabel.text = widgetInfo.displayName;
	if ([widgetInfo respondsToSelector:@selector(_icon)])
		cell.imageView.image = [widgetInfo _icon];
	else
		cell.imageView.image = [widgetInfo icon];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WGWidgetInfo *widgetInfo = [_widgetInfos objectAtIndex:indexPath.row];
	self.selectedWidgetIdentifier = widgetInfo.widgetIdentifier;
	[super tableView:tableView didSelectRowAtIndexPath:indexPath]; // this begins the dismiss animation so its better to do it at the end
}

-(void)dealloc {
	if (_widgetInfos != nil) {
		[_widgetInfos release];
		_widgetInfos = nil;
	}

	[super dealloc];
}
@end

@implementation HSTodayWidgetViewController
-(id)initForOriginRow:(NSUInteger)originRow withOptions:(NSDictionary *)options {
	self = [super initForOriginRow:originRow withOptions:options];
	if (self != nil) {
		_widgetIdentifier = options[@"widgetIdentifier"];
		_isExpandedMode = options[@"isExpandedMode"] ? [options[@"isExpandedMode"] boolValue] : NO;
		_requestedWidgetUpdate = NO;
		_shouldRequestWidgetRemoteViewController = NO;
	}
	return self;
}

-(NSUInteger)numRows {
	// TODO: maybe calculate num rows for expanded mode
	if (_isExpandedMode)
		return _options[@"expandedModeRows"] ? [_options[@"expandedModeRows"] doubleValue] : kExpandedNumRows;
	return _options[@"normalModeRows"] ? [_options[@"normalModeRows"] doubleValue] : kNumRows; // apple widgets take up 2 rows (non expanded)
}

+(BOOL)canAddWidgetForAvailableRows:(NSUInteger)rows {
	return rows >= kNumRows; // least amount of rows needed
}

+(NSString *)displayName {
	return kDisplayName;
}

+(UIImage *)icon {
	return [UIImage imageNamed:kIconImageName inBundle:[NSBundle bundleWithPath:kBundlePath] compatibleWithTraitCollection:nil];
}

+(Class)addNewWidgetAdditionalOptionsClass {
	return [HSTodayWidgetsListViewController class];
}

+(NSDictionary *)createOptionsFromController:(HSTodayWidgetsListViewController *)controller {
	return @{
		@"widgetIdentifier" : controller.selectedWidgetIdentifier
	};
}

/*-(BOOL)canExpandWidget {
	return [self availableRows] >= (kExpandedNumRows - kNumRows) && !_isExpandedMode;
}

-(BOOL)canShrinkWidget {
	return _isExpandedMode;
}

-(void)expandBoxTapped {
	_isExpandedMode = YES;
	_options[@"isExpandedMode"] = @(YES);

	[self.hostingViewController setActiveDisplayMode:1];
	[self requestWidgetUpdate];

	[self updateForExpandOrShrinkFromRows:kNumRows];
}

-(void)shrinkBoxTapped {
	_isExpandedMode = NO;
	_options[@"isExpandedMode"] = @(NO);

	[self.hostingViewController setActiveDisplayMode:0];
	[self requestWidgetUpdate];

	[self updateForExpandOrShrinkFromRows:kExpandedNumRows];
}*/

-(void)_setupWidgetView {
	CGRect frame = (CGRect){{0, 0}, self.requestedSize};
	if (%c(WGWidgetShortLookView)) {
		WGWidgetShortLookView *shortlookView = [[%c(WGWidgetShortLookView) alloc] initWithFrame:frame andCornerRadius:13.0f];
		if (%c(NCMaterialSettings)) {
			NCMaterialSettings *materialSettings = [[%c(NCMaterialSettings) alloc] init];
			[materialSettings setDefaultValues];
			@try {
				[shortlookView setValue:materialSettings forKey:@"_materialSettings"];
			} @catch (NSException *e) {
				// do nothing for NSUndefinedKeyException
			}
			// go through each subview to find material view (usually the first element)
			for (UIView *view in [shortlookView subviews]) {
				if ([view isKindOfClass:%c(NCMaterialView)]) {
					NCMaterialView *materialView = (NCMaterialView *)view;
					@try {
						[materialView setValue:@2 forKey:@"_styleOptions"];
						[materialView setValue:materialSettings forKey:@"_settings"];
					} @catch (NSException *e) {
						// do nothing for NSUndefinedKeyException
					}
					break;
				}
			}
			[materialSettings release];
		}
		[shortlookView setWidgetHost:self.hostingViewController];
		[shortlookView setShowMoreButtonVisible:NO];
		[self.view addSubview:shortlookView];
		self.widgetView = shortlookView;
	} else if (%c(WGWidgetPlatterView)) {
		WGWidgetPlatterView *platterView = [[%c(WGWidgetPlatterView) alloc] initWithFrame:frame andCornerRadius:13.0f];
		if (%c(MTMaterialView)) {
			@try {
				[platterView setValue:@1 forKey:@"_recipe"];
				[platterView setValue:@2 forKey:@"_options"];
			} @catch (NSException *e) {
				// do nothing for NSUndefinedKeyException
			}
			// go through each subview to find material view (usually the first element)
			for (UIView *view in [platterView subviews]) {
				if ([view isKindOfClass:%c(MTMaterialView)]) {
					MTMaterialView *materialView = (MTMaterialView *)view;
					if ([materialView respondsToSelector:@selector(setFinalRecipe:options:)]) {
						[materialView setFinalRecipe:1 options:2];
					} else {
						[view removeFromSuperview];

						@autoreleasepool {
							// little performance heavy but I couldn't figure out a way to overwrite recipe once view is created
							materialView = [%c(MTMaterialView) materialViewWithRecipe:1 options:2];
							materialView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
							[materialView _setCornerRadius:13.0f];
							[platterView insertSubview:materialView atIndex:0];
						}
					}
					break;
				}
			}
		}
		[platterView setWidgetHost:self.hostingViewController];
		[platterView setShowMoreButtonVisible:NO];
		[self.view addSubview:platterView];
		self.widgetView = platterView;
	}
}

-(BOOL)isExpandedMode {
	return _isExpandedMode;
}

-(void)loadView {
	[super loadView];

	if (self.widgetIdentifier != nil) {
		@autoreleasepool {
			NSExtension *widgetExtension = [%c(NSExtension) extensionWithIdentifier:self.widgetIdentifier error:nil];
			WGWidgetInfo *widgetInfo = [%c(WGWidgetInfo) widgetInfoWithExtension:widgetExtension];
			self.hostingViewController = [[%c(WGWidgetHostingViewController) alloc] initWithWidgetInfo:widgetInfo delegate:self host:self];
		}

		if ([self.hostingViewController respondsToSelector:@selector(_removeAllSnapshotsForActiveDisplayMode)])
			[self.hostingViewController _removeAllSnapshotsForActiveDisplayMode];
		else if ([self.hostingViewController respondsToSelector:@selector(_removeAllSnapshotFilesForActiveDisplayMode)])
			[self.hostingViewController _removeAllSnapshotFilesForActiveDisplayMode];

		[self.hostingViewController _setLargestAvailableDisplayMode:(_isExpandedMode ? kDisplayModeExpanded : kDisplayModeCompact)];

		[self _setupWidgetView];
		self.widgetView.frame = (CGRect){{0, 0}, self.requestedSize};
		_shouldRequestWidgetRemoteViewController = YES;
		// if (_isFirstLoadAfterRespring) {
		// 	[self.hostingViewController _initiateNewSequenceIfNecessary];
		// 	[self.hostingViewController _updateWidgetWithCompletionHandler:nil];
		// }
		// [self connectRemoteViewController];
	}
}

-(void)_editingStateChanged {
	[super _editingStateChanged];

	if (_isEditing && _editingView != nil && self.widgetView != nil) {
		if ([_editingView isDescendantOfView:self.widgetView])
			[self.widgetView addSubview:_editingView];
		[self.widgetView bringSubviewToFront:_editingView];
		self.widgetView.frame = [self calculatedFrame];
	}
}

/*-(void)remoteViewControllerDidConnectForWidget:(id)arg1 {
	// do nothing
}

-(void)remoteViewControllerViewDidAppearForWidget:(id)arg1 {
	// do nothing
}*/

-(CGRect)calculatedFrame {
	CGSize finalWidgetSize = self.widgetView.frame.size;
	CGFloat preferredContentHeight = self.hostingViewController.preferredContentSize.height;
	CGFloat maximumContentHeightForCompactDisplayMode = [%c(WGWidgetInfo) maximumContentHeightForCompactDisplayMode];
	CGFloat expectedHeight = self.requestedSize.height;
	if (_options[@"expandedModeHeight"] != nil && _isExpandedMode) {
		expectedHeight = [_options[@"expandedModeHeight"] doubleValue];
	} else if (_options[@"normalModeHeight"] != nil && !_isExpandedMode) {
		expectedHeight = [_options[@"normalModeHeight"] doubleValue];
	} else if (preferredContentHeight == 0.0) {
		NSUInteger numRows = [self numRows];
		expectedHeight = 74 * numRows + (numRows >= 2 ? 34 * (numRows - 2) : 0); // backup values
	} else if (_isExpandedMode && preferredContentHeight > maximumContentHeightForCompactDisplayMode && fabs(preferredContentHeight - maximumContentHeightForCompactDisplayMode) > kHeaderHeight) {
		expectedHeight = preferredContentHeight + kHeaderHeight;
	} else if (!_isExpandedMode) {
		expectedHeight = maximumContentHeightForCompactDisplayMode + kHeaderHeight;
	}
	finalWidgetSize.height = expectedHeight;
	if (finalWidgetSize.width <= 0.0) {
		finalWidgetSize.width = self.requestedSize.width;
	}
	CGPoint center = (CGPoint){(self.requestedSize.width - finalWidgetSize.width) / 2, (self.requestedSize.height - finalWidgetSize.height) / 2};
	center.x += _options[@"offsetX"] ? [_options[@"offsetX"] doubleValue] : 0.0;
	center.y += _options[@"offsetY"] ? [_options[@"offsetY"] doubleValue] : 0.0;
	return (CGRect){center, finalWidgetSize};
}

-(void)setRequestedSize:(CGSize)requestedSize {
	[super setRequestedSize:requestedSize];

	if (self.widgetView != nil)
		self.widgetView.frame = [self calculatedFrame];
}

/*-(void)clearZoomAnimatingView {
	// fix widget not loading correctly due to animation
	[self requestWidgetConnect];
	[super clearZoomAnimatingView];
}*/

/*-(void)updateWidgetAfterRespring {
	// fix widget not loading correctly after respring
	[super updateWidgetAfterRespring];
	[self performSelector:@selector(requestWidgetConnect) withObject:nil afterDelay:kUpdateAfterRespringWaitTime];
}*/

-(void)_setDelegate:(id<HSWidgetDelegate>)delegate {
	BOOL didDelegateChange = delegate != _delegate;
	if (didDelegateChange && self.hostingViewController != nil)
		[self disconnectRemoteViewControllerWithCompletion:nil];

	[super _setDelegate:delegate];

	if (didDelegateChange && self.hostingViewController != nil) {
		[self requestWidgetConnect];

		self.widgetView.frame = [self calculatedFrame]; // calculate size of widget view
	}
}

/*-(void)requestWidgetUpdate {
	if (_requestedWidgetUpdate) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestWidgetUpdate) object:nil];
		[self performSelector:@selector(requestWidgetUpdate) withObject:nil afterDelay:kReupdateWaitTime];
	} else {
		_requestedWidgetUpdate = YES;
		[self.widgetViewController.widgetHost _updateWidgetWithCompletionHandler:^{
			_requestedWidgetUpdate = NO;
		}];
	}
}*/

-(void)requestWidgetConnect {
	if (_requestedWidgetUpdate) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestWidgetConnect) object:nil];
		[self performSelector:@selector(requestWidgetConnect) withObject:nil afterDelay:kReupdateWaitTime];
	} else {
		[self connectRemoteViewController];
	}
}

-(void)connectRemoteViewController {
	if (!_requestedWidgetUpdate) {
		_requestedWidgetUpdate = YES;
		[self.hostingViewController _initiateNewSequenceIfNecessary];
		[self.hostingViewController _requestRemoteViewControllerForSequence:[self.hostingViewController _activeLifeCycleSequence] completionHander:^{
			[self.hostingViewController _connectRemoteViewControllerForReason:@"appearance transition" sequence:[self.hostingViewController _activeLifeCycleSequence] completionHandler:^{
				_requestedWidgetUpdate = NO;
				[self.hostingViewController _requestInsertionOfRemoteViewAfterViewWillAppearForSequence:[self.hostingViewController _activeLifeCycleSequence] completionHandler:^{
					self.widgetView.frame = [self calculatedFrame];
				}];
			}];
		}];
	}
}

-(void)disconnectRemoteViewControllerWithCompletion:(void(^)())completion {
	if (!_requestedWidgetUpdate) {
		_requestedWidgetUpdate = YES;
		[self.hostingViewController _disconnectRemoteViewControllerForSequence:[self.hostingViewController _activeLifeCycleSequence] completion:^{
			_requestedWidgetUpdate = NO;

			if (completion != nil)
				completion();
		}];
	}
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	_shouldRequestWidgetRemoteViewController = YES;

	// [self.hostingViewController _performUpdateForSequence:[self.hostingViewController _activeLifeCycleSequence] withCompletionHandler:nil];
	[self requestWidgetConnect];
	
	if (self.widgetView != nil)
		self.widgetView.frame = [self calculatedFrame]; // calculate size of widget view
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	_shouldRequestWidgetRemoteViewController = NO;

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestWidgetConnect) object:nil];
	// [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestWidgetUpdate) object:nil];
	_requestedWidgetUpdate = NO;

	if (_options[@"forceDisconnectWhenNotVisible"] != nil &&  [_options[@"forceDisconnectWhenNotVisible"] boolValue])
		[self disconnectRemoteViewControllerWithCompletion:nil];
}

-(void)dealloc {
	[self.hostingViewController release];
	self.hostingViewController = nil;

	[self.widgetView removeFromSuperview];
	[self.widgetView release];
	self.widgetView = nil;

	[super dealloc];
}

-(CGSize)maxSizeForWidget:(id)arg1 forDisplayMode:(NSInteger)arg2 {
	CGSize result = self.requestedSize;
	if (arg2 == kDisplayModeCompact)
		result.height = [%c(WGWidgetInfo) maximumContentHeightForCompactDisplayMode];
	else if (arg2 == kDisplayModeExpanded)
		result.height = [UIScreen mainScreen].bounds.size.height - kHeaderHeight;
	if (result.width == 0.0)
		result.width = [UIScreen mainScreen].bounds.size.width - kScreenPadding;
	return result;
}

-(NSInteger)userSpecifiedDisplayModeForWidget:(id)arg1 {
	return _isExpandedMode ? kDisplayModeExpanded : kDisplayModeCompact;
}

-(NSInteger)largestAvailableDisplayModeForWidget:(id)arg1 {
	return _isExpandedMode ? kDisplayModeExpanded : kDisplayModeCompact;
}

-(NSInteger)activeLayoutModeForWidget:(id)arg1 {
	return _isExpandedMode ? kDisplayModeExpanded : kDisplayModeCompact;
}

-(BOOL)isWidgetExtensionVisible:(id)arg1 {
	return [%c(SBUIIconForceTouchController) _isWidgetVisible:arg1];
}

-(BOOL)shouldRequestWidgetRemoteViewControllers {
	return _shouldRequestWidgetRemoteViewController;
}
@end

%hook WGWidgetHostingViewController
-(void)_updatePreferredContentSizeWithHeight:(CGFloat)arg1 {
	%orig;

	HSTodayWidgetViewController *todayWidgetViewController = nil;
	if ([self host] != nil && [[self host] isKindOfClass:%c(HSTodayWidgetViewController)])
		todayWidgetViewController = (HSTodayWidgetViewController *)[self host];
	else if ([self delegate] != nil && [[self delegate] isKindOfClass:%c(HSTodayWidgetViewController)])
		todayWidgetViewController = (HSTodayWidgetViewController *)[self delegate];

	if (todayWidgetViewController != nil) {
		// update preferredContentSize as it doesn't seem to be updated for non system widgets
		CGSize preferredContentSize = self.preferredContentSize;
		preferredContentSize.height = arg1;
		self.preferredContentSize = preferredContentSize;

		UIView *_editingView = [todayWidgetViewController valueForKey:@"_editingView"];
		CGRect calculatedFrame = [todayWidgetViewController calculatedFrame];
		todayWidgetViewController.preferredContentSize = calculatedFrame.size;
		[UIView animateWithDuration:kAnimationDuration animations:^{
			todayWidgetViewController.widgetView.frame = calculatedFrame;
			_editingView.frame = calculatedFrame;
		} completion:nil];
	}
}
%end

%dtor {
	widgetDiscoveryController = nil;
}