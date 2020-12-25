#import "HSTodayWidgetViewController.h"
#import "HSTodayWidgetController.h"
#import "HSTodayWidgetsListViewController.h"
#import "MTMaterialView.h"
#import "SBWidgetController.h"
#import "SBUIIconForceTouchController.h"
#import "SBIconController.h"
#import "SpringBoard.h"
#import "UIViewController+Widgets.h"
#import "WGMajorListViewContorller.h"
#import "WGWidgetDiscoveryController.h"
#import "WGWidgetGroupViewController.h"
#import "WGWidgetHostingViewController.h"
#import "WGWidgetInfo.h"
#import "WGWidgetPlatterView.h"

#define WIDGET_HEADER_HEIGHT 40 // height of the header bar

// display modes
typedef NS_ENUM(NSInteger, DisplayMode) {
	DisplayModeCompact = 0,
	DisplayModeExpanded = 1
};

@implementation HSTodayWidgetViewController
-(instancetype)initForWidgetFrame:(HSWidgetFrame)frame withOptions:(NSDictionary *)options {
	self = [super initForWidgetFrame:frame withOptions:options];
	if (self != nil) {
		_widgetIdentifier = options[@"widgetIdentifier"];
		_isExpandedMode = options[@"isExpandedMode"] ? [options[@"isExpandedMode"] boolValue] : NO;
		_isWidgetVisible = NO;
	}
	return self;
}

+(HSWidgetSize)minimumSize {
	return HSWidgetSizeMake(HSTodayWidgetMinNumRows, HSTodayWidgetMinNumCols); // least amount of rows and cols the widget needs
}

+(BOOL)isAvailable {
	return [[HSTodayWidgetController sharedInstance] availableWidgetsCount] > 0;
}

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
		WGWidgetPlatterView *platterView = nil;
		if ([%c(WGWidgetPlatterView) instancesRespondToSelector:@selector(initWithFrame:andCornerRadius:)]) {
			platterView = [[%c(WGWidgetPlatterView) alloc] initWithFrame:frame andCornerRadius:13.0f];
		} else  {
			platterView = [[%c(WGWidgetPlatterView) alloc] initWithFrame:frame];
			
			// set the continuous radius
			if ([platterView respondsToSelector:@selector(_setContinuousCornerRadius:)]) {
				[platterView _setContinuousCornerRadius:13.0];
			}

			// fix title view not being loaded in iOS 13+
			if ([platterView respondsToSelector:@selector(_configureHeaderViewsIfNecessary)]) {
				[platterView _configureHeaderViewsIfNecessary];
			}

			// fix header view background on iOS 13+
			if ([platterView respondsToSelector:@selector(setMaterialGroupNameBase:)]) {
				[platterView setMaterialGroupNameBase:@"WGWidgetListViewControllerGroupName"];
			}
		}

		if (%c(MTMaterialView)) {
			if ([platterView respondsToSelector:@selector(_configureBackgroundMaterialViewIfNecessary)]) {
				[platterView _configureBackgroundMaterialViewIfNecessary];
			} else if ([platterView respondsToSelector:@selector(updateWithRecipe:options:)]) {
				[platterView updateWithRecipe:2 options:3];
			} else {
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
							[materialView setFinalRecipe:2 options:3];
						} else if ([materialView respondsToSelector:@selector(setRecipe:)] && [materialView respondsToSelector:@selector(setConfiguration:)]) {
							[materialView setRecipe:2];
							[materialView setConfiguration:1];
						} else if ([%c(MTMaterialView) respondsToSelector:@selector(materialViewWithRecipe:options:)]) {
							[view removeFromSuperview];

							@autoreleasepool {
								// little performance heavy but I couldn't figure out a way to overwrite recipe once view is created
								materialView = [%c(MTMaterialView) materialViewWithRecipe:1 options:2];
								materialView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
								[materialView _setContinuousCornerRadius:13.0];
								[platterView insertSubview:materialView atIndex:0];
							}
						}
						break;
					}
				}
			}
		}
		
		[platterView setWidgetHost:self.hostingViewController];
		[platterView setShowMoreButtonVisible:NO];
		[self.view addSubview:platterView];
		self.widgetView = platterView;
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingStateChanged:) name:HSWidgetEditingStateChangedNotification object:nil];
}

