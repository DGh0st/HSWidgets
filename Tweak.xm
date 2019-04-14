#import <UIKit/UIKit.h>
#import <vector>
#import "HSWidgetViewController.h"
#import "HSAddNewWidgetView.h"
#import "HSAddWidgetRootViewController.h"


// One of SpringBoard structs (iOS 7 - 11)
typedef struct SBIconCoordinate {
	NSInteger row;
	NSInteger col;
} SBIconCoordinate;

// manage current page type
typedef NS_ENUM(NSUInteger, PageType) {
	kNone = 0,
	kWidgetPage
};

@interface SBIconListModel // iOS 4 - 12
@property (nonatomic, assign) NSUInteger pageLayoutType; // PageType enum
@property (nonatomic, retain) NSMutableArray *widgetViewControllers;
@end

%hook SBIconListModel
%property (nonatomic, assign) NSUInteger pageLayoutType; // PageType enum
%property (nonatomic, retain) NSMutableArray *widgetViewControllers;

-(id)initWithFolder:(id)arg1 maxIconCount:(NSUInteger)arg2 {
	self = %orig;
	if (self != nil) {
		self.pageLayoutType = kNone;
		self.widgetViewControllers = nil;
	}
	return self;
}

-(void)dealloc {
	if (self.widgetViewControllers != nil) {
		for (HSWidgetViewController *widgetViewController in self.widgetViewControllers) {
			[widgetViewController.view removeFromSuperview];
			[widgetViewController release];
		}
		self.widgetViewControllers = nil;
	}

	%orig;
}
%end

@interface SBIconListView : UIView // iOS 4 - 12
@property (nonatomic, assign) UIInterfaceOrientation orientation; // iOS 7 - 12
+(NSUInteger)maxIcons; // iOS 4 - 12
+(NSUInteger)maxVisibleIconRowsInterfaceOrientation:(UIInterfaceOrientation)arg1; // iOS 5 - 12
-(SBIconCoordinate)coordinateForIcon:(id)arg1; // iOS 7 - 12
-(CGPoint)originForIconAtCoordinate:(SBIconCoordinate)arg1; // iOS 7 - 12
-(SBIconCoordinate)coordinateForIconAtIndex:(NSUInteger)arg1; // iOS 7 - 12
-(CGPoint)originForIconAtIndex:(NSUInteger)arg1; // iOS 7 - 12
-(SBIconListModel *)model; // iOS 4 - 12
-(CGSize)defaultIconSize; // iOS 5 - 12
-(CGFloat)verticalIconPadding; // iOS 4 - 12
-(void)layoutIconsNow; // iOS 4 - 12
-(NSUInteger)rowAtPoint:(CGPoint)arg1; // iOS 4 - 12
-(id)icons; // iOS 4 - 12
-(BOOL)isEditing; // iOS 7 - 12
-(CGPoint)centerForIconCoordinate:(SBIconCoordinate)arg1; // iOS 7 - 12
// -(BOOL)containsIcon:(id)arg1; // iOS 7 - 12
@end

// note this class doesn't actually respond to these protocols, its just here to get around the compiler
@interface SBRootIconListView : SBIconListView <HSWidgetDelegate, HSAddNewWidgetDelegate, HSAddWidgetSelectionDelegate> // iOS 7 - 12
@property (nonatomic, retain) HSWidgetViewController *draggingWidgetViewController;
@property (nonatomic, retain) HSAddNewWidgetView *addNewWidgetView;
@property (nonatomic, assign) NSUInteger newRowForDraggingAnimation;
@property (nonatomic, assign) BOOL isWidgetsAvailableForCurrentEmptySpace;
@property (nonatomic, assign) BOOL requiresSaveToFileForWidgetChanges;
@property (nonatomic, retain) UINavigationController *hsWidgetPickerNavigationController;
-(void)_updateAddWidgetViewAndLayerForAvailableSpace:(HSWidgetAvailableSpace)maxAvailableSpace;
-(void)_configureAddWidgetViewIfNeededWithRect:(CGRect)frame withAvailableSpace:(HSWidgetAvailableSpace)availableSpace;
-(CGSize)sizeForWidgetWithNumRows:(NSUInteger)numRows;
-(void)configureWidgetsIfNeededWithIndex:(NSInteger)index;
-(void)layoutWidget;
-(BOOL)containsWidget:(NSString *)identifier;
-(void)_closeTapped:(HSWidgetViewController *)widgetViewController;
-(void)animateUnscatterAfterDelay:(CGFloat)delay;
-(HSWidgetAvailableSpace)maxAvailableSpace;
-(void)_animateUpdateOfIconDraggingWithCompletion:(void(^)(BOOL))completion;
-(void)_animateRemoveOfIconExcludingCurrentIcon:(BOOL)excluded withCompletion:(void(^)(BOOL))completion;
-(void)_updateWidgetDrag;
-(void)_updateWidgetsWithAvailableRows:(HSWidgetAvailableSpace)space;
@end

@interface SBIconController : UIViewController // iOS 3 - 12
@property (nonatomic, assign) BOOL isDraggingWidget;
+(id)sharedInstance; // iOS 3 - 12
-(id)rootIconListAtIndex:(NSInteger)arg1; // iOS 4 - 12
-(id)currentRootIconList; // iOS 7 - 12
-(NSInteger)currentIconListIndex; // iOS 3 - 12
-(NSUInteger)maxColCountForListInRootFolderWithInterfaceOrientation:(NSInteger)arg1; // iOS 7 - 12
-(id)grabbedIcon; // // iOS 3 - 10
-(BOOL)isIconDragging; // iOS 12
-(id)_rootFolderController; // iOS 7 - 12
@end

@interface SBFolderController // iOS 7 - 12
@property (nonatomic, assign) BOOL animatingIconListViewDragLocationChange;
@property (nonatomic, copy, readonly) NSArray *iconListViews; // iOS 7 - 12
@property (nonatomic,readonly) NSUInteger iconListViewCount; // iOS 7 - 12
-(id)currentIconListView; // iOS 7 - 12
-(BOOL)isEditing; // iOS 7 - 12
@end

@interface SBRootFolderController : SBFolderController // iOS 7 - 12
@end

#define kWidgetLayoutPreferencesID CFSTR("com.dgh0st.hswidget.widgetlayouts")
#define kWidgetLayoutPreferencesPath @"/var/mobile/Library/Preferences/com.dgh0st.hswidget.widgetlayouts.plist"

static NSMutableDictionary *allPagesWidgetLayouts = nil;

%hook SBRootFolderController
-(void)viewDidLoad {
	%orig;

	if (self.iconListViews != nil) {
		for (NSInteger listViewIndex = 0; listViewIndex < self.iconListViewCount; ++listViewIndex) {
			id iconListView = self.iconListViews[listViewIndex];
			if (iconListView != nil && [iconListView isKindOfClass:%c(SBRootIconListView)])
				[(SBRootIconListView *)iconListView configureWidgetsIfNeededWithIndex:listViewIndex];
		}
	}
}

