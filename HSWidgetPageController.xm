#import "HSWidgetPageController.h"
#import "HSWidgetLoader.h"
#import "HSWidgetPreferences.h"
#import "HSWidgetUnrotateableViewController.h"
#import "SBIconController.h"
#import "SBRootFolderController.h"
// #import "SpringBoard.h"

#define DRAGGING_WIDGET_HOLD_DURATION 0.03
// #define PICKER_ROTATION_ASSERTION_REASON @"HSWidgetPicker"

static NSMutableArray *AvailableWidgetControllerClassesForAvailableSpaces(NSArray<HSWidgetAvailablePositionObject *> *positions, NSMutableArray *insufficientSpaceWidgets) {
	NSMutableArray *result = [NSMutableArray array];
	for (Class widgetClass in [HSWidgetLoader availableHSWidgetClasses]) {
		if ([widgetClass isSubclassOfClass:[HSWidgetViewController class]] && [widgetClass isAvailable]) {
			if ([widgetClass canAddWidgetForAvailableGridPositions:positions]) {
				[result addObject:widgetClass];
			} else {
				[insufficientSpaceWidgets addObject:widgetClass];
			}
		}
	}
	return result;
}

static inline SBIconListView *GetCurrentIconListView() {
	return [[[%c(SBIconController) sharedInstance] _rootFolderController] currentIconListView];
}

static inline SBIconListView *GetIconListViewAtIndex(NSUInteger index) {
	return [[[%c(SBIconController) sharedInstance] _rootFolderController] iconListViewAtIndex:index];
}

static inline CGSize GetIconSize(SBIconListView *iconListView) {
	CGSize iconSize = CGSizeZero;
	if ([iconListView respondsToSelector:@selector(alignmentIconSize)]) {
		iconSize = [iconListView alignmentIconSize];
	} else if ([iconListView respondsToSelector:@selector(defaultIconSize)]) {
		iconSize = [iconListView defaultIconSize];
	}
	return iconSize;
}

static inline BOOL IsDraggingIcon() {
	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	if ([iconController respondsToSelector:@selector(iconDragManager)] && [[iconController iconDragManager] isIconDragging])
		return YES;
	else if ([iconController respondsToSelector:@selector(grabbedIcon)] && [iconController grabbedIcon] != nil)
		return YES;
	return NO;
}

static inline void MarkIconPositions(NSMutableArray<HSWidgetAvailablePositionObject *> *positions, NSUInteger numIconsToMark) {
	numIconsToMark = MIN(numIconsToMark, positions.count);
	// POTENTIAL TODO: Instead of marking the first x positions for x icons, mark the grid position
	// the icon actually takes up for better compatibility with custom icon position tweaks
	for (NSUInteger iconIndex = 0; iconIndex < numIconsToMark; ++iconIndex) {
		positions[iconIndex].containsIcon = YES;
	}
}

static inline void RemoveIconPostions(NSMutableArray<HSWidgetAvailablePositionObject *> *positions, NSUInteger numIconsToRemove) {
	numIconsToRemove = MIN(numIconsToRemove, positions.count);
	// POTENTIAL TODO: Instead of removing the first x positions for x icons, remove the grid position
	// the icon actually takes up for better compatibility with custom icon position tweaks
	[positions removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numIconsToRemove)]];
}

static inline void SetFloatingDockHidden(BOOL hidden) {
	if (%c(SBHIconManager)) {
		SBIconController *iconController = [%c(SBIconController) sharedInstance];
		if (hidden) {
			// hide the floating dock
			iconController.iconManager.floatingDockViewController.dockOffscreenProgress = 1.0;
		} else {
			// unhide the floating dock
			iconController.iconManager.floatingDockViewController.dockOffscreenProgress = 0.0;
		}
	}
}

static inline void SetEditingEndTimer(BOOL shouldRestart) {
	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	if (shouldRestart) {
		// restart editing end timer
		if ([iconController respondsToSelector:@selector(_restartEditingEndTimer)]) {
			[iconController _restartEditingEndTimer];
		} else if (%c(SBHIconManager) && [iconController.iconManager respondsToSelector:@selector(_restartEditingEndTimer)]) {
			[iconController.iconManager _restartEditingEndTimer];
		}
	} else {
		// stop editing end timer
		if ([iconController respondsToSelector:@selector(_restartEditingEndTimer)]) {
			[iconController.editingEndTimer invalidate];
			iconController.editingEndTimer = nil;
		} else if (%c(SBHIconManager) && [iconController.iconManager respondsToSelector:@selector(_restartEditingEndTimer)]) {
			[iconController.iconManager.editingEndTimer invalidate];
			iconController.iconManager.editingEndTimer = nil;
		}
	}
}