-(void)loadView {
	[super loadView];

	if (self.widgetIdentifier != nil) {
		@autoreleasepool {
			self.hostingViewController = [[HSTodayWidgetController sharedInstance] widgetWithIdentifier:self.widgetIdentifier delegate:self host:self];
			[self addChildViewController:self.hostingViewController];
			[self.hostingViewController didMoveToParentViewController:self];
		}

		if ([self.hostingViewController respondsToSelector:@selector(_removeAllSnapshotsForActiveDisplayMode)]) {
			[self.hostingViewController _removeAllSnapshotsForActiveDisplayMode];
		} else if ([self.hostingViewController respondsToSelector:@selector(_removeAllSnapshotFilesForActiveDisplayMode)]) {
			[self.hostingViewController _removeAllSnapshotFilesForActiveDisplayMode];
		}

		DisplayMode mode = (_isExpandedMode ? DisplayModeExpanded : DisplayModeCompact);
		[self.hostingViewController _setLargestAvailableDisplayMode:mode];
		self.hostingViewController.userSpecifiedDisplayMode = mode;
		[self.hostingViewController setDisconnectsImmediately:NO];

		[self _setupWidgetView];

		[self.view setNeedsLayout];
		[self.view layoutIfNeeded];

		_isWidgetVisible = YES;
	}
}

-(void)editingStateChanged:(NSNotification *)notification {
	BOOL isEditing = [notification.userInfo[HSWidgetEditingStateKey] boolValue];
	if (isEditing && self.widgetView != nil) {
		self.widgetView.frame = [self calculatedFrame];
	}
}

/*-(void)remoteViewControllerDidConnectForWidget:(id)widget {
	// do nothing
}

-(void)remoteViewControllerDidDisconnectForWidget:(id)widget {
	[widget setDisconnectsImmediately:NO];
}

-(void)remoteViewControllerViewDidAppearForWidget:(id)widget {
	// do nothing
}*/

-(CGFloat)_todayWidgetWidth {
	CGFloat expectedWidth = 0.0;
	// get user selected widget width
	WidthStyle widthStyle = (WidthStyle)[widgetOptions[@"WidthStyle"] unsignedIntegerValue];
	if (widthStyle == WidthStyleFillSpace) {
		expectedWidth = self.requestedSize.width;
	} else if (widthStyle == WidthStyleCustom) {
		CGFloat width = [widgetOptions[@"Width"] doubleValue];
		expectedWidth = width > 0.0 ? width : 398.0;
	}

	// fallback to using auto width style
	// try get the width from icon controller if possible
	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	if (expectedWidth == 0.0 && [iconController respondsToSelector:@selector(widgetGroupViewController:sizeForInterfaceOrientation:)]) {
		UIInterfaceOrientation orientation = [[%c(SpringBoard) sharedApplication] homeScreenSupportsRotation] ? [iconController orientation] : UIInterfaceOrientationPortrait;
		CGSize size = [iconController widgetGroupViewController:nil sizeForInterfaceOrientation:orientation];
		if (size.width > 0) {
			expectedWidth = size.width;
		}
	}

	// fallback to this if width was not found through icon controller
	if (expectedWidth == 0.0) {
		WGWidgetDiscoveryController *widgetDiscoveryController = [[[%c(SpringBoard) sharedApplication] widgetController] _widgetDiscoveryController];
		WGWidgetGroupViewController *groupWidgetViewController = nil;
		if ([[widgetDiscoveryController debuggingHandler] isKindOfClass:%c(WGWidgetGroupViewController)]) {
			groupWidgetViewController = [widgetDiscoveryController debuggingHandler];
		}

		if ([groupWidgetViewController respondsToSelector:@selector(widgetListViewController:sizeForInterfaceOrientation:)]) {
			UIInterfaceOrientation orientation = [[%c(SpringBoard) sharedApplication] homeScreenSupportsRotation] ? [iconController orientation] : UIInterfaceOrientationPortrait;
			expectedWidth = [groupWidgetViewController widgetListViewController:nil sizeForInterfaceOrientation:orientation].width;
		} else {
			WGMajorListViewContorller *majorListViewController = [groupWidgetViewController valueForKey:@"_majorColumnListViewController"];
			if (majorListViewController != nil) {
				expectedWidth = [majorListViewController maxSizeForWidget:nil forDisplayMode:_isExpandedMode ? DisplayModeExpanded : DisplayModeCompact].width;
			} else /*if (finalWidgetSize.width <= 0.0)*/ {
				expectedWidth = self.requestedSize.width;
			}
		}
	}
	return expectedWidth == 0.0 ? self.requestedSize.width : expectedWidth;
}

