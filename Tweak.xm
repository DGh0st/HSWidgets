#import <UIKit/UIKit.h>
#import "HSWidgets-core.h"
#import "HSWidgetPageController.h"
#import "HSWidgetViewController.h"
#import "SBIconController.h"
#import "SBIconCoordinate.h"
#import "SBIconListModel.h"
#import "SBIconListView.h"
#import "SBRootFolderController.h"
#import "SBRootFolderView.h"

const HSWidgetPosition HSWidgetPositionZero = HSWidgetPositionMake(0, 0);
const HSWidgetSize HSWidgetSizeZero = HSWidgetSizeMake(0, 0);
const HSWidgetFrame HSWidgetFrameZero = HSWidgetFrameMake(HSWidgetPositionZero, HSWidgetSizeZero);

#define WIDGET_LAYOUT_PREFERENCES_PATH @"/var/mobile/Library/Preferences/com.dgh0st.hswidget.widgetlayouts.plist"

static inline void ConfigureWidgetsIfNeeded(NSArray *iconListViews) {
	for (NSInteger listViewIndex = 0; listViewIndex < iconListViews.count; ++listViewIndex) {
		SBIconListView *iconListView = iconListViews[listViewIndex];
		HSWidgetPageController *widgetPageController = iconListView.widgetPageController;
		[widgetPageController configureWidgetsIfNeededWithIndex:listViewIndex];
		[iconListView layoutIconsNow];
	}

	// send all widgets configured notification
	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetAllWidgetsConfiguredNotification object:nil userInfo:nil];
}

static inline SBIconCoordinate GetCoordinateAtPoint(SBIconListView *iconListView, CGPoint point, SBIconCoordinate preferredCoordinate) {
	// undo our changes to calculate the correct row and column for editing mode
	SBIconListModel *model = [iconListView valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		// preferredRow is expected to be 0-indexed
		preferredCoordinate = [iconListView.widgetPageController coordinateForPoint:point withRow:preferredCoordinate.row column:preferredCoordinate.col];
		--preferredCoordinate.row;
		--preferredCoordinate.col;
	}
	return preferredCoordinate;
}

static inline SBIconCoordinate GetNewIconCoordinate(SBIconListView *iconListView, SBIconCoordinate preferredCoordinate) {
	SBIconListModel *model = [iconListView valueForKey:@"_model"];
	NSUInteger maxIconSpaces = [iconListView iconRowsForCurrentOrientation] * [iconListView iconColumnsForCurrentOrientation];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		NSInteger iconIndex = [iconListView indexForCoordinate:preferredCoordinate forOrientation:iconListView.orientation];
		for (HSWidgetPositionObject *position in [iconListView.widgetPageController occupiedWidgetSpaces]) {
			if ([iconListView indexForCoordinate:SBIconCoordinateMake(position.position) forOrientation:iconListView.orientation] <= iconIndex)
				++iconIndex;
		}

		if (iconIndex < 0) {
			iconIndex = 0;
		} else if (iconIndex >= maxIconSpaces) {
			iconIndex = maxIconSpaces - 1;
		}

		preferredCoordinate = [iconListView iconCoordinateForIndex:iconIndex forOrientation:iconListView.orientation];
	}
	return preferredCoordinate;
}

static inline NSMutableDictionary *GetWidgetLayouts() {
	if ([[NSFileManager defaultManager] fileExistsAtPath:WIDGET_LAYOUT_PREFERENCES_PATH]) {
		return [[NSMutableDictionary alloc] initWithContentsOfFile:WIDGET_LAYOUT_PREFERENCES_PATH];
	}
	return [NSMutableDictionary new];
}

%hook SBRootFolderController
%property (nonatomic, retain) NSMutableDictionary *allPagesWidgetLayouts;

-(void)viewDidLoad {
	%orig;

	if (self.iconListViews != nil) {
		// load saved widget layouts from file
		self.allPagesWidgetLayouts = GetWidgetLayouts();

		ConfigureWidgetsIfNeeded(self.iconListViews);
	}
}