-(void)setEditing:(BOOL)arg1 animated:(BOOL)arg2 {
	BOOL stateDidChange = arg1 != [self isEditing];

	%orig;

	if (stateDidChange && !arg1 && self.iconListViews != nil) {
		BOOL wereAnyChangesMade = NO;
		for (NSInteger listViewIndex = 0; listViewIndex < self.iconListViewCount; ++listViewIndex) {
			id iconListView = self.iconListViews[listViewIndex];
			if (iconListView != nil && [iconListView isKindOfClass:%c(SBRootIconListView)]) {
				SBRootIconListView *rootIconListView = (SBRootIconListView *)iconListView;
				if (rootIconListView.requiresSaveToFileForWidgetChanges) {
					rootIconListView.requiresSaveToFileForWidgetChanges = NO;
					wereAnyChangesMade = YES;

					// save changes to dictionary
					NSString *pageKey = [NSString stringWithFormat:@"%zd", listViewIndex];
					if (rootIconListView.model.widgetViewControllers != nil && [rootIconListView.model.widgetViewControllers count] > 0) {
						NSMutableArray *currentPageWidgetLayout = [NSMutableArray array];
						for (HSWidgetViewController *widgetViewController in rootIconListView.model.widgetViewControllers) {
							[currentPageWidgetLayout addObject:@{
								@"WidgetOriginRow" : @(widgetViewController.originRow),
								@"WidgetClass" : NSStringFromClass([widgetViewController class]),
								@"WidgetOptions" : [widgetViewController options] ?: [NSDictionary dictionary]
							}];
						}
						allPagesWidgetLayouts[pageKey] = currentPageWidgetLayout;
					} else {
						allPagesWidgetLayouts[pageKey] = [NSDictionary dictionary];
					}
				}
			}
		}

		for (NSString *pageKey in allPagesWidgetLayouts.allKeys) {
			if (pageKey != nil && [pageKey intValue] >= self.iconListViewCount) {
				wereAnyChangesMade = YES;
				[allPagesWidgetLayouts removeObjectForKey:pageKey];
			}
		}
		
		if (wereAnyChangesMade)
			[allPagesWidgetLayouts writeToFile:kWidgetLayoutPreferencesPath atomically:YES];
	}
}
%end

#define kDraggingWidgetHoldDuration 0.03

static NSMutableArray *availableHSWidgetClasses = nil;
static std::vector<void *> availableHSWidgetHandlers;
static BOOL shouldDisableWidgetLayout = NO;

static NSMutableArray *availableWidgetControllerClassesForAvailableRows(NSUInteger rows) {
	NSMutableArray *result = [NSMutableArray array];
	for (Class widgetClass in availableHSWidgetClasses)
		if ([widgetClass isSubclassOfClass:[HSWidgetViewController class]] && [widgetClass canAddWidgetForAvailableRows:rows])
			[result addObject:widgetClass];
	return result;
}

%hook SBRootIconListView
%property (nonatomic, retain) HSWidgetViewController *draggingWidgetViewController;
%property (nonatomic, retain) HSAddNewWidgetView *addNewWidgetView;
%property (nonatomic, assign) NSUInteger newRowForDraggingAnimation;
%property (nonatomic, assign) BOOL isWidgetsAvailableForCurrentEmptySpace;
%property (nonatomic, assign) BOOL requiresSaveToFileForWidgetChanges;
%property (nonatomic, retain) UINavigationController *hsWidgetPickerNavigationController;

-(id)init {
	self = %orig;
	if (self != nil) {
		self.draggingWidgetViewController = nil;
		self.addNewWidgetView = nil;
		self.newRowForDraggingAnimation = 0;
		self.requiresSaveToFileForWidgetChanges = NO;
		self.hsWidgetPickerNavigationController = nil;
	}
	return self;
}

-(id)initWithModel:(id)arg1 orientation:(UIInterfaceOrientation)arg2 viewMap:(id)arg3 {
	self = %orig;
	if (self != nil) {
		self.draggingWidgetViewController = nil;
		self.addNewWidgetView = nil;
		self.newRowForDraggingAnimation = 0;
		self.requiresSaveToFileForWidgetChanges = NO;
		self.hsWidgetPickerNavigationController = nil;
	}
	return self;
}

-(void)layoutIconsNow {
	if (!shouldDisableWidgetLayout)
		[self layoutWidget];

	%orig;
}

-(NSUInteger)rowAtPoint:(CGPoint)arg1 {
	// undo our changes to calculate the correct row for editing mode
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	if (model.pageLayoutType != kNone) {
		NSUInteger maxWidgetSpace = 0;
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers)
			maxWidgetSpace += [widgetViewController numRows];
		NSUInteger maxRows = [%c(SBIconListView) maxVisibleIconRowsInterfaceOrientation:self.orientation];
		for (NSInteger i = 0; i < maxRows - maxWidgetSpace - 1; i++) {
			CGFloat verticalIconPadding = [self verticalIconPadding] / 2;
			CGPoint origin = [self originForIconAtCoordinate:(SBIconCoordinate){1 + i, 1}];
			origin.y -= verticalIconPadding;
			CGPoint nextRowOrigin = [self originForIconAtCoordinate:(SBIconCoordinate){2 + i, 1}];
			nextRowOrigin.y -= verticalIconPadding;
			if (arg1.y < origin.y && i == 0) // point above first row
				return 0;
			if (arg1.y >= origin.y && arg1.y < nextRowOrigin.y)
				return i;
		}
		return maxRows - maxWidgetSpace - 1;
	} else {
		return %orig;
	}
}

-(CGPoint)originForIconAtIndex:(NSUInteger)arg1 {
	if (MSHookIvar<SBIconListModel *>(self, "_model").pageLayoutType != kNone)
		return [self originForIconAtCoordinate:[self coordinateForIconAtIndex:arg1]];
	return %orig;
}

-(CGPoint)originForIconAtCoordinate:(SBIconCoordinate)arg1 {
	CGFloat yOffset = 0;
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	BOOL isPreviousWidgetOneRow = NO;
	if (model.pageLayoutType != kNone) {
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			NSUInteger numRows = [widgetViewController numRows];
			if (arg1.row >= widgetViewController.originRow + 1)
				arg1.row += numRows;
			if (numRows > 0 && arg1.row >= widgetViewController.originRow + numRows) {
				yOffset = [self defaultIconSize].height / 3;
				isPreviousWidgetOneRow = (numRows == 1);
			}
			if (yOffset != 0 && arg1.row <= widgetViewController.originRow) {
				yOffset /= 2;
				break;
			}
		}
	}
	CGPoint result = %orig(arg1);
	if (isPreviousWidgetOneRow)
		yOffset = 0;
	result.y -= yOffset; // move icons up a little for better look
	return result;
}

-(CGPoint)originForIcon:(id)arg1 {
	if (MSHookIvar<SBIconListModel *>(self, "_model").pageLayoutType != kNone)
		return [self originForIconAtCoordinate:[self coordinateForIcon:arg1]];
	return %orig;
}

-(id)model {
	// reduce limit of icons for this page as clock takes up 2 rows
	SBIconListModel *result = %orig;
	if (result.pageLayoutType != kNone) {
		NSUInteger numRowsToRemove = 0;
		for (HSWidgetViewController *widgetViewController in result.widgetViewControllers)
			numRowsToRemove += [widgetViewController numRows];
		MSHookIvar<NSUInteger>(result, "_maxIconCount") = [%c(SBRootIconListView) maxIcons] - numRowsToRemove * [[%c(SBIconController) sharedInstance] maxColCountForListInRootFolderWithInterfaceOrientation:self.orientation]; // original - numRows * iconsPerRow
	}
	return result;
}

-(void)setEditing:(BOOL)arg1 {
	BOOL stateDidChange = arg1 != [self isEditing];

	%orig;
	
	if (stateDidChange && ![self isKindOfClass:%c(SBDockIconListView)]) {
		if (arg1) {
			HSWidgetAvailableSpace availableSpace = [self maxAvailableSpace];
			self.isWidgetsAvailableForCurrentEmptySpace = [availableWidgetControllerClassesForAvailableRows(availableSpace.numRows) count] > 0;
			if (self.isWidgetsAvailableForCurrentEmptySpace) {
				[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];

				// animate only if visible
				if ([self isEqual:[[%c(SBIconController) sharedInstance] currentRootIconList]]) {
					CGPoint startingCenter = self.addNewWidgetView.center;
					self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
					[UIView animateWithDuration:kAnimationDuration animations:^{
						self.addNewWidgetView.transform = CGAffineTransformMakeScale(1, 1);
						self.addNewWidgetView.center = startingCenter;
					} completion:nil];
				}
			}
		} else {
			void (^removeAddNewWidgetView)() = ^{
				[self.addNewWidgetView removeFromSuperview];
				[self.addNewWidgetView release];
				self.addNewWidgetView = nil;
			};

			if (self.hsWidgetPickerNavigationController != nil) {
				self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
				removeAddNewWidgetView();

				[self.hsWidgetPickerNavigationController dismissViewControllerAnimated:YES completion:^{
					[self.hsWidgetPickerNavigationController release];
					self.hsWidgetPickerNavigationController = nil;
				}];
			} else if ([self isEqual:[[%c(SBIconController) sharedInstance] currentRootIconList]] && self.addNewWidgetView != nil) {
				// animate only if visible
				CGPoint startingCenter = self.addNewWidgetView.center;
				self.addNewWidgetView.transform = CGAffineTransformMakeScale(1, 1);
				[UIView animateWithDuration:kAnimationDuration animations:^{
					self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
					self.addNewWidgetView.center = startingCenter;
				} completion:^(BOOL finished) {
					if (finished)
						removeAddNewWidgetView();
				}];
			} else if (self.addNewWidgetView != nil) {
				removeAddNewWidgetView();
			}
		}
	}
}