-(CGRect)calculatedFrame {
	CGSize finalWidgetSize = [super calculatedFrame].size;
	CGFloat preferredContentHeight = self.hostingViewController.preferredContentSize.height;
	CGFloat maximumContentHeightForCompactDisplayMode = [%c(WGWidgetInfo) maximumContentHeightForCompactDisplayMode];

	// get the height
	CGFloat expectedHeight = self.requestedSize.height;
	if ([widgetOptions[@"modeHeight"] doubleValue] > 0.0) {
		expectedHeight = [widgetOptions[@"modeHeight"] doubleValue];
	} else if (_isExpandedMode) {
		if (preferredContentHeight == 0.0) {
			NSUInteger numRows = self.widgetFrame.size.numRows;
			expectedHeight = 74 * numRows + (numRows >= 2 ? 34 * (numRows - 2) : 0); // backup values
		} else if (preferredContentHeight > maximumContentHeightForCompactDisplayMode && fabs(preferredContentHeight - maximumContentHeightForCompactDisplayMode) > WIDGET_HEADER_HEIGHT) {
			expectedHeight = preferredContentHeight + WIDGET_HEADER_HEIGHT;
		}
	} else if (!_isExpandedMode) {
		expectedHeight = maximumContentHeightForCompactDisplayMode + WIDGET_HEADER_HEIGHT;
	}
	finalWidgetSize.height = expectedHeight;
	finalWidgetSize.width = [self _todayWidgetWidth];

	CGPoint origin = (CGPoint){(self.requestedSize.width - finalWidgetSize.width) / 2, (self.requestedSize.height - finalWidgetSize.height) / 2};
	origin.x += widgetOptions[@"offsetX"] ? [widgetOptions[@"offsetX"] doubleValue] : 0.0;
	origin.y += widgetOptions[@"offsetY"] ? [widgetOptions[@"offsetY"] doubleValue] : 0.0;
	return (CGRect){origin, finalWidgetSize};
}

-(void)setWidgetOptionValue:(id<NSCoding>)object forKey:(NSString *)key {
	[super setWidgetOptionValue:object forKey:key];

	if ([key isEqualToString:@"isExpandedMode"]) {
		_isExpandedMode = object != nil ? [(NSNumber *)object boolValue] : NO;
		DisplayMode mode = (_isExpandedMode ? DisplayModeExpanded : DisplayModeCompact);
		[self.hostingViewController _setLargestAvailableDisplayMode:mode];
		self.hostingViewController.userSpecifiedDisplayMode = mode;
	}

	// force relayout
	[self setRequestedSize:self.requestedSize];
}

-(void)setRequestedSize:(CGSize)requestedSize {
	[super setRequestedSize:requestedSize];

	if (self.widgetView != nil) {
		self.widgetView.frame = [self calculatedFrame];
	}
}

