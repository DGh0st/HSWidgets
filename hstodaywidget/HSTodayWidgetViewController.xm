#import "HSTodayWidgetViewController.h"
#import <HSWidgets/HSAdditionalOptionsTableViewController.h>

#define kNumRows 2 // today widgets take atleast 2 rows
#define kExpandedNumRows 3 // expanded display mode takes up 3 rows
#define kDisplayName @"Today Widgets"
#define kIconImageName @"HSCustom"
#define kReupdateWaitTime 3.0 // wait for 3 seconds before reattempting to update
#define kHeaderHeight 36 // height of the header bar

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

@interface SpringBoard : UIApplication

@end

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
		_didAddMaterialView = NO;
		_isExpandedMode = options[@"isExpandedMode"] ? [options[@"isExpandedMode"] boolValue] : NO;
		_requestedWidgetUpdate = NO;
		_isNewlyAdded = options[@"isNewlyAdded"] ? [options[@"isNewlyAdded"] boolValue] : NO;
		if (_isNewlyAdded) {
			[_options removeObjectForKey:@"isNewlyAdded"]; // remove completely from dictionary as we don't need it to take up space
			_isFirstLoadAfterRespring = NO;
		} else {
			_isFirstLoadAfterRespring = YES;
		}
	}
	return self;
}

-(NSUInteger)numRows {
	// TODO: maybe calculate num rows for expanded mode
	if (_isExpandedMode)
		return _options[@"expandedModeRows"] ? [_options[@"expandedModeRows"] doubleValue] : kExpandedNumRows;
	return _options[@"normalModeRows"] ? [_options[@"normalModeRows"] doubleValue]: kNumRows; // apple widgets take up 2 rows (non expanded)
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
		@"widgetIdentifier" : controller.selectedWidgetIdentifier,
		@"isNewlyAdded" : @YES
	};
}

/*-(BOOL)canExpandWidget {
	return [super availableRows] >= (kExpandedNumRows - kNumRows) && !_isExpandedMode;
}

-(BOOL)canShrinkWidget {
	return _isExpandedMode;
}

-(void)expandBoxTapped {
	_isExpandedMode = YES;
	_options[@"isExpandedMode"] = @(YES);

	[self.widgetViewController.widgetHost setActiveDisplayMode:1];
	[self requestWidgetUpdate];

	[self updateForExpandOrShrinkFromRows:kNumRows];
}

-(void)shrinkBoxTapped {
	_isExpandedMode = NO;
	_options[@"isExpandedMode"] = @(NO);

	[self.widgetViewController.widgetHost setActiveDisplayMode:0];
	[self requestWidgetUpdate];

	[self updateForExpandOrShrinkFromRows:kExpandedNumRows];
}*/

-(void)_setupWidgetView {
	if ([self.widgetViewController.view isKindOfClass:%c(WGWidgetShortLookView)]) {
		if (%c(NCMaterialSettings)) {
			NCMaterialSettings *materialSettings = [[%c(NCMaterialSettings) alloc] init];
			[materialSettings setDefaultValues];
			@try {
				[self.widgetViewController.view setValue:materialSettings forKey:@"_materialSettings"];
			} @catch (NSException *e) {
				// do nothing for NSUndefinedKeyException
			}
			if (!_didAddMaterialView) {
				_didAddMaterialView = YES;
				NCMaterialView *materialView = [%c(NCMaterialView) materialViewWithStyleOptions:2 materialSettings:materialSettings];
				materialView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				materialView.cornerRadius = 13.0f;
				[self.widgetViewController.view insertSubview:materialView atIndex:0];
			}
			[materialSettings release];
		}
		((WGWidgetShortLookView *)self.widgetViewController.view).addWidgetButtonVisible = NO;
		((WGWidgetShortLookView *)self.widgetViewController.view).cornerRadius = 13.0f;
	} else if ([self.widgetViewController.view isKindOfClass:%c(WGWidgetPlatterView)]) {
		((WGWidgetPlatterView *)self.widgetViewController.view).addWidgetButtonVisible = NO;
		((WGWidgetPlatterView *)self.widgetViewController.view).cornerRadius = 13.0f;
	}
}

-(BOOL)isExpandedMode {
	return _isExpandedMode;
}