-(void)dealloc {
	self.draggingWidgetViewController = nil;

	if (self.addNewWidgetView != nil) {
		[self.addNewWidgetView removeFromSuperview];
		[self.addNewWidgetView release];
		self.addNewWidgetView = nil;
	}

	%orig();
}

%new
-(void)_updateAddWidgetViewAndLayerForAvailableSpace:(HSWidgetAvailableSpace)maxAvailableSpace {
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	self.isWidgetsAvailableForCurrentEmptySpace = [availableWidgetControllerClassesForAvailableRows(maxAvailableSpace.numRows) count] > 0;
	NSUInteger currentPageType = model.pageLayoutType;
	model.pageLayoutType = kNone;
	CGPoint origin = [self originForIconAtCoordinate:(SBIconCoordinate){1 + (NSInteger)maxAvailableSpace.startRow, 1}];
	model.pageLayoutType = currentPageType;

	CGSize size = [self sizeForWidgetWithNumRows:maxAvailableSpace.numRows];
	origin.x = (self.frame.size.width - size.width) / 2;

	[self _configureAddWidgetViewIfNeededWithRect:(CGRect){origin, size} withAvailableSpace:maxAvailableSpace];

	if (![self.addNewWidgetView isDescendantOfView:self])
		[self addSubview:self.addNewWidgetView];
	
	self.addNewWidgetView.frame = (CGRect){origin, size};
	[self.addNewWidgetView setNeedsDisplay];
}

%new
-(void)_configureAddWidgetViewIfNeededWithRect:(CGRect)frame withAvailableSpace:(HSWidgetAvailableSpace)availableSpace {
	if (self.addNewWidgetView == nil) {	
		self.addNewWidgetView = [[HSAddNewWidgetView alloc] initWithFrame:frame withAvailableSpace:availableSpace];
		[self.addNewWidgetView setAddNewWidgetDelegate:self];
	}
}

%new
-(CGSize)sizeForWidgetWithNumRows:(NSUInteger)numRows {
	CGSize iconSize = [self defaultIconSize];
	CGFloat listViewWidth = self.frame.size.width > 0 ? self.frame.size.width : [UIScreen mainScreen].bounds.size.width;
	CGFloat width = listViewWidth - 16;
	CGFloat height = iconSize.height * numRows + (numRows >= 2 ? [self verticalIconPadding] * (numRows - 2) : 0);
	return CGSizeMake(width, height);
}

%new
-(void)configureWidgetsIfNeededWithIndex:(NSInteger)index {
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	if (model.pageLayoutType == kNone && ![self isKindOfClass:%c(SBDockIconListView)] && model.widgetViewControllers == nil) {
		// confirm correct icon list view index
		if ([self isEqual:[[%c(SBIconController) sharedInstance] rootIconListAtIndex:index]]) {
			NSArray *currentPageWidgetLayout = allPagesWidgetLayouts[[NSString stringWithFormat:@"%zd", index]];
			if (currentPageWidgetLayout != nil && [currentPageWidgetLayout count] > 0) {
				model.pageLayoutType = kWidgetPage;
				model.widgetViewControllers = [NSMutableArray array];

				for (NSDictionary *currentWidgetPreferences in currentPageWidgetLayout) {
					NSInteger widgetOriginRow = [[currentWidgetPreferences valueForKey:@"WidgetOriginRow"] integerValue];
					Class widgetClass = NSClassFromString([currentWidgetPreferences valueForKey:@"WidgetClass"]);
					NSDictionary *widgetOptions = [currentWidgetPreferences valueForKey:@"WidgetOptions"];

					if (widgetClass == nil || ![widgetClass isSubclassOfClass:[HSWidgetViewController class]])
						continue; // make sure the class is subclass of HSWidgetViewController

					HSWidgetViewController *widgetViewController = [[widgetClass alloc] initForOriginRow:widgetOriginRow withOptions:widgetOptions];
					[widgetViewController _setDelegate:self];
					widgetViewController.requestedSize = [self sizeForWidgetWithNumRows:[widgetViewController numRows]];
					[model.widgetViewControllers addObject:widgetViewController];
					[self addSubview:widgetViewController.view];
				}
			}
		}

		// sort list as other methods depend on list being ordered by the originRow for slight peformance enhancements
		if (model.widgetViewControllers != nil) {
			[model.widgetViewControllers sortUsingComparator:^NSComparisonResult(HSWidgetViewController *first, HSWidgetViewController *second) {
				if (first.originRow < second.originRow)
					return NSOrderedAscending;
				else if (first.originRow > second.originRow)
					return NSOrderedDescending;
				else
					return NSOrderedSame;
			}];
		}
	}
}

%new
-(void)layoutWidget {
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	if (model.pageLayoutType != kNone && model.widgetViewControllers != nil) {
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			// add to current list view if it isn't already (this happens when list views are recreated)
			if (![widgetViewController.view isDescendantOfView:self]) {
				if (widgetViewController.view.superview != nil)
					[widgetViewController.view removeFromSuperview];
				[widgetViewController _setDelegate:self];
				[self addSubview:widgetViewController.view];
			}

			// skip dragging widget
			if ([widgetViewController isEqual:self.draggingWidgetViewController])
				continue;

			// calculate and set the frame for the widget
			NSUInteger currentPageType = model.pageLayoutType;
			NSUInteger numRows = [widgetViewController numRows];
			model.pageLayoutType = kNone;
			CGPoint origin = [self originForIconAtCoordinate:(SBIconCoordinate){1 + (NSInteger)widgetViewController.originRow, 1}];
			model.pageLayoutType = currentPageType;
			widgetViewController.requestedSize = [self sizeForWidgetWithNumRows:numRows];
			origin.x = (self.frame.size.width - widgetViewController.requestedSize.width) / 2;

			widgetViewController.view.frame = (CGRect){origin, widgetViewController.requestedSize};
		}
	}
}

%new
-(void)_closeTapped:(HSWidgetViewController *)widgetViewController {
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	if (model.widgetViewControllers != nil) {
		[model.widgetViewControllers removeObject:widgetViewController];

		// move other widgets up if they were placed below the widget being removed
		NSUInteger originRow = widgetViewController.originRow;
		NSUInteger numRowsToMove = [widgetViewController numRows];
		for (HSWidgetViewController *otherWidgetViewController in model.widgetViewControllers)
			if (otherWidgetViewController.originRow > originRow)
				otherWidgetViewController.originRow -= numRowsToMove;

		// changes made to widget layout so they need to be saved
		self.requiresSaveToFileForWidgetChanges = YES;

		model = [self model]; // update maxIconCount for current page

		BOOL isAddNewWidgetViewVisible = self.addNewWidgetView != nil;
		HSWidgetAvailableSpace availableSpace = [self maxAvailableSpace];
		if (!isAddNewWidgetViewVisible) {
			[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];

			self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
		} else {
			[self.addNewWidgetView setAvailableSpace:availableSpace];
		}
		[self _updateWidgetsWithAvailableRows:availableSpace];

		// widget removal animation
		CGPoint startingCenter = CGPointMake(widgetViewController.view.center.x, widgetViewController.view.frame.origin.y);
		widgetViewController.view.alpha = 1.0;
		[UIView animateWithDuration:kAnimationDuration animations:^{
			widgetViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
			widgetViewController.view.center = startingCenter;
			widgetViewController.view.alpha = 0.0;
			[self layoutIconsNow]; // animate icons and other widgets moving up
			if (isAddNewWidgetViewVisible) // animate add widget view
				[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];
			else
				self.addNewWidgetView.transform = CGAffineTransformMakeScale(1, 1);
		} completion:^(BOOL finished) {
			if (finished) {
				[widgetViewController.view removeFromSuperview];
				[widgetViewController release];

				if ([model.widgetViewControllers count] == 0) {
					model.pageLayoutType = kNone;
					model.widgetViewControllers = nil;
				}
			}
		}];
	}
}