static inline void PresentViewControllerInNavigationController(UIViewController *presentedViewController, UIViewController *rootViewController, BOOL animated, void (^completionHandler)(void)) {
	SetEditingEndTimer(NO);

	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
	navigationController.navigationBar.translucent = NO;

	// setup background color
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
	UIColor *backgroundColor = [UIColor respondsToSelector:@selector(systemGroupedBackgroundColor)] ? [UIColor systemGroupedBackgroundColor] : [UIColor whiteColor];
#pragma clang diagnostic pop
	rootViewController.view.backgroundColor = backgroundColor;
	navigationController.view.backgroundColor = backgroundColor;
	navigationController.navigationBar.barTintColor = backgroundColor;
	presentedViewController.view.backgroundColor = backgroundColor;

	// add navigation controller to widget picker
	[presentedViewController addChildViewController:navigationController];
	[presentedViewController.view addSubview:navigationController.view];
	[navigationController didMoveToParentViewController:presentedViewController];

	UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
	if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		// constraint to readable guide for iPad
		navigationController.view.translatesAutoresizingMaskIntoConstraints = NO;
		[navigationController.view.topAnchor constraintEqualToAnchor:presentedViewController.view.readableContentGuide.topAnchor].active = YES;
		[navigationController.view.bottomAnchor constraintEqualToAnchor:presentedViewController.view.readableContentGuide.bottomAnchor].active = YES;
		[navigationController.view.leadingAnchor constraintEqualToAnchor:presentedViewController.view.readableContentGuide.leadingAnchor].active = YES;
		[navigationController.view.trailingAnchor constraintEqualToAnchor:presentedViewController.view.readableContentGuide.trailingAnchor].active = YES;
		
		// cover full screen on iPad
		presentedViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
	}

	// [[%c(SpringBoard) sharedApplication] addDisableActiveInterfaceOrientationChangeAssertion:PICKER_ROTATION_ASSERTION_REASON];

	// setup style for 
	if ([presentedViewController respondsToSelector:@selector(setModalInPresentation:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
		[presentedViewController setModalInPresentation:YES];
#pragma clang diagnostic pop
	}

	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	[iconController presentViewController:presentedViewController animated:YES completion:completionHandler];

	// hide floating dock since its in a separate window
	if (%c(SBHIconManager)) {
		[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
			SetFloatingDockHidden(YES);
		} completion:nil];
	}
	
	[navigationController release];
}

static inline void RemoveViewController(UIViewController *viewController, BOOL animated, void (^completionHandler)(void)) {
	[viewController dismissViewControllerAnimated:animated completion:^{
		// unhide floating dock since its in a separate window and we hid it
		if (%c(SBHIconManager)) {
			[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
				SetFloatingDockHidden(NO);
			} completion:nil];
		}

		/*// remove rotation disable assertions
		SpringBoard *springBoard = [%c(SpringBoard) sharedApplication];
		if ([springBoard respondsToSelector:@selector(removeDisableActiveInterfaceOrientationChangeAssertion:)]) {
			[springBoard removeDisableActiveInterfaceOrientationChangeAssertion:PICKER_ROTATION_ASSERTION_REASON];
		} else if ([springBoard respondsToSelector:@selector(removeDisableActiveInterfaceOrientationChangeAssertion:nudgeOrientationIfRemovingLast:)]) {
			[springBoard removeDisableActiveInterfaceOrientationChangeAssertion:PICKER_ROTATION_ASSERTION_REASON nudgeOrientationIfRemovingLast:NO];
		}*/

		SetEditingEndTimer(YES);

		if (completionHandler != nil) {
			completionHandler();
		}
	}];
}

@implementation HSWidgetPageController
-(instancetype)initWithIconListView:(SBIconListView *)iconListView {
	self = [super init];
	if (self != nil) {
		_iconListView = iconListView;
		_model = [_iconListView model];
		_isRemoving = NO;
		self.draggingWidgetViewController = nil;
		self.newWidgetPositionForDraggingAnimation = HSWidgetPositionZero;
		self.addNewWidgetView = nil;
		self.requiresSaveToFileForWidgetChanges = NO;
		self.widgetPickerViewController = nil;
		self.widgetPreferenceViewController = nil;
		self.shouldDisableWidgetLayout = NO;
	}
	return self;
}

-(void)configureWidgetsIfNeededWithIndex:(NSInteger)index {
	_model = [_iconListView model];
	if (_model.pageLayoutType == PageTypeNone && _model.widgetViewControllers == nil) {
		// confirm correct icon list view index
		if ([_iconListView isEqual:GetIconListViewAtIndex(index)]) {
			SBIconController *iconController = [%c(SBIconController) sharedInstance];
			SBRootFolderController *rootFolderController = [iconController _rootFolderController];
			NSArray *currentPageWidgetLayout = rootFolderController.allPagesWidgetLayouts[[@(index) stringValue]];
			if (currentPageWidgetLayout != nil && [currentPageWidgetLayout count] > 0) {
				_model.pageLayoutType = PageTypeIconsAndWidgetPage;
				_model.widgetViewControllers = [NSMutableArray array];

				for (NSDictionary *currentWidgetPreferences in currentPageWidgetLayout) {
					NSInteger widgetOriginRow = [[currentWidgetPreferences valueForKey:@"WidgetOriginRow"] integerValue];
					NSInteger widgetOriginCol = [[currentWidgetPreferences valueForKey:@"WidgetOriginCol"] integerValue];
					NSInteger widgetNumRows = [[currentWidgetPreferences valueForKey:@"WidgetNumRows"] integerValue];
					NSInteger widgetNumCols = [[currentWidgetPreferences valueForKey:@"WidgetNumCols"] integerValue];

					if (widgetOriginRow == 0 || widgetOriginCol == 0 || widgetNumRows == 0 || widgetNumCols == 0)
						continue; // make sure widget origin and size is valid

					HSWidgetFrame widgetFrame = HSWidgetFrameMake(widgetOriginRow, widgetOriginCol, widgetNumRows, widgetNumCols);
					Class widgetClass = NSClassFromString([currentWidgetPreferences valueForKey:@"WidgetClass"]);
					NSDictionary *widgetOptions = [currentWidgetPreferences valueForKey:@"WidgetOptions"];

					if (widgetClass == nil || ![widgetClass isSubclassOfClass:[HSWidgetViewController class]])
						continue; // make sure the class is subclass of HSWidgetViewController

					HSWidgetViewController *widgetViewController = [[widgetClass alloc] initForWidgetFrame:widgetFrame withOptions:widgetOptions];
					[widgetViewController _setDelegate:self];
					widgetViewController.requestedSize = [self sizeForWidgetSize:widgetFrame.size];
					[_model.widgetViewControllers addObject:widgetViewController];
					[_iconListView addSubview:widgetViewController.view];
				}
			}
		}

		// sort list as other methods depend on list being ordered by the origin row and col for slight peformance enhancements
		if (_model.widgetViewControllers != nil) {
			[_model.widgetViewControllers sortUsingComparator:^NSComparisonResult(HSWidgetViewController *first, HSWidgetViewController *second) {
				if (first.widgetFrame.origin.row < second.widgetFrame.origin.row) {
					return NSOrderedAscending;
				} else if (first.widgetFrame.origin.row > second.widgetFrame.origin.row) {
					return NSOrderedDescending;
				} else { // widgets are on same row
					if (first.widgetFrame.origin.col < second.widgetFrame.origin.col) {
						return NSOrderedAscending;
					} else if (first.widgetFrame.origin.col == second.widgetFrame.origin.col) {
						return NSOrderedSame;
					} else {
						return NSOrderedDescending;
					}
				}
			}];
		}
	}
}