-(void)_setDelegate:(id<HSWidgetDelegate>)delegate {
	BOOL didDelegateChange = delegate != _delegate;
	if (didDelegateChange && self.hostingViewController != nil) {
		[self.hostingViewController wg_beginAppearanceTransitionIfNecessary:NO animated:NO];
		[self.hostingViewController wg_endAppearanceTransitionIfNecessary];
	}

	[super _setDelegate:delegate];

	if (didDelegateChange && self.hostingViewController != nil) {
		[self.hostingViewController wg_beginAppearanceTransitionIfNecessary:YES animated:NO];
		[self.hostingViewController wg_endAppearanceTransitionIfNecessary];

		self.widgetView.frame = [self calculatedFrame]; // calculate size of widget view
	}
}

-(BOOL)shouldAutomaticallyForwardAppearanceMethods {
	return NO;
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if ([self.hostingViewController respondsToSelector:@selector(managingContainerWillAppear:)]) {
		[self.hostingViewController managingContainerWillAppear:self];
	}
	
	[self.hostingViewController wg_beginAppearanceTransitionIfNecessary:YES animated:animated];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	_isWidgetVisible = YES;

	[self.hostingViewController wg_beginAppearanceTransitionIfNecessary:YES animated:animated];
	[self.hostingViewController wg_endAppearanceTransitionIfNecessary];
	
	if (self.widgetView != nil) {
		self.widgetView.frame = [self calculatedFrame]; // calculate size of widget view
	}
}

-(void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self.hostingViewController wg_beginAppearanceTransitionIfNecessary:NO animated:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	_isWidgetVisible = NO;
	if ([self.hostingViewController respondsToSelector:@selector(managingContainerDidDisappear:)]) {
		[self.hostingViewController managingContainerDidDisappear:self];
	}

	[self.hostingViewController wg_beginAppearanceTransitionIfNecessary:NO animated:animated];
	[self.hostingViewController wg_endAppearanceTransitionIfNecessary];
}

-(CGSize)maxSizeForWidget:(id)widget forDisplayMode:(NSInteger)mode {
	CGSize result = self.requestedSize;
	if (mode == DisplayModeCompact) {
		result.height = [%c(WGWidgetInfo) maximumContentHeightForCompactDisplayMode];
	} else if (mode == DisplayModeExpanded) {
		result.height = [UIScreen mainScreen].bounds.size.height - WIDGET_HEADER_HEIGHT;
	}
	result.width = [self _todayWidgetWidth];
	return result;
}

-(void)registerWidgetForRefreshEvents:(id)widget {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	[widgetDiscoveryController registerIdentifierForRefreshEvents:self.widgetIdentifier];
}

-(void)unregisterWidgetForRefreshEvents:(id)widget {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	[widgetDiscoveryController unregisterIdentifierForRefreshEvents:self.widgetIdentifier];
}

-(NSInteger)userSpecifiedDisplayModeForWidget:(id)widget {
	return _isExpandedMode ? DisplayModeExpanded : DisplayModeCompact;
}

-(void)widget:(id)widget didChangeUserSpecifiedDisplayMode:(NSInteger)mode {
	DisplayMode displayMode = _isExpandedMode ? DisplayModeExpanded : DisplayModeCompact;
	if (mode == displayMode) {
		WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
		if ([widgetDiscoveryController respondsToSelector:@selector(widget:didChangeUserSpecifiedDisplayMode:)]) {
			[widgetDiscoveryController widget:widget didChangeUserSpecifiedDisplayMode:mode];
		}
	}
}

-(NSInteger)largestAvailableDisplayModeForWidget:(id)widget {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	if ([widgetDiscoveryController respondsToSelector:@selector(largestAvailableDisplayModeForWidget:)]) {
		return [widgetDiscoveryController largestAvailableDisplayModeForWidget:widget];
	}
	return _isExpandedMode ? DisplayModeExpanded : DisplayModeCompact;
}