%new
-(BOOL)_canDragWidget:(id)widget {
	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	if ([iconController respondsToSelector:@selector(isIconDragging)] && [iconController isIconDragging])
		return NO;
	else if ([iconController respondsToSelector:@selector(grabbedIcon)] && [iconController grabbedIcon] != nil)
		return NO;
	return self.draggingWidgetViewController == nil || [widget isEqual:self.draggingWidgetViewController];
}

%new
-(void)_setDraggingWidget:(id)widget {
	// update current dragging widget and can add more widgets
	self.draggingWidgetViewController = widget;
	self.isWidgetsAvailableForCurrentEmptySpace = [availableWidgetControllerClassesForAvailableRows([self maxAvailableSpace].numRows) count] > 0;

	BOOL isDraggingWidget = (widget != nil);
	((SBIconController *)[%c(SBIconController) sharedInstance]).isDraggingWidget = isDraggingWidget;
	if (!isDraggingWidget) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateWidgetDrag) object:nil];
		[self _updateWidgetDrag];
		[self layoutWidget];
	} else {
		[self bringSubviewToFront:self.draggingWidgetViewController.view];
		self.newRowForDraggingAnimation = self.draggingWidgetViewController.originRow;
	}
}

%new
-(void)_widgetDraggedToPoint:(CGPoint)point {
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	if (model.widgetViewControllers != nil && self.draggingWidgetViewController != nil) {
		// move widget with the finger
		CGRect frame = self.draggingWidgetViewController.view.frame;
		frame.origin.y = point.y;
		self.draggingWidgetViewController.view.frame = frame;

		// find its origin and move other widgets if needed
		NSUInteger currentPageType = model.pageLayoutType;
		model.pageLayoutType = kNone;
		NSUInteger result = [self rowAtPoint:point];
		model.pageLayoutType = currentPageType;

		NSUInteger maxRows = [%c(SBIconListView) maxVisibleIconRowsInterfaceOrientation:self.orientation];
		NSUInteger numRowsToMove = [self.draggingWidgetViewController numRows];
		NSUInteger previousRow = self.draggingWidgetViewController.originRow;

		if (result + numRowsToMove > maxRows)
			result = maxRows - numRowsToMove;

		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			if ([widgetViewController isEqual:self.draggingWidgetViewController])
				continue;

			// correct result row or other widget's row (bit messy)
			NSUInteger originRow =  widgetViewController.originRow;
			NSUInteger numRows = [widgetViewController numRows];
			if (originRow == result) {
				if (previousRow < originRow) {
					if (result >= numRowsToMove) {
						widgetViewController.originRow = result - numRowsToMove;
						break;
					} else {
						widgetViewController.originRow = 0;
						result = numRows;
						break;
					}
				} else if (previousRow > originRow) {
					if (result + numRowsToMove < maxRows) {
						widgetViewController.originRow = result + numRowsToMove;
						break;
					} else {
						widgetViewController.originRow = maxRows - numRows;
						result =  maxRows - numRows - numRowsToMove;
						break;
					}
				}
			} else if (originRow < result && originRow + numRows > result) {
				if (originRow + numRows >= maxRows) {
					widgetViewController.originRow = maxRows - numRows - numRowsToMove;
					break;
				} else {
					result = originRow + numRows;
					break;
				}
			} else if (originRow > result && originRow < result + numRowsToMove) {
				if (originRow >= numRowsToMove) {
					result = originRow - numRowsToMove;
					break;
				} else {
					result = 0;
					break;
				}
			}
		}

		// update available widget available
		if (previousRow != result) {
			self.draggingWidgetViewController.originRow = result;
			self.isWidgetsAvailableForCurrentEmptySpace = [availableWidgetControllerClassesForAvailableRows([self maxAvailableSpace].numRows) count] > 0;
			self.draggingWidgetViewController.originRow = previousRow;
		}
		
		// animate views with delay to get smoother animations
		if (self.newRowForDraggingAnimation != result) {
			self.newRowForDraggingAnimation = result;
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateWidgetDrag) object:nil];
			[self performSelector:@selector(_updateWidgetDrag) withObject:nil afterDelay:kDraggingWidgetHoldDuration];
		}
	}
}

%new
-(void)_updatePageForExpandOrShrinkOfWidget:(HSWidgetViewController *)widgetViewController fromRows:(NSUInteger)rows {
	// changes made to widget layout so they need to be saved
	self.requiresSaveToFileForWidgetChanges = YES;
	
	SBIconListModel *model = [self model]; // update maxIconCount for current page

	NSInteger numRowsToRemove = [widgetViewController numRows] - rows;
	if (numRowsToRemove > 0) { // move views if needed since we are expanding
		if ([widgetViewController availableStartRow] < widgetViewController.originRow) {
			widgetViewController.originRow -= numRowsToRemove;
			for (HSWidgetViewController *currentWidgetViewController in model.widgetViewControllers) {
				NSUInteger originRow = currentWidgetViewController.originRow;
				NSUInteger numRows = [currentWidgetViewController numRows];
				if ([widgetViewController isEqual:currentWidgetViewController])
					continue;
				if (originRow < widgetViewController.originRow && originRow + numRows > widgetViewController.originRow) {
					currentWidgetViewController.originRow -= numRowsToRemove;
					break;
				}
			}
		} else {
			for (HSWidgetViewController *currentWidgetViewController in model.widgetViewControllers)
				if (currentWidgetViewController.originRow > widgetViewController.originRow && [currentWidgetViewController availableStartRow] > currentWidgetViewController.originRow)
					currentWidgetViewController.originRow += numRowsToRemove;
		}
	} else { // move views if needed since we are shrinking
		for (HSWidgetViewController *currentWidgetViewController in model.widgetViewControllers)
			if (currentWidgetViewController.originRow > widgetViewController.originRow && ([currentWidgetViewController availableStartRow] > currentWidgetViewController.originRow || [currentWidgetViewController availableStartRow] == 0))
				currentWidgetViewController.originRow += numRowsToRemove; // numRowsToRemove will be negative so we are moving views up
	}

	HSWidgetAvailableSpace availableSpace = [self maxAvailableSpace];
	self.isWidgetsAvailableForCurrentEmptySpace = [availableWidgetControllerClassesForAvailableRows(availableSpace.numRows) count] > 0;
	BOOL isAddNewWidgetViewVisible = self.addNewWidgetView != nil;
	if (isAddNewWidgetViewVisible)
		[self.addNewWidgetView setAvailableSpace:availableSpace];
	CGSize finalSize = [self sizeForWidgetWithNumRows:[widgetViewController numRows]];
	[self _updateWidgetsWithAvailableRows:availableSpace];
	[UIView animateWithDuration:kAnimationDuration animations:^{
		widgetViewController.requestedSize = finalSize;
		[self layoutIconsNow];
		if (isAddNewWidgetViewVisible)
			[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];
	} completion:^(BOOL finished) {
		widgetViewController.requestedSize = finalSize;
		self.draggingWidgetViewController = nil;
		if (finished) {
			if (self.isWidgetsAvailableForCurrentEmptySpace && !isAddNewWidgetViewVisible) {
				[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];

				CGPoint startingCenter = self.addNewWidgetView.center;
				self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
				[UIView animateWithDuration:kAnimationDuration animations:^{
					self.addNewWidgetView.transform = CGAffineTransformMakeScale(1, 1);
					self.addNewWidgetView.center = startingCenter;
				} completion:nil];
			} else if (!self.isWidgetsAvailableForCurrentEmptySpace && isAddNewWidgetViewVisible) {
				CGPoint startingCenter = self.addNewWidgetView.center;
				[UIView animateWithDuration:kAnimationDuration animations:^{
					self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
					self.addNewWidgetView.center = startingCenter;
				} completion:^(BOOL removeFinished) {
					if (removeFinished) {
						[self.addNewWidgetView removeFromSuperview];
						[self.addNewWidgetView release];
						self.addNewWidgetView = nil;
					}
				}];
			}
		}
	}];
}