-(void)layoutWidgetPage {
	if (!self.shouldDisableWidgetLayout) {
		for (HSWidgetViewController *widgetViewController in _model.widgetViewControllers) {
			// add to current list view if it isn't already (this happens when list views are recreated)
			if (![widgetViewController.view isDescendantOfView:_iconListView] && !_isRemoving) {
				if (widgetViewController.view.superview != nil)
					[widgetViewController.view removeFromSuperview];
				[widgetViewController _setDelegate:self];
				[_iconListView addSubview:widgetViewController.view];
			}

			// skip dragging widget
			if ([widgetViewController isEqual:self.draggingWidgetViewController]) {
				continue;
			}

			// calculate and set the frame for the widget
			PageType currentPageType = _model.pageLayoutType;
			HSWidgetFrame widgetFrame = widgetViewController.widgetFrame;
			_model.pageLayoutType = PageTypeNone;
			CGFloat originCol = widgetFrame.origin.col;
			if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft)
				originCol += widgetFrame.size.numCols - 1;
			CGPoint origin = [_iconListView originForIconAtCoordinate:SBIconCoordinateMake(widgetFrame.origin.row, originCol)];
			_model.pageLayoutType = currentPageType;
			widgetViewController.requestedSize = [self sizeForWidgetSize:widgetFrame.size];

			widgetViewController.view.frame = (CGRect){origin, widgetViewController.requestedSize};
		}
	}
}

-(void)viewWillTransitionToSize:(CGSize)arg1 withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)arg2 {
	if ([_iconListView isEditing]) {
		// update the add widget view if needed
		[arg2 animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
			self.addNewWidgetView.frame = _iconListView.bounds;
		} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
			self.addNewWidgetView.frame = _iconListView.bounds;

			// update the positions of the available space (required if num rows is not the same as num cols)
			// [self _updateAddWidgetViewAnimated:YES forceRemove:NO includingLastIcon:NO];
		}];
	}

	_model = [_iconListView model];
	for (HSWidgetViewController *widgetViewController in _model.widgetViewControllers) {
		[widgetViewController viewWillTransitionToSize:arg1 withTransitionCoordinator:arg2];
	}
}

-(SBIconCoordinate)coordinateForPoint:(CGPoint)arg1 withRow:(NSInteger)row column:(NSInteger)column {
	// make sure row and column are both set
	PageType currentPageType = _model.pageLayoutType;
	_model.pageLayoutType = PageTypeNone;
	// update the row
	if (row == SBIconCoordinateInvalid) {
		row = [_iconListView rowAtPoint:arg1];
	}
	// update the column
	if (column == SBIconCoordinateInvalid) {
		column = [_iconListView columnAtPoint:arg1];
	}
	_model.pageLayoutType = currentPageType;

	NSInteger iconIndex = [_iconListView indexForCoordinate:SBIconCoordinateMake(row + 1, column + 1) forOrientation:_iconListView.orientation];
	for (HSWidgetPositionObject *position in [[self occupiedWidgetSpaces] reverseObjectEnumerator]) {
		if ([_iconListView indexForCoordinate:SBIconCoordinateMake(position.position) forOrientation:_iconListView.orientation] <= iconIndex - 1)
			--iconIndex;
	}

	return [_iconListView iconCoordinateForIndex:MAX(iconIndex, 0) forOrientation:_iconListView.orientation];
}

-(void)setEditing:(BOOL)editing {
	if (editing) {
		BOOL isCurrentIconListView = [_iconListView isEqual:GetCurrentIconListView()];
		if (self.addNewWidgetView == nil) {
			self.addNewWidgetView = [[HSAddNewWidgetView alloc] initWithFrame:_iconListView.bounds];
			[self.addNewWidgetView setDelegate:self];
			[_iconListView insertSubview:self.addNewWidgetView atIndex:0];

			if (isCurrentIconListView) {
				// prepare for animating in
				self.addNewWidgetView.alpha = 0.0;
			}
		}

		if (isCurrentIconListView) {
			[UIView animateWithDuration:HSWidgetQuickAnimationDuration animations:^{
				self.addNewWidgetView.alpha = 1.0;
			} completion:nil];
		}

		[self _updateAddWidgetViewAnimated:isCurrentIconListView forceRemove:NO includingLastIcon:NO];
	} else {
		void (^removeAddNewWidgetView)() = ^{
			[self.addNewWidgetView removeFromSuperview];
			[self.addNewWidgetView release];
			self.addNewWidgetView = nil;
		};

		if (self.widgetPickerViewController != nil && self.widgetPickerViewController.presentingViewController != nil) {
			removeAddNewWidgetView();

			RemoveViewController(self.widgetPickerViewController, YES, ^{
				[self.widgetPickerViewController release];
				self.widgetPickerViewController = nil;
			});
		} else if (self.widgetPreferenceViewController != nil && self.widgetPreferenceViewController.presentingViewController != nil) {
			removeAddNewWidgetView();

			RemoveViewController(self.widgetPreferenceViewController, YES, ^{
				[self.widgetPreferenceViewController release];
				self.widgetPreferenceViewController = nil;
			});
		} else if ([_iconListView isEqual:GetCurrentIconListView()] && self.addNewWidgetView != nil) {
			[CATransaction begin];
			[CATransaction setCompletionBlock:removeAddNewWidgetView];

			[self _updateAddWidgetViewAnimated:YES forceRemove:YES includingLastIcon:NO];

			SetFloatingDockHidden(NO);

			[CATransaction commit];
		} else if (self.addNewWidgetView != nil) {
			removeAddNewWidgetView();

			SetFloatingDockHidden(NO);
		}
	}
}