-(void)loadView {
	[super loadView];

	if (self.widgetIdentifier != nil) {
		NSExtension *widgetExtension = [%c(NSExtension) extensionWithIdentifier:self.widgetIdentifier error:nil];
		WGWidgetInfo *widgetInfo = [%c(WGWidgetInfo) widgetInfoWithExtension:widgetExtension];
		self.widgetViewController = [[%c(WGWidgetViewController) alloc] initWithWidgetInfo:widgetInfo];
		[self.widgetViewController setDelegate:self];
		[self _setupWidgetView];
		if ([self.widgetViewController respondsToSelector:@selector(_shortLookViewLoadingIfNecessary:)])
			[self.view addSubview:[self.widgetViewController _shortLookViewLoadingIfNecessary:YES]];
		else if ([self.widgetViewController respondsToSelector:@selector(_platterViewLoadingIfNecessary:)])
			[self.view addSubview:[self.widgetViewController _platterViewLoadingIfNecessary:YES]];
		else
			[self.view addSubview:self.widgetViewController.view];
		self.widgetViewController.view.frame = (CGRect){{0, 0}, self.requestedSize}; // back up size

		// TODO: Correctly update the widget on first load (sometimes the widget just isn't feeling it)
		if (_isFirstLoadAfterRespring) {
			[self.widgetViewController.widgetHost _initiateNewSequenceIfNecessary];
			[self.widgetViewController.widgetHost _updateWidgetWithCompletionHandler:nil];
		} else {
			[self connectRemoteViewController];
			// [self requestWidgetConnect];
		}
	}
}

-(void)_editingStateChanged {
	[super _editingStateChanged];

	if (_isEditing && _editingView != nil && self.widgetViewController != nil && self.widgetViewController.view != nil) {
		if ([_editingView isDescendantOfView:self.widgetViewController.view])
			[self.widgetViewController.view addSubview:_editingView];
		[self.widgetViewController.view bringSubviewToFront:_editingView];
	}
}

-(void)remoteViewControllerDidConnectForWidgetViewController:(id)arg1 {
	// do nothing
}

-(void)remoteViewControllerViewDidAppearForWidgetViewController:(id)arg1 {
	// do nothing
}

-(CGRect)calculatedFrame {
	CGSize finalWidgetSize = self.widgetViewController.view.frame.size;
	CGFloat preferredContentHeight = self.widgetViewController.widgetHost.preferredContentSize.height;
	CGFloat maximumContentHeightForCompactDisplayMode = [%c(WGWidgetInfo) maximumContentHeightForCompactDisplayMode];
	CGFloat expectedHeight = self.requestedSize.height;
	if (_options[@"expandedModeHeight"] != nil && _isExpandedMode) {
		expectedHeight = [_options[@"expandedModeHeight"] doubleValue];
	} else if (preferredContentHeight == 0.0) {
		NSUInteger numRows = [self numRows];
		expectedHeight = 74 * numRows + (numRows >= 2 ? 34 * (numRows - 2) : 0); // backup values
	} else if (_isExpandedMode && preferredContentHeight > maximumContentHeightForCompactDisplayMode && fabs(preferredContentHeight - maximumContentHeightForCompactDisplayMode) > kHeaderHeight) {
		expectedHeight = preferredContentHeight + kHeaderHeight;
	} else if (!_isExpandedMode) {
		expectedHeight = maximumContentHeightForCompactDisplayMode + kHeaderHeight;
	}
	finalWidgetSize.height = expectedHeight;
	return (CGRect){{(self.requestedSize.width - finalWidgetSize.width) / 2, (self.requestedSize.height - finalWidgetSize.height) / 2}, finalWidgetSize};
}

-(void)setRequestedSize:(CGSize)requestedSize {
	[super setRequestedSize:requestedSize];

	if (self.widgetViewController != nil)
		self.widgetViewController.view.frame = [self calculatedFrame];
}

-(void)clearZoomAnimatingView {
	// fix widget not loading correctly due to animation
	[self requestWidgetConnect];
	[super clearZoomAnimatingView];
}