%new
-(void)_updateWidgetDrag {
	// update widget ordering if needed
	if (self.newRowForDraggingAnimation != self.draggingWidgetViewController.originRow) {
		self.draggingWidgetViewController.originRow = self.newRowForDraggingAnimation;
		self.requiresSaveToFileForWidgetChanges = YES;

		// sort the widgets based on origin row
		[MSHookIvar<SBIconListModel *>(self, "_model").widgetViewControllers sortUsingComparator:^NSComparisonResult(HSWidgetViewController *first, HSWidgetViewController *second) {
			if (first.originRow < second.originRow)
				return NSOrderedAscending;
			else if (first.originRow > second.originRow)
				return NSOrderedDescending;
			else
				return NSOrderedSame;
		}];
	}
	
	// animate add widget view and icon moving based new widget location
	BOOL isAddNewWidgetViewVisible = self.addNewWidgetView != nil;
	HSWidgetAvailableSpace availableSpace = [self maxAvailableSpace];
	if (isAddNewWidgetViewVisible)
		[self.addNewWidgetView setAvailableSpace:availableSpace];
	[self _updateWidgetsWithAvailableRows:availableSpace];
	[UIView animateWithDuration:kAnimationDuration animations:^{
		[self layoutIconsNow];
		if (isAddNewWidgetViewVisible)
			[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];
	} completion:^(BOOL finished) {
		if (finished) {
			if (self.isWidgetsAvailableForCurrentEmptySpace && !isAddNewWidgetViewVisible) {
				[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];
				[self bringSubviewToFront:self.draggingWidgetViewController.view];

				[self.addNewWidgetView.layer removeAllAnimations]; // fix double animations
				CGPoint startingCenter = self.addNewWidgetView.center;
				self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
				[UIView animateWithDuration:kAnimationDuration animations:^{
					self.addNewWidgetView.transform = CGAffineTransformMakeScale(1, 1);
					self.addNewWidgetView.center = startingCenter;
				} completion:nil];
			} else if (!self.isWidgetsAvailableForCurrentEmptySpace && isAddNewWidgetViewVisible) {
				CGPoint startingCenter = self.addNewWidgetView.center;
				[UIView animateWithDuration:kAnimationDuration animations:^{
					self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
					self.addNewWidgetView.center = startingCenter;
				} completion:^(BOOL removeFinished) {
					if (removeFinished) {
						[self.addNewWidgetView removeFromSuperview];
						[self.addNewWidgetView release];
						self.addNewWidgetView = nil;

					}
				}];
			}
		}
	}];
}

%new
-(void)_addNewWidgetTappedWithAvailableSpace:(HSWidgetAvailableSpace)availableSpace {
	// display a list of widgets to pick from
	HSAddWidgetRootViewController *hsWidgetPickerTableViewController = [[HSAddWidgetRootViewController alloc] initWithStyle:UITableViewStylePlain];
	self.hsWidgetPickerNavigationController = [[UINavigationController alloc] initWithRootViewController:hsWidgetPickerTableViewController];
	[hsWidgetPickerTableViewController _setAvailableSpace:availableSpace];
	hsWidgetPickerTableViewController.addWidgetSelectionDelegate = self;
	hsWidgetPickerTableViewController.availableWidgetClasses = availableWidgetControllerClassesForAvailableRows(availableSpace.numRows);
	
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	NSMutableDictionary *widgetsToExclude = [NSMutableDictionary dictionary];
	for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
		NSString *currentKey = NSStringFromClass([widgetViewController class]);
		NSMutableArray *widgetsForCurrentClass = [widgetsToExclude objectForKey:currentKey];
		if (widgetsForCurrentClass == nil)
			widgetsForCurrentClass = [NSMutableArray array];
		[widgetsForCurrentClass addObject:[widgetViewController options] ?:[NSDictionary dictionary]];
		[widgetsToExclude setObject:widgetsForCurrentClass forKey:currentKey];
	}
	hsWidgetPickerTableViewController.widgetsToExclude = widgetsToExclude;
	[hsWidgetPickerTableViewController updateAvailableWidgetsForExclusions];

	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	[iconController presentViewController:self.hsWidgetPickerNavigationController animated:YES completion:nil];

	[hsWidgetPickerTableViewController release];
}

%new
-(void)addWidgetOfClass:(Class)widgetClass forAvailableSpace:(HSWidgetAvailableSpace)availableSpace withOptions:(NSDictionary *)options {
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	if (model.widgetViewControllers == nil) {
		model.pageLayoutType = kWidgetPage;
		model.widgetViewControllers = [NSMutableArray array];
	}

	// create widget view controller and add it to view hierarchy
	HSWidgetViewController *widgetViewController = [[widgetClass alloc] initForOriginRow:availableSpace.startRow withOptions:options];
	[widgetViewController _setDelegate:self];
	[model.widgetViewControllers addObject:widgetViewController];

	// changes made to widget layout so they need to be saved
	self.requiresSaveToFileForWidgetChanges = YES;

	NSUInteger currentPageType = model.pageLayoutType;
	NSUInteger numRows = [widgetViewController numRows];
	model.pageLayoutType = kNone;
	CGPoint origin = [self originForIconAtCoordinate:(SBIconCoordinate){1 + (NSInteger)widgetViewController.originRow, 1}];
	model.pageLayoutType = currentPageType;
	widgetViewController.requestedSize = [self sizeForWidgetWithNumRows:numRows];
	origin.x = (self.frame.size.width - widgetViewController.requestedSize.width) / 2;
	
	model = [self model]; // update maxIconCount for current page

	// need to get new maxAvailableSpace since the new widget will take up space
	HSWidgetAvailableSpace maxAvailableSpace = [self maxAvailableSpace];
	self.isWidgetsAvailableForCurrentEmptySpace = [availableWidgetControllerClassesForAvailableRows(maxAvailableSpace.numRows) count] > 0;
	if (self.isWidgetsAvailableForCurrentEmptySpace)
		[self.addNewWidgetView setAvailableSpace:maxAvailableSpace];
	[self _updateWidgetsWithAvailableRows:maxAvailableSpace];

	void (^animateWidgetAddition)()  = ^{
		[self addSubview:widgetViewController.view];
		widgetViewController.view.frame = (CGRect){origin, widgetViewController.requestedSize};

		CGPoint addNewStartingCenter = CGPointMake(self.addNewWidgetView.center.x, self.addNewWidgetView.frame.origin.y);
		self.addNewWidgetView.transform = CGAffineTransformMakeScale(1, 1);

		// widget addition animation and add new widget view removal animation
		widgetViewController.view.alpha = 0.0;
		widgetViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
		shouldDisableWidgetLayout = YES; // disable widget layout so there are no animation issues
		[UIView animateWithDuration:kAnimationDuration animations:^{
			if (self.isWidgetsAvailableForCurrentEmptySpace) {
				[self _updateAddWidgetViewAndLayerForAvailableSpace:maxAvailableSpace];
			} else {
				self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
				self.addNewWidgetView.center = addNewStartingCenter;
				self.addNewWidgetView.alpha = 0.0;
			}

			[self layoutIconsNow]; // update icon position

			widgetViewController.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
			widgetViewController.view.alpha = 1.0;
		} completion:^(BOOL finished) {
			shouldDisableWidgetLayout = NO;
			if (!self.isWidgetsAvailableForCurrentEmptySpace) {
				[self.addNewWidgetView removeFromSuperview];
				[self.addNewWidgetView release];
				self.addNewWidgetView = nil;
			}
		}];
	};

	if (self.hsWidgetPickerNavigationController != nil) {
		[self.hsWidgetPickerNavigationController dismissViewControllerAnimated:YES completion:^{
			// remove widget picker
			[self.hsWidgetPickerNavigationController release];
			self.hsWidgetPickerNavigationController = nil;

			animateWidgetAddition();
		}];
	} else {
		animateWidgetAddition();
	}
}