-(BOOL)_canWidget:(HSWidgetViewController *)widgetViewController expandOrShrinkToGridPositions:(NSArray *)positions {
	NSUInteger maxRows = [_iconListView iconRowsForCurrentOrientation];
	NSUInteger maxCols = [_iconListView iconColumnsForCurrentOrientation];

	// get available positions for widgets to move
	NSMutableArray<HSWidgetAvailablePositionObject *> *availableSpaceForWidgetExpandOrShrink = [NSMutableArray arrayWithCapacity:maxRows * maxCols];
	[availableSpaceForWidgetExpandOrShrink addObjectsFromArray:[self availableSpaceWithRule:HSWidgetAvailableSpaceRuleIncludeIconsWithMark]];
	for (HSWidgetPositionObject *position in widgetViewController._gridPositions) {
		[availableSpaceForWidgetExpandOrShrink addObject:[HSWidgetAvailablePositionObject objectWithAvailableWidgetPosition:position.position containingIcon:NO]];
	}

	return [HSWidgetGridPositionConverterCache canFitWidget:positions inGridPositions:availableSpaceForWidgetExpandOrShrink];
}

-(BOOL)canWidget:(HSWidgetViewController *)widgetViewController expandOrShrinkToGridPositions:(NSArray<HSWidgetPositionObject *> *)positions {
	NSInteger additionalIconSpacesRequired = positions.count - widgetViewController._gridPositions.count;
	NSMutableArray *newPositions = [NSMutableArray arrayWithArray:positions];
	[newPositions removeObjectsInArray:widgetViewController._gridPositions];
	if (additionalIconSpacesRequired == 0 && newPositions.count == 0) { // no change
		return NO;
	} else if (additionalIconSpacesRequired < 0 && newPositions.count == 0) { // shrinking size
		return positions.count != 0;
	} else if (additionalIconSpacesRequired <= 0 && newPositions.count > 0) { // change of shape (may be shrinking as well)
		// POTENTIAL TODO: create different method for handling shape changes
		BOOL canExpand = [self _canWidget:widgetViewController expandOrShrinkToGridPositions:positions];
		// POTENTIAL TODO: maybe try move other widgets to see if it can fit then
		return canExpand;
	} else if (additionalIconSpacesRequired > 0) { // expanding size
		NSUInteger maxIconCountForPage = [_model maxNumberOfIcons];
		NSUInteger currentIconCount = ((NSMutableArray *)[_iconListView icons]).count;
		NSUInteger availableIconCount = maxIconCountForPage - currentIconCount;
		if (additionalIconSpacesRequired > availableIconCount) {
			return NO; // not enough space for expanding
		}
		BOOL canExpand = [self _canWidget:widgetViewController expandOrShrinkToGridPositions:positions];
		// POTENTIAL TODO: maybe try move other widgets to see if it can fit then
		return canExpand;
	} else { // unknown case
		return NO;
	}
}

-(void)closeTapped:(HSWidgetViewController *)widgetViewController {
	if (_model.widgetViewControllers != nil) {
		[_model.widgetViewControllers removeObject:widgetViewController];
		[widgetViewController _setDelegate:nil];

		// POTENTIAL TODO: move other widgets up if they were placed below the widget being removed

		// changes made to widget layout so they need to be saved
		self.requiresSaveToFileForWidgetChanges = YES;

		_model = [_iconListView model]; // update maxIconCount for current page

		SetEditingEndTimer(YES);

		// widget removal animation
		CGPoint startingCenter = CGPointMake(widgetViewController.view.center.x, widgetViewController.view.frame.origin.y);
		widgetViewController.view.alpha = 1.0;
		[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
			widgetViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
			widgetViewController.view.center = startingCenter;
			widgetViewController.view.alpha = 0.0;
			[_iconListView layoutIconsNow]; // animate icons
		} completion:^(BOOL finished) {
			if (finished) {
				[widgetViewController.view removeFromSuperview];
				[widgetViewController release];

				if ([_model.widgetViewControllers count] == 0) {
					_model.pageLayoutType = PageTypeNone;
					_model.widgetViewControllers = nil;
				}
			}
		}];

		[self _updateAddWidgetViewAnimated:YES forceRemove:NO includingLastIcon:NO];

		// notify widgets about available space being changed
		[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAvailableSpaceDidChangeNotification object:nil userInfo:nil];
	}
}

-(void)settingsTapped:(HSWidgetViewController *)widgetViewController {
	Class preferencesOptionsControllerClass = [[widgetViewController class] preferencesOptionsControllerClass];
	if (preferencesOptionsControllerClass != nil) {
		// setup the preferences option controller
		UIViewController *preferencesOptionsController = [preferencesOptionsControllerClass alloc];
		if ([preferencesOptionsControllerClass conformsToProtocol:@protocol(HSWidgetPreferences)]) {
			NSArray *availableSpaces = [self availableSpaceWithRule:HSWidgetAvailableSpaceRuleIncludeIconsWithMark];
			[(UIViewController<HSWidgetPreferences> *)preferencesOptionsController initWithWidgetViewController:widgetViewController availablePositions:availableSpaces];
		} else if ([preferencesOptionsController respondsToSelector:@selector(initForContentSize:)]) {
			SBIconController *iconController = [%c(SBIconController) sharedInstance];
			CGSize contentSize = iconController.view.bounds.size;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
			preferencesOptionsController = [preferencesOptionsController initForContentSize:contentSize];
#pragma clang diagnostic pop
		} else {
			preferencesOptionsController = [preferencesOptionsController init];
		}

		self.widgetPreferenceViewController = [[HSWidgetUnrotateableViewController alloc] init];
		PresentViewControllerInNavigationController(self.widgetPreferenceViewController, preferencesOptionsController, YES, nil);

		// add done button if there isn't a right bar button already
		if (preferencesOptionsController.navigationItem.rightBarButtonItems.count == 0) {
			UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_dismissPreferencesOptionsController)];
			preferencesOptionsController.navigationItem.rightBarButtonItems = @[doneButton];
			[doneButton release];
		}
		
		[preferencesOptionsController release];
	}
}