-(void)_setDelegate:(id<HSWidgetDelegate>)delegate {
	BOOL didDelegateChange = delegate != _delegate;
	if (didDelegateChange && self.widgetViewController != nil)
		[self.widgetViewController viewDidDisappear:NO];

	[super _setDelegate:delegate];

	if (didDelegateChange && self.widgetViewController != nil) {
		[self.widgetViewController viewDidAppear:NO];

		self.widgetViewController.view.frame = [self calculatedFrame]; // calculate size of widget view
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
		WGWidgetHostingViewController *hostingViewController = self.widgetViewController.widgetHost;
		[hostingViewController _initiateNewSequenceIfNecessary];
		[hostingViewController _requestRemoteViewControllerForSequence:[hostingViewController _activeLifeCycleSequence] completionHander:^{
			[hostingViewController _connectRemoteViewControllerForReason:@"appearance transition" sequence:[hostingViewController _activeLifeCycleSequence] completionHandler:^{
				_requestedWidgetUpdate = NO;
				[self.widgetViewController remoteViewControllerDidConnectForWidget:hostingViewController];
				[hostingViewController _requestInsertionOfRemoteViewAfterViewWillAppearForSequence:[hostingViewController _activeLifeCycleSequence] completionHandler:^{
					[self.widgetViewController remoteViewControllerViewDidAppearForWidget:hostingViewController];
				}];
			}];
		}];
	}
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	if (_isNewlyAdded || !_isFirstLoadAfterRespring)
		[self requestWidgetConnect];

	[self.widgetViewController viewDidAppear:animated];

	// speed up remote view display cycle (doesn't actually connect the remote view controller)
	if (!_isNewlyAdded && _isFirstLoadAfterRespring) {
		[self.widgetViewController remoteViewControllerDidConnectForWidget:self.widgetViewController.widgetHost];
		[self.widgetViewController remoteViewControllerViewDidAppearForWidget:self.widgetViewController.widgetHost];
	}
	
	self.widgetViewController.view.frame = [self calculatedFrame]; // calculate size of widget view
	_isNewlyAdded = NO;
	_isFirstLoadAfterRespring = NO;
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	[self.widgetViewController viewDidDisappear:animated];

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestWidgetConnect) object:nil];
	// [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(requestWidgetUpdate) object:nil];
	_requestedWidgetUpdate = NO;
}

-(void)dealloc {
	[self.widgetViewController.view removeFromSuperview];
	[self.widgetViewController release];
	self.widgetViewController = nil;

	[super dealloc];
}
@end


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

// add expanded mode (I know it is bad practice to directly call the object's method instead of using the protocol but this was a proof of concept which turned into a permanent thing)
%hook WGWidgetViewController
-(NSInteger)userSpecifiedDisplayModeForWidget:(id)arg1 {
	if ([self delegate] != nil && [[self delegate] isKindOfClass:%c(HSTodayWidgetViewController)])
		return [(HSTodayWidgetViewController *)[self delegate] isExpandedMode] ? 1 : 0;
	return %orig;
}

-(NSInteger)largestAvailableDisplayModeForWidget:(id)arg1 {
	if ([self delegate] != nil && [[self delegate] isKindOfClass:%c(HSTodayWidgetViewController)])
		return [(HSTodayWidgetViewController *)[self delegate] isExpandedMode] ? 1 : 0;
	return %orig;
}

-(CGSize)maxSizeForWidget:(id)arg1 forDisplayMode:(CGFloat)arg2 {
	CGSize result = %orig;
	if ([self delegate] != nil && [[self delegate] isKindOfClass:%c(HSTodayWidgetViewController)]) {
		if (arg2 == 0)
			result.height = [%c(WGWidgetInfo) maximumContentHeightForCompactDisplayMode];
		else if (arg2 == 1)
			result.height = [UIScreen mainScreen].bounds.size.height - kHeaderHeight;
	}
	return result;
}

%new
-(NSInteger)activeLayoutModeForWidget:(id)arg1 {
	if ([self delegate] != nil && [[self delegate] isKindOfClass:%c(HSTodayWidgetViewController)])
		return [(HSTodayWidgetViewController *)[self delegate] isExpandedMode] ? 1 : 0;
	return [self largestAvailableDisplayModeForWidget:arg1];
}

-(BOOL)isWidgetExtensionVisible:(id)arg1 {
	BOOL result = %orig;
	if (!result)
		[%c(SBUIIconForceTouchController) _isWidgetVisible:arg1];
	return result;
}
%end

%hook WGWidgetHostingViewController
-(void)_updatePreferredContentSizeWithHeight:(CGFloat)arg1 {
	%orig;

	if ([self host] != nil && [[self host] isKindOfClass:%c(WGWidgetViewController)] && [[self host] delegate] != nil && [[[self host] delegate] isKindOfClass:%c(HSTodayWidgetViewController)]) {
		// update preferredContentSize as it doesn't seem to be updated for non system widgets
		CGSize preferredContentSize = self.preferredContentSize;
		preferredContentSize.height = arg1;
		self.preferredContentSize = preferredContentSize;

		HSTodayWidgetViewController *todayWidgetViewController = (HSTodayWidgetViewController *)[[self host] delegate];
		UIView *_editingView = [todayWidgetViewController valueForKey:@"_editingView"];
		CGRect calculatedFrame = [todayWidgetViewController calculatedFrame];
		[UIView animateWithDuration:kAnimationDuration animations:^{
			todayWidgetViewController.widgetViewController.view.frame = calculatedFrame;
			_editingView.frame = calculatedFrame;
		} completion:nil];
	}
}
%end

%dtor {
	widgetDiscoveryController = nil;
}