-(void)setEditing:(BOOL)arg1 animated:(BOOL)arg2 {
	BOOL stateDidChange = arg1 != [self isEditing];

	%orig;

	if (stateDidChange && !arg1 && self.iconListViews != nil) {
		BOOL wereAnyChangesMade = NO;
		for (NSInteger listViewIndex = 0; listViewIndex < self.iconListViewCount; ++listViewIndex) {
			SBIconListView *iconListView = self.iconListViews[listViewIndex];
			NSString *pageKey = [@(listViewIndex) stringValue];
			SBIconListModel *model = [iconListView model];
			NSUInteger widgetsCount = model.widgetViewControllers.count;
			if (iconListView.widgetPageController.requiresSaveToFileForWidgetChanges || [self.allPagesWidgetLayouts[pageKey] count] != widgetsCount) {
				iconListView.widgetPageController.requiresSaveToFileForWidgetChanges = NO;
				wereAnyChangesMade = YES;

				// save changes to dictionary
				if (widgetsCount > 0) {
					NSMutableArray *currentPageWidgetLayout = [NSMutableArray array];
					for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
						[currentPageWidgetLayout addObject:@{
							@"WidgetOriginRow" : @(widgetViewController.widgetFrame.origin.row),
							@"WidgetOriginCol" : @(widgetViewController.widgetFrame.origin.col),
							@"WidgetNumRows" : @(widgetViewController.widgetFrame.size.numRows),
							@"WidgetNumCols" : @(widgetViewController.widgetFrame.size.numCols),
							@"WidgetClass" : NSStringFromClass([widgetViewController class]),
							@"WidgetOptions" : [widgetViewController options] ?: [NSDictionary dictionary]
						}];
					}
					self.allPagesWidgetLayouts[pageKey] = currentPageWidgetLayout;
				} else {
					self.allPagesWidgetLayouts[pageKey] = [NSDictionary dictionary];
				}
			}
		}

		// remove layouts of pages that don't exist
		NSMutableArray *keysToBeRemove = [NSMutableArray arrayWithCapacity:self.allPagesWidgetLayouts.count];
		for (NSString *pageKey in self.allPagesWidgetLayouts) {
			if (pageKey != nil && [pageKey intValue] >= self.iconListViewCount) {
				wereAnyChangesMade = YES;
				[keysToBeRemove addObject:pageKey];
			}
		}
		[self.allPagesWidgetLayouts removeObjectsForKeys:keysToBeRemove];

		if (wereAnyChangesMade) {
			[self.allPagesWidgetLayouts writeToFile:WIDGET_LAYOUT_PREFERENCES_PATH atomically:YES];
		}
	}
}

-(void)rootFolderView:(id)arg1 didChangeSidebarVisibilityProgress:(CGFloat)arg2 {
	%orig(arg1, arg2);

	for (SBIconListView *iconListView in self.iconListViews) {
		iconListView.widgetPageController.addNewWidgetView.frame = iconListView.bounds;
	}
}

-(void)dealloc {
	[self.allPagesWidgetLayouts release];
	self.allPagesWidgetLayouts = nil;

	%orig();
}
%end

%hook SBRootFolderView
-(void)_cleanupAfterSidebarSlideGestureCompleted:(id)arg1 {
	%orig(arg1);

	SBIconController *iconController = [%c(SBIconController) sharedInstance];
	SBRootFolderController *rootFolderController = [iconController _rootFolderController];
	for (SBIconListView *iconListView in rootFolderController.iconListViews) {
		iconListView.widgetPageController.addNewWidgetView.frame = iconListView.bounds;
	}
}
%end

%hook SBIconListView
%property (nonatomic, retain) HSWidgetPageController *widgetPageController;

-(instancetype)initWithModel:(id)arg1 orientation:(UIInterfaceOrientation)arg2 viewMap:(id)arg3 { // iOS 7 - 12
	self = %orig(arg1, arg2, arg3);
	if (self != nil) { // iOS 10 - 12
		if ([self isKindOfClass:%c(SBRootIconListView)] && ![self isKindOfClass:%c(SBDockIconListView)]) {
			self.widgetPageController = [[HSWidgetPageController alloc] initWithIconListView:self];
		} else {
			self.widgetPageController = nil;
		}
	}
	return self;
}

-(instancetype)initWithModel:(id)arg1 layoutProvider:(id)arg2 iconLocation:(id)arg3 orientation:(UIInterfaceOrientation)arg4 iconViewProvider:(id)arg5 { // iOS 13
	self = %orig(arg1, arg2, arg3, arg4, arg5);
	if (self != nil) { // iOS 13
		if ([[arg1 folder] isKindOfClass:%c(SBRootFolderWithDock)] && ![self isKindOfClass:%c(SBDockIconListView)]) {
			self.widgetPageController = [[HSWidgetPageController alloc] initWithIconListView:self];
		} else {
			self.widgetPageController = nil;
		}
	}
	return self;
}

-(void)setVisibleColumnRange:(NSRange)arg1 { // iOS 13
	if (arg1.length == 0 || ((SBIconListModel *)[self valueForKey:@"_model"]).widgetViewControllers == nil) {
		%orig(arg1);
	} else {
		%orig(NSMakeRange(0, [self iconColumnsForCurrentOrientation]));
	}
}

-(void)layoutIconsIfNeeded:(CGFloat)arg1 animationType:(NSInteger)arg2 options:(NSUInteger)arg3 { // iOS 13
	SBIconListModel *model = [self valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		[self.widgetPageController layoutWidgetPage];
	}

	%orig(arg1, arg2, arg3);
}