-(void)widgetOptionsChanged:(HSWidgetViewController *)widgetViewController {
	// changes made to widget options they need to be saved
	self.requiresSaveToFileForWidgetChanges = YES;
}

-(void)_dismissPreferencesOptionsController {
	RemoveViewController(self.widgetPreferenceViewController, YES, ^{
		[self.widgetPreferenceViewController release];
		self.widgetPreferenceViewController = nil;
	});
}

-(BOOL)canDragWidget:(HSWidgetViewController *)widgetViewController {
	return !IsDraggingIcon() && (self.draggingWidgetViewController == nil || [widgetViewController isEqual:self.draggingWidgetViewController]);
}

-(void)setDraggingWidget:(HSWidgetViewController *)widgetViewController {
	// update current dragging widget and can add more widgets
	self.draggingWidgetViewController = widgetViewController;

	BOOL isDraggingWidget = (widgetViewController != nil);
	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	iconController.isDraggingWidget = isDraggingWidget;
	if (!isDraggingWidget) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateWidgetDrag) object:nil];
		[self _updateWidgetDrag];
		[self layoutWidgetPage];

		SetEditingEndTimer(YES);
	} else {
		[_iconListView bringSubviewToFront:self.draggingWidgetViewController.view];
		self.newWidgetPositionForDraggingAnimation = self.draggingWidgetViewController.widgetFrame.origin;

		// pre-emptively notify widgets about available space being changed if the widget was dragged quickly
		[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAvailableSpaceDidChangeNotification object:nil userInfo:nil];

		SetEditingEndTimer(NO);
	}
}

-(void)widgetDragged:(HSWidgetViewController *)widgetViewController toPoint:(CGPoint)point {
	if (_model.widgetViewControllers != nil && widgetViewController != nil) {
		// move widget with the finger
		CGRect frame = widgetViewController.view.frame;
		frame.origin = point;
		widgetViewController.view.frame = frame;

		@autoreleasepool {
			// get the unmodified icon coordinate
			PageType currentPageType = _model.pageLayoutType;
			_model.pageLayoutType = PageTypeNone;
			SBIconCoordinate newWidgetOrigin = SBIconCoordinateMake([_iconListView rowAtPoint:point] + 1, [_iconListView columnAtPoint:point] + 1);
			_model.pageLayoutType = currentPageType;

			// get the shifted grid positions
			HSWidgetFrame widgetFrame = widgetViewController.widgetFrame;
			if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft)
				newWidgetOrigin.col -= widgetFrame.size.numCols - 1;

			NSInteger diffRow = newWidgetOrigin.row - widgetFrame.origin.row;
			NSInteger diffCol = newWidgetOrigin.col - widgetFrame.origin.col;
			if (diffRow != 0 || diffCol != 0) {
				NSUInteger maxRows = [_iconListView iconRowsForCurrentOrientation];
				NSUInteger maxCols = [_iconListView iconColumnsForCurrentOrientation];

				NSArray<HSWidgetPositionObject *> *widgetPositions = widgetViewController._gridPositions;
				NSMutableArray<HSWidgetPositionObject *> *shiftedGridPositions = [NSMutableArray arrayWithCapacity:widgetPositions.count];
				for (HSWidgetPositionObject *position in widgetPositions) {
					HSWidgetPosition shiftedWidgetPosition = HSWidgetPositionAdd(position.position, diffRow, diffCol);
					if (HSWidgetPositionIsValid(shiftedWidgetPosition, maxRows, maxCols)) {
						[shiftedGridPositions addObject:[HSWidgetPositionObject objectWithWidgetPosition:shiftedWidgetPosition]];
					} else {
						return;
					}
				}

				// get available positions for widgets to move
				NSMutableArray<HSWidgetAvailablePositionObject *> *availableSpaceForWidgetMovement = [NSMutableArray arrayWithCapacity:maxRows * maxCols];
				[availableSpaceForWidgetMovement addObjectsFromArray:[self availableSpaceWithRule:HSWidgetAvailableSpaceRuleIncludeIconsWithMark]];
				for (HSWidgetPositionObject *position in widgetPositions) {
					[availableSpaceForWidgetMovement addObject:[HSWidgetAvailablePositionObject objectWithAvailableWidgetPosition:position.position containingIcon:NO]];
				}

				// check if widget can move to the shifted positions
				HSWidgetFrame newWidgetFrame = HSWidgetFrameMake(HSWidgetPositionMake(newWidgetOrigin), widgetFrame.size);
				if ([HSWidgetGridPositionConverterCache canFitWidget:shiftedGridPositions inGridPositions:availableSpaceForWidgetMovement]) {
					widgetViewController.widgetFrame = newWidgetFrame;
					widgetViewController.widgetFrame = widgetFrame;

					if (!HSWidgetPositionEqualsPosition(widgetFrame.origin, newWidgetFrame.origin)) {
						self.newWidgetPositionForDraggingAnimation = newWidgetFrame.origin;
						[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateWidgetDrag) object:nil];
						[self performSelector:@selector(_updateWidgetDrag) withObject:nil afterDelay:DRAGGING_WIDGET_HOLD_DURATION];
					}
				}
			}
		}
	}
}