%new
-(void)_cancelAddWidgetWithCompletion {
	if (self.hsWidgetPickerNavigationController != nil)
		[self.hsWidgetPickerNavigationController dismissViewControllerAnimated:YES completion:^{
			[self.hsWidgetPickerNavigationController release];
			self.hsWidgetPickerNavigationController = nil;
		}];
}

%new
-(NSMutableArray *)updatedAvailableClassesForController:(HSAddWidgetRootViewController *)controller {
	HSWidgetAvailableSpace maxAvailableSpace = [self maxAvailableSpace];
	[controller _setAvailableSpace:maxAvailableSpace];
	return availableWidgetControllerClassesForAvailableRows(maxAvailableSpace.numRows);
}

%new
-(HSWidgetAvailableSpace)maxAvailableSpace {
	HSWidgetAvailableSpace result = (HSWidgetAvailableSpace){0, 0};
	// TOOD: Fix add new widget layer size when icon is dragging by maybe exlcuded the dragged icon
	NSUInteger lastSlotIndex = ((NSMutableArray *)[self icons]).count;
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	NSUInteger maxIconCountForPage = MSHookIvar<NSUInteger>(model, "_maxIconCount");
	if (lastSlotIndex < maxIconCountForPage && lastSlotIndex > 0) {
		NSUInteger maxRows = [%c(SBIconListView) maxVisibleIconRowsInterfaceOrientation:self.orientation];
		NSUInteger colsPerRow = [[%c(SBIconController) sharedInstance] maxColCountForListInRootFolderWithInterfaceOrientation:self.orientation];
		NSUInteger iconsInRow = lastSlotIndex % colsPerRow;
		NSUInteger startIndex = iconsInRow == 0 ? lastSlotIndex : (lastSlotIndex + colsPerRow - iconsInRow);

		if (startIndex >= maxIconCountForPage)
			return result; // no space available so just return

		CGPoint modifiedOrigin = [self originForIconAtIndex:startIndex];
		modifiedOrigin.y += [self verticalIconPadding] / 2;

		NSUInteger currentPageType = model.pageLayoutType;
		model.pageLayoutType = kNone;
		NSUInteger startRow = [self rowAtPoint:modifiedOrigin];
		model.pageLayoutType = currentPageType;

		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			if (widgetViewController.originRow > startRow && result.numRows < widgetViewController.originRow - startRow) {
				result = (HSWidgetAvailableSpace){startRow, widgetViewController.originRow - startRow};
				startRow = widgetViewController.originRow + [widgetViewController numRows];
			} else if (widgetViewController.originRow >= startRow) {
				startRow = widgetViewController.originRow + [widgetViewController numRows];
			}
		}

		if (startRow < maxRows && result.numRows < maxRows - startRow)
			result = (HSWidgetAvailableSpace){startRow, maxRows - startRow};
	}
	return result;
}

%new
-(void)_animateUpdateOfIconDraggingWithCompletion:(void(^)(BOOL))completion {
	if ([self isEditing]) {
		NSUInteger lastSlotIndex = ((NSMutableArray *)[self icons]).count;
		NSUInteger colsPerRow = [[%c(SBIconController) sharedInstance] maxColCountForListInRootFolderWithInterfaceOrientation:self.orientation];
		NSUInteger iconsInRow = lastSlotIndex % colsPerRow;
		NSUInteger startIndex = iconsInRow == 0 ? lastSlotIndex : (lastSlotIndex + colsPerRow - iconsInRow);
		SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
		NSUInteger maxIconCountForPage = MSHookIvar<NSUInteger>(model, "_maxIconCount");
		if (startIndex <= maxIconCountForPage) {
			HSWidgetAvailableSpace availableSpace = [self maxAvailableSpace];
			self.isWidgetsAvailableForCurrentEmptySpace = [availableWidgetControllerClassesForAvailableRows(availableSpace.numRows) count] > 0;
			[self _updateWidgetsWithAvailableRows:availableSpace];
			if (self.isWidgetsAvailableForCurrentEmptySpace) {
				if (self.addNewWidgetView != nil) {
					[UIView animateWithDuration:kAnimationDuration animations:^{
						[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];
					} completion:completion];
				} else {
					[self _updateAddWidgetViewAndLayerForAvailableSpace:availableSpace];

					CGPoint startingCenter = self.addNewWidgetView.center;
					self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
					[UIView animateWithDuration:kAnimationDuration animations:^{
						self.addNewWidgetView.transform = CGAffineTransformMakeScale(1, 1);
						self.addNewWidgetView.center = startingCenter;
					} completion:completion];
				}
				return;
			} else {
				if (self.addNewWidgetView != nil) {
					CGPoint startingCenter = self.addNewWidgetView.center;
					[UIView animateWithDuration:kAnimationDuration animations:^{
						self.addNewWidgetView.transform = CGAffineTransformMakeScale(0.01, 0.01);
						self.addNewWidgetView.center = startingCenter;
					} completion:^(BOOL removeFinished) {
						if (removeFinished) {
							[self.addNewWidgetView removeFromSuperview];
							[self.addNewWidgetView release];
							self.addNewWidgetView = nil;
						}

						if (completion != nil)
							completion(removeFinished);
					}];
					return;
				}
			}
		}
	}

	[self _animateRemoveOfIconExcludingCurrentIcon:NO withCompletion:completion];
}

%new
-(void)_animateRemoveOfIconExcludingCurrentIcon:(BOOL)excluded withCompletion:(void(^)(BOOL))completion {
	NSInteger iconsRequired = excluded ? 1 : 0;
	if ([self isEditing]) {
		if (((NSMutableArray *)[self icons]).count == iconsRequired) {
			SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
			if (model != nil) {
				[CATransaction begin];
				[CATransaction setCompletionBlock:^{
					if (completion != nil)
						completion(YES);
				}];

				NSArray *currentWidgetViewControllers = [NSArray arrayWithArray:model.widgetViewControllers];
				for (HSWidgetViewController *widgetViewController in currentWidgetViewControllers)
					[self _closeTapped:widgetViewController];

				[CATransaction commit];
			}
		} else {
			[self _updateWidgetsWithAvailableRows:[self maxAvailableSpace]];
		}
	} else if (completion != nil) {
		completion(NO);
	}
}

%new
-(void)_updateWidgetsWithAvailableRows:(HSWidgetAvailableSpace)space {
	SBIconListModel *model = MSHookIvar<SBIconListModel *>(self, "_model");
	for (HSWidgetViewController *widgetViewController in model.widgetViewControllers)
		[widgetViewController _updateAvailableSpace:space];
}
%end

// disable homescreen rotation
%hook SpringBoard
-(BOOL)homeScreenSupportsRotation { // iOS 8 - 11
	return NO;
}

-(NSInteger)homeScreenRotationStyle { // iOS 8 - 11
	return 0;
}
%end

%hook SBIconController
%property (nonatomic, assign) BOOL isDraggingWidget;

-(BOOL)_iconCanBeGrabbed:(id)arg1 {
	if (self.isDraggingWidget)
		return NO; // disable icon grabbing when widget is being dragged
	return %orig;
}

-(void)uninstallIcon:(id)arg1 {
	if ([[self currentRootIconList] isKindOfClass:%c(SBRootIconListView)])
		[(SBRootIconListView *)[self currentRootIconList] _animateRemoveOfIconExcludingCurrentIcon:YES withCompletion:nil];

	%orig;
}
%end

@interface SBFolderView // iOS 7 - 11
-(id)currentIconListView; // iOS 7 - 11
@end