-(void)layoutIconsIfNeeded:(CGFloat)arg1 animationType:(NSInteger)arg2 { // iOS 11 - 12
	SBIconListModel *model = [self valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		[self.widgetPageController layoutWidgetPage];
	}

	%orig(arg1, arg2);
}

-(void)layoutIconsIfNeeded:(CGFloat)arg1 domino:(BOOL)arg2 { // iOS 10
	SBIconListModel *model = [self valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		[self.widgetPageController layoutWidgetPage];
	}

	%orig(arg1, arg2);
}

-(NSUInteger)columnAtPoint:(CGPoint)arg1 {
	if ([self respondsToSelector:@selector(columnAtPoint:fractionOfDistanceThroughColumn:)]) {
		return %orig(arg1);
	}
	return GetCoordinateAtPoint(self, arg1, SBIconCoordinateMake(SBIconCoordinateInvalid, %orig(arg1))).col;
}

-(NSUInteger)columnAtPoint:(CGPoint)arg1 metrics:(const void *)arg2 fractionOfDistanceThroughColumn:(CGFloat *)arg3 {
	if (arg1.x == 0.0 || arg1.y == 0.0) {
		return %orig(arg1, arg2, arg3);
	}
	return GetCoordinateAtPoint(self, arg1, SBIconCoordinateMake(SBIconCoordinateInvalid, %orig(arg1, arg2, arg3))).col;
}

-(NSUInteger)rowAtPoint:(CGPoint)arg1 {
	if ([self respondsToSelector:@selector(columnAtPoint:fractionOfDistanceThroughColumn:)]) {
		return %orig(arg1);
	}
	return GetCoordinateAtPoint(self, arg1, SBIconCoordinateMake(%orig(arg1), SBIconCoordinateInvalid)).row;
}

-(NSUInteger)rowAtPoint:(CGPoint)arg1 metrics:(const void *)arg2 {
	if (arg1.x == 0.0 || arg1.y == 0.0) {
		return %orig(arg1, arg2);
	}
	return GetCoordinateAtPoint(self, arg1, SBIconCoordinateMake(%orig(arg1, arg2), SBIconCoordinateInvalid)).row;
}

-(SBIconCoordinate)coordinateAtPoint:(CGPoint)arg1 {
	NSUInteger maxRows = [self iconRowsForCurrentOrientation];
	NSUInteger maxCols = [self iconColumnsForCurrentOrientation];
	SBIconCoordinate originalCoordinate = %orig(arg1);
	SBIconCoordinate coordinate = GetCoordinateAtPoint(self, arg1, originalCoordinate);
	return HSWidgetPositionIsValid(HSWidgetPositionMake(coordinate), maxRows, maxCols) ? coordinate : originalCoordinate;
}

-(CGPoint)originForIconAtCoordinate:(SBIconCoordinate)arg1 { // iOS 10 - 12
	return %orig(GetNewIconCoordinate(self, arg1));
}

-(CGPoint)originForIconAtCoordinate:(SBIconCoordinate)arg1 metrics:(const void *)arg2 { // iOS 13
	return %orig(GetNewIconCoordinate(self, arg1), arg2);
}

-(id)model {
	// reduce limit of icons for this page as widgets takes up icon spaces
	SBIconListModel *result = %orig;
	if (result.pageLayoutType != PageTypeNone && result.widgetViewControllers != nil) {
		NSUInteger numIconsToRemove = 0;
		for (HSWidgetViewController *widgetViewController in result.widgetViewControllers)
			numIconsToRemove += widgetViewController._gridPositions.count;
		NSUInteger maxRows = [self iconRowsForCurrentOrientation];
		NSUInteger maxCols = [self iconColumnsForCurrentOrientation];
		MSHookIvar<NSUInteger>(result, "_maxIconCount") = (maxRows * maxCols) - numIconsToRemove; // original - num icon spaces taken up by widgets
	}
	return result;
}

-(void)setEditing:(BOOL)arg1 {
	BOOL stateDidChange = arg1 != [self isEditing];

	%orig(arg1);

	if (stateDidChange) {
		[self.widgetPageController setEditing:arg1];
	}
}

-(void)dealloc {
	[self.widgetPageController release];
	self.widgetPageController = nil;

	%orig();
}
%end

%hook SBIconController
-(void)setIsEditing:(BOOL)arg1 withFeedbackBehavior:(id)arg2 { // iOS 10 - 12
	%orig(arg1, arg2);

	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetEditingStateChangedNotification object:nil userInfo:@{
		HSWidgetEditingStateKey : @(arg1)
	}];
}
%end

%hook SBHIconManager
-(void)setEditing:(BOOL)arg1 withFeedbackBehavior:(id)arg2 { // iOS 13
	%orig(arg1, arg2);

	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetEditingStateChangedNotification object:nil userInfo:@{
		HSWidgetEditingStateKey : @(arg1)
	}];
}
%end