-(void)updatePageForExpandOrShrinkOfWidget:(HSWidgetViewController *)widgetViewController toGridPositions:(NSArray *)positions {
	// changes made to widget layout so they need to be saved
	self.requiresSaveToFileForWidgetChanges = YES;

	_model = [_iconListView model]; // update maxIconCount for current page

	SetEditingEndTimer(YES);

	// TODO: maybe move other widgets if needed but for now assume it fits

	[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
		[_iconListView layoutIconsNow]; // animate icons and current widget

		[widgetViewController.view layoutIfNeeded];
	} completion:nil];

	[self _updateAddWidgetViewAnimated:YES forceRemove:NO includingLastIcon:NO];

	// notify widgets about available space being changed
	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAvailableSpaceDidChangeNotification object:nil userInfo:nil];
}

-(void)_updateWidgetDrag {
	// update widget ordering if needed
	if (!HSWidgetPositionEqualsPosition(self.newWidgetPositionForDraggingAnimation, self.draggingWidgetViewController.widgetFrame.origin)) {
		HSWidgetFrame newWidgetFrame = HSWidgetFrameMake(self.newWidgetPositionForDraggingAnimation, self.draggingWidgetViewController.widgetFrame.size);
		self.draggingWidgetViewController.widgetFrame = newWidgetFrame;
		self.requiresSaveToFileForWidgetChanges = YES;

		// sort the widgets based on origin row and row
		[_model.widgetViewControllers sortUsingComparator:^NSComparisonResult(HSWidgetViewController *first, HSWidgetViewController *second) {
			if (first.widgetFrame.origin.row < second.widgetFrame.origin.row) {
				return NSOrderedAscending;
			} else if (first.widgetFrame.origin.row > second.widgetFrame.origin.row) {
				return NSOrderedDescending;
			} else { // widgets are on same row
				if (first.widgetFrame.origin.col < second.widgetFrame.origin.col) {
					return NSOrderedAscending;
				} else if (first.widgetFrame.origin.col == second.widgetFrame.origin.col) {
					return NSOrderedSame;
				} else {
					return NSOrderedDescending;
				}
			}
		}];
	}

	// animate icon moving based on new widget location
	[_iconListView bringSubviewToFront:self.draggingWidgetViewController.view];
	[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
		[_iconListView layoutIconsNow];
	} completion:nil];

	[self _updateAddWidgetViewAnimated:YES forceRemove:NO includingLastIcon:NO];

	// notify widgets about available space being changed
	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAvailableSpaceDidChangeNotification object:nil userInfo:nil];
}

-(void)addNewWidgetTappedForPosition:(HSWidgetPosition)position {
	// get list of available widget classes for available free spaces
	NSArray *availableSpaces = [self availableSpaceWithRule:HSWidgetAvailableSpaceRuleIncludeIconsWithMark];
	NSMutableArray *insufficientSpaceWidgets = [NSMutableArray array];
	NSArray *availableWidgetClasses = AvailableWidgetControllerClassesForAvailableSpaces(availableSpaces, insufficientSpaceWidgets);

	// get list of widget options to exclude
	NSMutableDictionary *widgetOptionsToExclude = [NSMutableDictionary dictionary];
	for (HSWidgetViewController *widgetViewController in _model.widgetViewControllers) {
		NSString *currentKey = NSStringFromClass([widgetViewController class]);
		NSMutableArray *widgetsForCurrentClass = [widgetOptionsToExclude objectForKey:currentKey];
		if (widgetsForCurrentClass == nil) {
			widgetsForCurrentClass = [NSMutableArray array];
		}
		[widgetsForCurrentClass addObject:[widgetViewController options] ?: [NSDictionary dictionary]];
		[widgetOptionsToExclude setObject:widgetsForCurrentClass forKey:currentKey];
	}

	// create widget view controllers that will contain the list of available widgets
	HSAddWidgetRootViewController *widgetPickerTableViewController = [[HSAddWidgetRootViewController alloc] initWithWidgets:availableWidgetClasses insufficientSpaceWidgets:insufficientSpaceWidgets excludingWidgetsOptions:widgetOptionsToExclude];
	[widgetPickerTableViewController setDelegate:self];
	widgetPickerTableViewController.preferredPosition = position;
	widgetPickerTableViewController.availablePositions = availableSpaces;

	self.widgetPickerViewController = [[HSWidgetUnrotateableViewController alloc] init];
	PresentViewControllerInNavigationController(self.widgetPickerViewController, widgetPickerTableViewController, YES, nil);

	[widgetPickerTableViewController release];
}

-(void)cancelAddWidgetAnimated:(BOOL)animated {
	RemoveViewController(self.widgetPickerViewController, animated, ^{
		[self.widgetPickerViewController release];
		self.widgetPickerViewController = nil;
	});
}