%hook SBFolderView
-(void)noteUserIsInteractingWithIcons {
	%orig;

	if ([[self currentIconListView] isKindOfClass:%c(SBRootIconListView)])
		[(SBRootIconListView *)[self currentIconListView] _animateUpdateOfIconDraggingWithCompletion:nil];
}
%end

%hook SBFolderController
%property (nonatomic, assign) BOOL animatingIconListViewDragLocationChange;

-(id)initWithFolder:(id)arg1 orientation:(UIInterfaceOrientation)arg2 viewMap:(id)arg3 {
	self = %orig;
	if (self != nil)
		self.animatingIconListViewDragLocationChange = NO;
	return self;
}

-(id)initWithFolder:(id)arg1 orientation:(UIInterfaceOrientation)arg2 viewMap:(id)arg3 context:(id)arg4 {
	self = %orig;
	if (self != nil)
		self.animatingIconListViewDragLocationChange = NO;
	return self;
}

-(void)noteGrabbedIconDidChange:(id)arg1 {
	%orig;

	if (arg1 == nil) {
		for (SBIconListView *iconListView in self.iconListViews)
			if ([iconListView isKindOfClass:%c(SBRootIconListView)])
				[(SBRootIconListView *)iconListView _animateUpdateOfIconDraggingWithCompletion:nil];
	}
}

-(void)noteGrabbedIcon:(id)arg1 locationDidChangeWithTouch:(id)arg2 {
	%orig;

	if ([[self currentIconListView] isKindOfClass:%c(SBRootIconListView)] && !self.animatingIconListViewDragLocationChange) {
		self.animatingIconListViewDragLocationChange = YES;
		[(SBRootIconListView *)[self currentIconListView] _animateUpdateOfIconDraggingWithCompletion:^(BOOL finished) {
			self.animatingIconListViewDragLocationChange = NO;
		}];
	}
}

-(void)noteIconDrag:(id)arg1 didChangeInIconListView:(id)arg2 {
	%orig;

	if ([arg2 isKindOfClass:%c(SBRootIconListView)] && !self.animatingIconListViewDragLocationChange) {
		self.animatingIconListViewDragLocationChange = YES;
		[(SBRootIconListView *)arg2 _animateUpdateOfIconDraggingWithCompletion:^(BOOL finished) {
			self.animatingIconListViewDragLocationChange = NO;
		}];
	}
}

-(void)noteIconDrag:(id)arg1 didEnterIconListView:(id)arg2 {
	%orig;

	if ([arg2 isKindOfClass:%c(SBRootIconListView)] && !self.animatingIconListViewDragLocationChange) {
		self.animatingIconListViewDragLocationChange = YES;
		self.animatingIconListViewDragLocationChange = YES;
		[(SBRootIconListView *)arg2 _animateUpdateOfIconDraggingWithCompletion:^(BOOL finished) {
			self.animatingIconListViewDragLocationChange = NO;
		}];
	}
}

-(void)noteIconDrag:(id)arg1 didExitIconListView:(id)arg2 {
	%orig;

	if ([arg2 isKindOfClass:%c(SBRootIconListView)] && !self.animatingIconListViewDragLocationChange) {
		self.animatingIconListViewDragLocationChange = YES;
		[(SBRootIconListView *)arg2 _animateUpdateOfIconDraggingWithCompletion:^(BOOL finished) {
			self.animatingIconListViewDragLocationChange = NO;
		}];
	}
}

-(void)noteIconDragDidEnd:(id)arg1 {
	%orig;

	if ([[self currentIconListView] isKindOfClass:%c(SBRootIconListView)] && !self.animatingIconListViewDragLocationChange) {
		self.animatingIconListViewDragLocationChange = YES;
		[(SBRootIconListView *)[self currentIconListView] _animateUpdateOfIconDraggingWithCompletion:^(BOOL finished) {
			self.animatingIconListViewDragLocationChange = NO;
		}];
		
		for (SBIconListView *iconListView in self.iconListViews)
			if ([iconListView isKindOfClass:%c(SBRootIconListView)] && iconListView != [self currentIconListView])
				[(SBRootIconListView *)iconListView _animateUpdateOfIconDraggingWithCompletion:nil];
	}
}
%end

@interface SBAnimationSettings // iOS 9 - 12
-(id)BSAnimationSettings; // iOS 9 - 12
@property (assign,nonatomic) CGFloat mass; // iOS 9 - 12
@property (assign,nonatomic) NSTimeInterval delay; // iOS 9 - 12
@end

@interface SBCenterZoomSettings // iOS 7 - 12
@property (assign) CGFloat centerRowCoordinate; // iOS 7 - 12
-(SBAnimationSettings *)centralAnimationSettings; // inherited
-(NSInteger)distanceEffect; // iOS 7 - 12
-(CGFloat)firstHopIncrement; // iOS 7 - 12
-(double)hopIncrementAcceleration; // iOS 7 - 12
@end

@interface SBCenterIconZoomAnimator // iOS 7 - 12
@property (nonatomic,retain) SBCenterZoomSettings *settings; // iOS 7 - 12
@property (nonatomic,readonly) SBIconListView *iconListView; // inherited
@property (nonatomic,readonly) UIView * zoomView; // iOS 7 - 12
-(CGFloat)_iconZoomDelay; // iOS 7 - 12
-(CGPoint)cameraPosition; // iOS 7 - 12
-(id)_animationFactoryForWidget:(id)widgetViewController;
@end

@interface BSAnimationSettings // iOS 8 - 12
-(void)applyToCAAnimation:(id)arg1; // iOS 9 - 12
-(void)_setDelay:(NSTimeInterval)arg1; // iOS 8 - 12
-(NSTimeInterval)delay; // iOS 8 - 12
-(void)_setSpeed:(float)arg1; // iOS 8 - 12
-(CGFloat)speed; // iOS 8 - 12
@end

@interface BSUIAnimationFactory // iOS 9 - 12
@property (nonatomic,copy,readonly) BSAnimationSettings *settings; // iOS 9 - 12
+(id)factoryWithSettings:(id)arg1; // iOS 9 - 12
+(CGFloat)globalSlowDownFactor; // iOS 9 - 12
// +(void)animateWithFactory:(id)arg1 additionalDelay:(NSTimeInterval)arg2 options:(NSUInteger)arg3 actions:(id)arg4 completion:(id)arg5; // iOS 9 - 12
@end

%hook SBCenterIconZoomAnimator
-(void)_prepareAnimation {
	%orig;

	if ([self.iconListView isKindOfClass:%c(SBRootIconListView)]) {
		SBRootIconListView *rootIconListView = (SBRootIconListView *)self.iconListView;
		[rootIconListView configureWidgetsIfNeededWithIndex:[[%c(SBIconController) sharedInstance] currentIconListIndex]]; // not really required
		for (HSWidgetViewController *widgetViewController in MSHookIvar<SBIconListModel *>(rootIconListView, "_model").widgetViewControllers)
			[self.zoomView addSubview:[widgetViewController zoomAnimatingView]];
	}
}

-(void)_cleanupAnimation {
	%orig;

	if ([self.iconListView isKindOfClass:%c(SBRootIconListView)]) {
		SBRootIconListView *rootIconListView = (SBRootIconListView *)self.iconListView;
		for (HSWidgetViewController *widgetViewController in MSHookIvar<SBIconListModel *>(rootIconListView, "_model").widgetViewControllers) {
			[[widgetViewController zoomAnimatingView].layer removeAnimationForKey:@"HSWidgetZPosition"];
			[widgetViewController clearZoomAnimatingView];
			if ([widgetViewController shouldUseCustomViewForAnimation])
				widgetViewController.view.alpha = 1.0;
			else
				[rootIconListView addSubview:[widgetViewController zoomAnimatingView]]; // move the view back to root icon list view
		}
	}
}