-(void)widget:(id)widget didChangeLargestAvailableDisplayMode:(NSInteger)mode {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	if ([widgetDiscoveryController respondsToSelector:@selector(widget:didChangeLargestAvailableDisplayMode:)]) {
		[widgetDiscoveryController widget:widget didChangeLargestAvailableDisplayMode:mode];
	}
}

-(void)widget:(id)widget didEncounterProblematicSnapshotAtURL:(id)url {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	if ([widgetDiscoveryController respondsToSelector:@selector(widget:didEncounterProblematicSnapshotAtURL:)]) {
		[widgetDiscoveryController widget:widget didEncounterProblematicSnapshotAtURL:url];
	}
}

-(void)widget:(id)widget didRemoveSnapshotAtURL:(id)url {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	if ([widgetDiscoveryController respondsToSelector:@selector(widget:didRemoveSnapshotAtURL:)]) {
		[widgetDiscoveryController widget:widget didRemoveSnapshotAtURL:url];
	}
}

-(BOOL)shouldPurgeArchivedSnapshotsForWidget:(id)widget {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	if ([widgetDiscoveryController respondsToSelector:@selector(shouldPurgeArchivedSnapshotsForWidget:)]) {
		return [widgetDiscoveryController shouldPurgeArchivedSnapshotsForWidget:widget];
	}
	return NO;
}

-(BOOL)shouldPurgeNonCAMLSnapshotsForWidget:(id)widget {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	if ([widgetDiscoveryController respondsToSelector:@selector(shouldPurgeNonCAMLSnapshotsForWidget:)]) {
		return [widgetDiscoveryController shouldPurgeNonCAMLSnapshotsForWidget:widget];
	}
	return NO;
}

-(BOOL)shouldPurgeNonASTCSnapshotsForWidget:(id)widget {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	if ([widgetDiscoveryController respondsToSelector:@selector(shouldPurgeNonASTCSnapshotsForWidget:)]) {
		return [widgetDiscoveryController shouldPurgeNonASTCSnapshotsForWidget:widget];
	}
	return NO;
}

-(BOOL)shouldRemoveSnapshotWhenNotVisibleForWidget:(id)widget {
	WGWidgetDiscoveryController *widgetDiscoveryController = [HSTodayWidgetController sharedInstance].widgetDiscoveryController;
	if ([widgetDiscoveryController respondsToSelector:@selector(shouldRemoveSnapshotWhenNotVisibleForWidget:)]) {
		return [widgetDiscoveryController shouldRemoveSnapshotWhenNotVisibleForWidget:widget];
	}
	return YES;
}

-(NSInteger)activeLayoutModeForWidget:(id)widget {
	return _isExpandedMode ? DisplayModeExpanded : DisplayModeCompact;
}

-(BOOL)isWidgetExtensionVisible:(id)widget {
	return [%c(SBUIIconForceTouchController) _isWidgetVisible:widget];
}

-(BOOL)shouldRequestWidgetRemoteViewControllers {
	return _isWidgetVisible;
}

-(BOOL)managingContainerIsVisibleForWidget:(id)widget {
	return _isWidgetVisible;
}

-(id)widget:(id)widget didUpdatePreferredHeight:(CGFloat)height completion:(id)completion {
	void (^result)() = ^{
		CGSize preferredContentSize = self.hostingViewController.preferredContentSize;
		preferredContentSize.height = height;
		self.hostingViewController.preferredContentSize = preferredContentSize;

		CGRect calculatedFrame = [self calculatedFrame];
		[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
			self.widgetView.frame = calculatedFrame;
		} completion:completion];
	};

	return result;
}

-(void)dealloc {
	[[HSTodayWidgetController sharedInstance] removeWidgetWithIdentifier:self.widgetIdentifier];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:HSWidgetEditingStateChangedNotification object:nil];

	[self.hostingViewController willMoveToParentViewController:nil];
	[self.hostingViewController removeFromParentViewController];
	self.hostingViewController = nil;

	[self.widgetView removeFromSuperview];
	[self.widgetView release];
	self.widgetView = nil;

	[super dealloc];
}
@end