-(void)addWidgetOfClass:(Class)widgetClass withWidgetFrame:(HSWidgetFrame)widgetFrame options:(NSDictionary *)options {
	if (_model.widgetViewControllers == nil) {
		_model.pageLayoutType = PageTypeIconsAndWidgetPage;
		_model.widgetViewControllers = [NSMutableArray array];
	}

	// create widget view controller and add it to view hierarchy
	CGSize finalRequestedSize = [self sizeForWidgetSize:widgetFrame.size];
	HSWidgetViewController *widgetViewController = [[widgetClass alloc] initForWidgetFrame:widgetFrame withOptions:options];
	[widgetViewController _setDelegate:self];
	widgetViewController.requestedSize = finalRequestedSize;
	[_model.widgetViewControllers addObject:widgetViewController];

	// changes made to widget layout so they need to be saved
	self.requiresSaveToFileForWidgetChanges = YES;
	
	PageType currentPageType = _model.pageLayoutType;
	_model.pageLayoutType = PageTypeNone;
	CGFloat originCol = widgetFrame.origin.col;
	if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft)
		originCol += widgetFrame.size.numCols - 1;
	CGPoint origin = [_iconListView originForIconAtCoordinate:SBIconCoordinateMake(widgetFrame.origin.row, originCol)];
	_model.pageLayoutType = currentPageType;

	_model = [_iconListView model]; // update maxIconCount for current page

	void (^animateWidgetAddition)() = ^{
		[_iconListView addSubview:widgetViewController.view];
		widgetViewController.view.frame = CGRectMake(origin.x, origin.y, widgetViewController.requestedSize.width, widgetViewController.requestedSize.height);

		// widget addition animation
		widgetViewController.view.alpha = 0.0;
		widgetViewController.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
		self.shouldDisableWidgetLayout = YES; // disable widget layout so there are no animation issues
		[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
			[_iconListView layoutIconsNow]; // update icon position

			widgetViewController.view.alpha = 1.0;
			widgetViewController.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
			widgetViewController.requestedSize = finalRequestedSize;

			SetFloatingDockHidden(NO);
		} completion:^(BOOL finished) {
			self.shouldDisableWidgetLayout = NO;
		}];
	};

	RemoveViewController(self.widgetPickerViewController, YES, ^{
		[self.widgetPickerViewController release];
		self.widgetPickerViewController = nil;

		animateWidgetAddition();
	});

	[self _updateAddWidgetViewAnimated:YES forceRemove:NO includingLastIcon:NO];

	// notify widgets about available space being changed
	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAvailableSpaceDidChangeNotification object:nil userInfo:nil];
}

-(NSArray<HSWidgetAvailablePositionObject *> *)availableSpaceWithRule:(HSWidgetAvailableSpaceRule)rule {
	_model = [_iconListView model];

	NSUInteger maxRows = [_iconListView iconRowsForCurrentOrientation];
	NSUInteger colsPerRow = [_iconListView iconColumnsForCurrentOrientation];

	__block NSMutableArray<HSWidgetAvailablePositionObject *> *result = [NSMutableArray arrayWithCapacity:maxRows * colsPerRow];
	__block NSMutableArray<HSWidgetViewController *> *widgetViewControllers = _model.widgetViewControllers;
	@autoreleasepool {
		for (NSUInteger row = 1; row <= maxRows; ++row) {
			for (NSUInteger col = 1; col <= colsPerRow; ++col) {
				[result addObject:[HSWidgetAvailablePositionObject objectWithAvailableWidgetPosition:HSWidgetPositionMake(row, col) containingIcon:NO]];
			}
		}

		for (HSWidgetViewController *widgetViewController in widgetViewControllers) {
			for (__block HSWidgetPositionObject *position in widgetViewController._gridPositions) {
				NSUInteger gridPositionIndex = [result indexOfObjectPassingTest:^(HSWidgetAvailablePositionObject *availablePosition, NSUInteger index, BOOL *stop) {
					return [availablePosition isEqual:position];
				}];
				
				if (gridPositionIndex != NSNotFound) {
					[result removeObjectAtIndex:gridPositionIndex];
				} else {
					// something really bad happened...
				}
			}
		}

		NSUInteger numIcons = ((NSMutableArray *)[_iconListView icons]).count;
		if (rule == HSWidgetAvailableSpaceRuleIncludeIconsWithMark) {
			MarkIconPositions(result, numIcons);
		} else if (rule == HSWidgetAvailableSpaceRuleIncludeIconsWithMarkExceptLast) {
			MarkIconPositions(result, numIcons - 1);
		} else if (rule == HSWidgetAvailableSpaceRuleExcludeIcons) {
			RemoveIconPostions(result, numIcons);
		} else if (rule == HSWidgetAvailableSpaceRuleExcludeIconsExceptLast) {
			RemoveIconPostions(result, numIcons - 1);
		}
	}
	return [NSArray arrayWithArray:result];
}

-(NSArray<HSWidgetPositionObject *> *)occupiedWidgetSpaces {
	NSUInteger maxRows = [_iconListView iconRowsForCurrentOrientation];
	NSUInteger colsPerRow = [_iconListView iconColumnsForCurrentOrientation];

	NSMutableArray<HSWidgetPositionObject *> *result = [NSMutableArray arrayWithCapacity:maxRows * colsPerRow];
	@autoreleasepool {
		for (HSWidgetViewController *widgetViewController in _model.widgetViewControllers) {
			for (HSWidgetPositionObject *position in widgetViewController._gridPositions) {
				[result addObject:position];
			}
		}

		// sort the positions
		[result sortUsingComparator:^(HSWidgetPositionObject *first, HSWidgetPositionObject *second) {
			if (first.row < second.row) {
				return NSOrderedAscending;
			} else if (first.row > second.row) {
				return NSOrderedDescending;
			} else { // same row
				if (first.col < second.col) {
					return NSOrderedAscending;
				} else if (first.col == second.col) {
					return NSOrderedSame;
				} else {
					return NSOrderedDescending;
				}
			}
		}];
	}
	return result;
}

-(void)_updateAddWidgetViewAnimated:(BOOL)animated forceRemove:(BOOL)remove includingLastIcon:(BOOL)included {
	NSInteger numIcons = ((NSMutableArray *)[_iconListView icons]).count;

	HSWidgetAvailableSpaceRule rule = included ? HSWidgetAvailableSpaceRuleIncludeIconsWithMarkExceptLast : HSWidgetAvailableSpaceRuleIncludeIconsWithMark;
	NSArray *availableSpaceForWidgets = [self availableSpaceWithRule:rule];

	BOOL areWidgetsAvailableForCurrentEmptySpace = [AvailableWidgetControllerClassesForAvailableSpaces(availableSpaceForWidgets, nil) count] > 0;
	if (!areWidgetsAvailableForCurrentEmptySpace || remove || numIcons == 0 || IsDraggingIcon()) {
		availableSpaceForWidgets = nil;
	}

	NSPredicate *nonIconPositionsPredicate = [NSPredicate predicateWithFormat:@"containsIcon == NO"];
	NSArray *nonIconAvailablePositions = [availableSpaceForWidgets filteredArrayUsingPredicate:nonIconPositionsPredicate];
	[self.addNewWidgetView updateAvailableSpaces:nonIconAvailablePositions withAnimationDuration:animated ? HSWidgetAnimationDuration : 0.0];
}