-(void)_calculateCentersAndCameraPosition {
	CGFloat previousCenterRowCoordinate = self.settings.centerRowCoordinate;
	if ([self.iconListView isKindOfClass:%c(SBRootIconListView)]) {
		CGFloat offset = self.settings.centerRowCoordinate - floorf(self.settings.centerRowCoordinate);
		SBRootIconListView *rootIconListView = (SBRootIconListView *)self.iconListView;

		for (HSWidgetViewController *widgetViewController in MSHookIvar<SBIconListModel *>(rootIconListView, "_model").widgetViewControllers) {
			NSUInteger numRows = [widgetViewController numRows];
			if (widgetViewController.originRow + numRows < previousCenterRowCoordinate + offset)
				self.settings.centerRowCoordinate -= numRows;
			else if (widgetViewController.originRow + numRows == previousCenterRowCoordinate + offset)
				self.settings.centerRowCoordinate -= previousCenterRowCoordinate - widgetViewController.originRow - offset;
			else if (widgetViewController.originRow < previousCenterRowCoordinate)
				self.settings.centerRowCoordinate -= previousCenterRowCoordinate - widgetViewController.originRow;
			else
				break;
		}

		if (self.settings.centerRowCoordinate <= offset)
			self.settings.centerRowCoordinate += offset;
	}

	%orig;
	
	self.settings.centerRowCoordinate = previousCenterRowCoordinate;
}

-(void)_performAnimationToFraction:(CGFloat)arg1 withCentralAnimationSettings:(id)arg2 delay:(NSTimeInterval)arg3 alreadyAnimating:(BOOL)arg4 sharedCompletion:(void (^)(BOOL finished))arg5 {
	// TODO: Fix the bug where the widget animation is quicker/less delayed than the icon animaiton (seems to be an iOS issue)
	if ([self.iconListView isKindOfClass:%c(SBRootIconListView)]) {
		NSTimeInterval additionalDelay = arg3 + [self _iconZoomDelay];
		SBRootIconListView *rootIconListView = (SBRootIconListView *)self.iconListView;
		CGFloat iconZoomedZ = MSHookIvar<CGFloat>(self, "_iconZoomedZ");
		for (HSWidgetViewController *widgetViewController in MSHookIvar<SBIconListModel *>(rootIconListView, "_model").widgetViewControllers) {
			/* // doesn't animate since zPosition isn't animated by default but this is the approach used by apple
			[%c(BSUIAnimationFactory) animateWithFactory:[self _animationFactoryForWidget:widgetViewController] additionalDelay:additionalDelay options:2 actions:^{
				[widgetViewController zoomAnimatingView].layer.zPosition = arg1 * MSHookIvar<CGFloat>(self, "_iconZoomedZ");
			} completion:arg5];*/
			BSUIAnimationFactory *animationFactory = [self _animationFactoryForWidget:widgetViewController];
			BSAnimationSettings *animationSettings = animationFactory.settings;
			[animationSettings _setSpeed:1.0 / [%c(BSUIAnimationFactory) globalSlowDownFactor]];
			[animationSettings _setDelay:[animationSettings delay] + additionalDelay];

			[CATransaction begin];
			[CATransaction setCompletionBlock:^{
				if ([widgetViewController shouldUseCustomViewForAnimation]) {
					if (arg1 == 0)
						widgetViewController.view.alpha = 1.0;
					[widgetViewController zoomAnimatingView].alpha = 0.0;
				}

				if (arg5 != nil)
					arg5(YES);
			}];

			CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"zPosition"];
			[animationSettings applyToCAAnimation:animation];
			animation.fromValue = @((1 - arg1) * iconZoomedZ);
			animation.toValue = @(arg1 * iconZoomedZ);
			animation.fillMode = kCAFillModeForwards;
			animation.removedOnCompletion = NO;
			animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];

			[[widgetViewController zoomAnimatingView].layer addAnimation:animation forKey:@"HSWidgetZPosition"];

			[CATransaction commit];
		}
	}

	%orig;
}

-(NSUInteger)_numberOfSignificantAnimations {
	NSUInteger result = %orig;
	if ([self.iconListView isKindOfClass:%c(SBRootIconListView)])
		result += [MSHookIvar<SBIconListModel *>(self.iconListView, "_model").widgetViewControllers count];
	return result;
}

-(void)_setAnimationFraction:(CGFloat)arg1 {
	if ([self.iconListView isKindOfClass:%c(SBRootIconListView)]) {
		SBRootIconListView *rootIconListView = (SBRootIconListView *)self.iconListView;
		for (HSWidgetViewController *widgetViewController in MSHookIvar<SBIconListModel *>(rootIconListView, "_model").widgetViewControllers) {
			// [widgetViewController zoomAnimatingView].layer.zPosition = arg1 * MSHookIvar<CGFloat>(self, "_iconZoomedZ");
			if ([widgetViewController shouldUseCustomViewForAnimation]) {
				widgetViewController.view.alpha = 0.0;
				[widgetViewController zoomAnimatingView].alpha = 1.0;
			}
			[[widgetViewController zoomAnimatingView].layer removeAnimationForKey:@"HSWidgetZPosition"];
		}
	}

	%orig;
}

%new
-(id)_animationFactoryForWidget:(HSWidgetViewController *)widgetViewController {
	SBAnimationSettings *animationSettings = [self.settings centralAnimationSettings];
	CGFloat distanceEffect = [self.settings distanceEffect];
	if (distanceEffect > 0 && [self.iconListView isKindOfClass:%c(SBRootIconListView)] && widgetViewController != nil) {
		CGFloat widgetCenterRow = (widgetViewController.originRow + [widgetViewController numRows]) / 2;
		NSInteger totalIncrements = floorf(fabs(widgetCenterRow - MSHookIvar<CGFloat>(self, "_centerRow")));
		CGFloat currentIncrement = [self.settings firstHopIncrement];
		CGFloat currentMass = animationSettings.mass;
		if (currentIncrement <= 0.0 || totalIncrements == 0) {
			NSInteger i = 1;
			do {
				currentMass += currentIncrement * distanceEffect;
				currentIncrement += [self.settings hopIncrementAcceleration];
			} while (currentIncrement <= 0.0 || i < totalIncrements);
		}
		CGFloat newMass = MAX(distanceEffect, 0.1);
		if (newMass != animationSettings.mass)
			animationSettings.mass = newMass;
	}
	return [%c(BSUIAnimationFactory) factoryWithSettings:[animationSettings BSAnimationSettings]];
}
%end

static void loadHSWidgets() {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *prefix = @"/Library/HSWidgets";
	NSError *error = nil;
	NSArray *widgetsDirectories = [fileManager contentsOfDirectoryAtPath:prefix error:&error];
	if (error != nil)
		return;

	availableHSWidgetClasses = [NSMutableArray array];
	availableHSWidgetHandlers.clear();
	for (NSString *widgetDirectoryName in widgetsDirectories) {
		NSString *widgetDirectoryPath = [prefix stringByAppendingPathComponent:widgetDirectoryName];
		NSString *infoPath = [NSString stringWithFormat:@"%@/%@.plist", widgetDirectoryPath, widgetDirectoryName];
		NSString *dylibPath = [NSString stringWithFormat:@"%@/%@.dylib", widgetDirectoryPath, widgetDirectoryName];
		NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
		void *handler = dlopen([dylibPath UTF8String], RTLD_LAZY);
		if (info != nil && handler != NULL) {
			[availableHSWidgetClasses addObject:NSClassFromString(info[@"HSPrincipalClass"])];
			availableHSWidgetHandlers.push_back(handler);
		}
	}
}

static void unloadHSWidgets() {
	for (void *handler : availableHSWidgetHandlers)
		dlclose(handler);
	availableHSWidgetHandlers.clear();
}

%ctor {
	loadHSWidgets();
	allPagesWidgetLayouts = [NSMutableDictionary dictionaryWithContentsOfFile:kWidgetLayoutPreferencesPath];
	if (allPagesWidgetLayouts == nil)
		allPagesWidgetLayouts = [NSMutableDictionary dictionary];
}

%dtor {
	unloadHSWidgets();
	availableHSWidgetClasses = nil;
	allPagesWidgetLayouts = nil;
}