-(void)animateUpdateOfIconChangesExcludingCurrentIcon:(BOOL)excluded completion:(void(^)(void))completion {
	if ([_iconListView isEditing]) {
		NSUInteger numIcons = ((NSMutableArray *)[_iconListView icons]).count;
		NSUInteger maxIconCountForPage = [_model maxNumberOfIcons];
		NSUInteger iconsRequiredToRemove = excluded ? 1 : 0;
		BOOL shouldRemoveFromPage = numIcons <= iconsRequiredToRemove;
		if (numIcons <= maxIconCountForPage) {
			[CATransaction begin];
			[CATransaction setCompletionBlock:^{
				if (completion != nil) {
					completion();
				}
			}];

			if (shouldRemoveFromPage && _model != nil) {
				NSArray *currentWidgetViewControllers = [NSArray arrayWithArray:_model.widgetViewControllers];
				for (HSWidgetViewController *widgetViewController in currentWidgetViewControllers) {
					[self closeTapped:widgetViewController];
				}
			}

			[self _updateAddWidgetViewAnimated:YES forceRemove:shouldRemoveFromPage includingLastIcon:excluded];

			[CATransaction commit];
		} else if (completion != nil) {
			completion();
		}

		// notify widgets about available space being changed
		[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAvailableSpaceDidChangeNotification object:nil userInfo:nil];
	} else if (completion != nil) {
		completion();
	}
}

-(HSWidgetPosition)widgetOriginForWidgetSize:(HSWidgetSize)size withPreferredOrigin:(HSWidgetPosition)position {
	NSUInteger maxRows = [_iconListView iconRowsForCurrentOrientation];
	NSUInteger maxCols = [_iconListView iconColumnsForCurrentOrientation];
	NSInteger diffRow = maxRows - (position.row + size.numRows - 1);
	NSInteger diffCol = maxCols - (position.col + size.numCols - 1);
	HSWidgetPosition widgetOrigin = HSWidgetPositionAdd(position, MIN(diffRow, 0), MIN(diffCol, 0));
	return HSWidgetPositionIsValid(widgetOrigin, maxRows, maxCols) ? widgetOrigin : HSWidgetPositionZero;
}

-(CGSize)sizeForWidgetSize:(HSWidgetSize)size {
	CGSize iconSize = GetIconSize(_iconListView);
	// fix iconSize on iOS 13
	CGFloat additionalHeight = 0;
	Class iconListViewClass = [_iconListView class];
	if ([iconListViewClass respondsToSelector:@selector(defaultIconViewConfigurationOptions)]) {
		Class baseIconViewClass = [_iconListView baseIconViewClass];
		CGSize iconViewSize = [baseIconViewClass defaultIconViewSize];
		NSUInteger configuration = [iconListViewClass defaultIconViewConfigurationOptions];
		additionalHeight = [baseIconViewClass defaultIconViewSizeForIconImageSize:iconViewSize configurationOptions:configuration].height - iconViewSize.height;
	}
	
	CGFloat width = iconSize.width * size.numCols + (size.numCols > 1 ? [_iconListView horizontalIconPadding] * (size.numCols - 1) : 0);
	CGFloat height = iconSize.height * size.numRows + (size.numRows > 1 ? [_iconListView verticalIconPadding] * (size.numRows - 1) : 0) + additionalHeight;
	return CGSizeMake(width, height);
}

-(CGRect)rectForWidgetPosition:(HSWidgetPosition)position {
	CGSize iconSize = GetIconSize(_iconListView);
	PageType currentPageType = _model.pageLayoutType;
	_model.pageLayoutType = PageTypeNone;
	CGPoint origin = [_iconListView originForIconAtCoordinate:SBIconCoordinateMake(position)];
	_model.pageLayoutType = currentPageType;
	CGFloat minLength = MIN(iconSize.width, iconSize.height);
	return CGRectMake(origin.x, origin.y, minLength, minLength);
}

-(void)dealloc {
	_isRemoving = YES;

	_iconListView = nil;
	_model = nil;
	self.draggingWidgetViewController = nil;

	if (self.addNewWidgetView != nil) {
		[self.addNewWidgetView removeFromSuperview];
		[self.addNewWidgetView release];
		self.addNewWidgetView = nil;
	}

	if (self.widgetPickerViewController != nil) {
		RemoveViewController(self.widgetPickerViewController, NO, ^{
			[self.widgetPickerViewController release];
			self.widgetPickerViewController = nil;
		});
	}

	if (self.widgetPreferenceViewController != nil) {
		RemoveViewController(self.widgetPreferenceViewController, NO, ^{
			[self.widgetPreferenceViewController release];
			self.widgetPreferenceViewController = nil;
		});
	}

	[super dealloc];
}
@end

@interface ISIconSupport : NSObject
+(id)sharedInstance;
-(BOOL)addExtension:(NSString *)extension;
@end

%ctor {
	if (dlopen("/Library/MobileSubstrate/DynamicLibraries/IconSupport.dylib", RTLD_NOW) != NULL && %c(ISIconSupport)) {
		[[%c(ISIconSupport) sharedInstance] addExtension:@"com.dgh0st.hswidgets"];
	}

	[HSWidgetLoader loadAllWidgets];
}

%dtor {
	[HSWidgetLoader unloadAllWidgets];
}
