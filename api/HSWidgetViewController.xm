#import "HSWidgetResources.h"
#import "HSWidgetViewController.h"
#import <objc/runtime.h>
#import <Preferences/PSViewController.h>
#import "SBIconController.h"
#import "SBRootFolderController.h"

#import <algorithm>
#import <iterator>
#import <vector>

const CGFloat HSWidgetAnimationDuration = 0.3;
const CGFloat HSWidgetQuickAnimationDuration = 0.13;

NSString *const HSWidgetDisplayCreatorKey = @"HSWidgetDisplayCreatorKey";
NSString *const HSWidgetDisplayIconKey = @"HSWidgetDisplayIconKey";
NSString *const HSWidgetDisplayNameKey = @"HSWidgetDisplayNameKey";
NSString *const HSWidgetEditingStateKey = @"HSWidgetEditingStateKey";

const NSNotificationName HSWidgetAllWidgetsConfiguredNotification = @"HSWidgetAllWidgetsConfiguredNotification";
const NSNotificationName HSWidgetAvailableSpaceDidChangeNotification = @"HSWidgetAvailableSpaceDidChangeNotification";
const NSNotificationName HSWidgetEditingStateChangedNotification = @"HSWidgetEditingStateChangedNotification";

#define EDITING_LONG_PRESS_DELAY 0.08293075930093222 // I found this value btw
#define UPDATE_ACCESSORIES_DELAY 0.5

@interface SBIconView // iOS 5 - 13
+(id)_jitterPositionAnimation; // iOS 5 - 10
+(id)_jitterTransformAnimation; // iOS 5 - 10
+(id)_jitterXTranslationAnimation; // iOS 11 - 13
+(id)_jitterYTranslationAnimation; // iOS 11 - 13
+(id)_jitterRotationAnimation; // iOS 11 - 13
@end

@interface SBHomeScreenMaterialView : UIView // iOS 12 - 13
@end

@interface SBCloseBoxView : UIButton // iOS 7 - 13 (on iOS 11+ this is a subclass of SBHomeScreenButton)
@end

@interface SBXCloseBoxView : SBCloseBoxView // iOS 11 - 13
-(instancetype)initWithFrame:(CGRect)frame; // iOS 11 - 13
-(instancetype)initWithFrame:(CGRect)frame backgroundView:(UIView *)arg2; // iOS 13
-(SBHomeScreenMaterialView *)materialView; // iOS 12 - 13
@end

@interface SBExpandBoxView : SBXCloseBoxView
@end

@interface SBShrinkBoxView : SBXCloseBoxView
@end

@interface SBSettingsBoxView : SBXCloseBoxView
@end

@interface SBWallpaperController : NSObject // iOS 7 - 13
+(instancetype)sharedInstance; // iOS 7 - 13
@end

@interface SBWallpaperEffectView : UIView // iOS 7 - 13
@property (assign, nonatomic) NSInteger wallpaperStyle;
-(instancetype)initWithWallpaperController:(SBWallpaperController *)arg1 variant:(NSInteger)arg2 transformOptions:(NSUInteger)arg3; // iOS 11 - 13
-(instancetype)initWithWallpaperVariant:(NSInteger)arg1 transformOptions:(NSUInteger)arg2; // iOS 10 - 13
@end

@interface CALayer (Private)
@property (assign) BOOL continuousCorners;
@end

typedef NS_ENUM(NSInteger, BoxViewButtonStyle) {
	BoxViewButtonStyleClose = 0,
	BoxViewButtonStyleExpand,
	BoxViewButtonStyleShrink,
	BoxViewButtonStyleSettings
};

@interface HSWidgetViewController () {
@private
	BOOL _isEditing;
	UIView *_editingView;
	UIView *_closeAccessoryView;
	UIView *_expandAccessoryView;
	UIView *_shrinkAccessoryView;
	UIView *_settingsAccessoryView;
	CGPoint _editingWidgetTranslationPoint;
	UIView *_zoomAnimatingView;
	UILongPressGestureRecognizer *_widgetDraggingGesture;
	BOOL _isDraggingWidget;
	BOOL _isPresentingOrDismissingEditingView;
	BOOL _isPresentingOrDismissingExpandAccessoryView;
	BOOL _isPresentingOrDismissingShrinkAccessoryView;
}
@end

static void SetContinuousCornerRadius(UIView *view, CGFloat cornerRadius) {
	view.layer.cornerRadius = cornerRadius;
	// enable continuous corner radius
	if ([view.layer respondsToSelector:@selector(setCornerCurve:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
		// iOS 13+
		view.layer.cornerCurve = kCACornerCurveContinuous;
#pragma clang diagnostic pop
	} else if ([view.layer respondsToSelector:@selector(setContinuousCorners:)]) {
		// iOS 11 - 12
		view.layer.continuousCorners = YES;
	}
}

static BOOL SetupAccessory(UIView *accessoryView, BOOL isEnabled, CGPoint previousButtonOffset, CGPoint globalOffset, CGSize containerSize, BOOL animated, BOOL &isPresentingOrDismissingAccessory) {
	if (isPresentingOrDismissingAccessory) {
		// disable changes to accessory views when we are presenting or dismissing them
		return NO;
	}

	if (isEnabled) {
		if (animated) {
			isPresentingOrDismissingAccessory = YES;

			if (accessoryView.hidden) {
				accessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
				accessoryView.alpha = 0.0;
				accessoryView.hidden = NO;
			}

			CGPoint center = CGPointMake(containerSize.width - previousButtonOffset.x - globalOffset.x, containerSize.height - previousButtonOffset.y - globalOffset.y);
			[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
				accessoryView.transform = CGAffineTransformMakeScale(1.0 , 1.0);
				accessoryView.alpha = 1.0;
				accessoryView.center = center;
			} completion:^(BOOL finished) {
				isPresentingOrDismissingAccessory = NO;
			}];
		} else {
			accessoryView.center = CGPointMake(containerSize.width - previousButtonOffset.x - globalOffset.x, containerSize.height - previousButtonOffset.y - globalOffset.y);
			accessoryView.transform = CGAffineTransformMakeScale(1.0 , 1.0);
			accessoryView.hidden = NO;
		}
	} else {
		if (animated) {
			isPresentingOrDismissingAccessory = YES;

			if (!accessoryView.hidden) {
				accessoryView.transform = CGAffineTransformMakeScale(1.0 , 1.0);
				accessoryView.alpha = 1.0;
			}

			CGPoint center = CGPointMake(containerSize.width - previousButtonOffset.x - globalOffset.x, containerSize.height - previousButtonOffset.y - globalOffset.y);
			[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
				accessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
				accessoryView.alpha = 0.0;
				accessoryView.center = center;
			} completion:^(BOOL finished) {
				accessoryView.hidden = YES;
				accessoryView.alpha = 1.0;
				isPresentingOrDismissingAccessory = NO;
			}];
		} else {
			accessoryView.center = CGPointMake(containerSize.width - previousButtonOffset.x - globalOffset.x, containerSize.height - previousButtonOffset.y - globalOffset.y);
			accessoryView.hidden = YES;
		}
	}

	return YES;
}

@implementation HSWidgetViewController
+(NSBundle *)bundle {
	return [NSBundle bundleForClass:[self class]];
}

+(BOOL)isAvailable {
	return YES;
}

+(BOOL)canAddWidgetForAvailableGridPositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	HSWidgetSize minimumSize = [self minimumSize];
	if (minimumSize.numRows == 0 || minimumSize.numCols == 0) {
		NSString *reason = [NSString stringWithFormat:@"%@ must have a non-zero minimumSize, (%zu, %zu) specified", [self class], minimumSize.numRows, minimumSize.numCols];
		@throw [NSException exceptionWithName:@"HSWidgetsInvalidMinimumSize" reason:reason userInfo:nil];
	}
	return [HSWidgetGridPositionConverterCache canFitWidgetOfSize:minimumSize inGridPositions:positions];
}

+(HSWidgetSize)minimumSize {
	return HSWidgetSizeZero; // should never be able to create widgets of this type
}

+(NSDictionary *)widgetDisplayInfo {
	NSBundle *bundle = [self bundle];
	UIImage *iconImage = [UIImage imageNamed:bundle.infoDictionary[@"HSWidgetIcon"] inBundle:bundle compatibleWithTraitCollection:nil];
	return @{
		HSWidgetDisplayNameKey : bundle.infoDictionary[@"HSWidgetDisplayName"] ?: NSStringFromClass([self class]),
		HSWidgetDisplayIconKey : iconImage ?: [HSWidgetResources imageNamed:HSWidgetPlaceholderImageName],
		HSWidgetDisplayCreatorKey : bundle.infoDictionary[@"HSWidgetCreator"] ?: @"Creator forgot to take credit for their amazing work :("
	};
}

+(Class)addNewWidgetAdditionalOptionsControllerClass {
	return NSClassFromString([self bundle].infoDictionary[@"HSWidgetAddNewOptionsControllerClass"]);
}

+(Class)preferencesOptionsControllerClass {
	return NSClassFromString([self bundle].infoDictionary[@"HSWidgetPreferencesControllerClass"]);
}

+(NSDictionary *)createOptionsFromController:(id<HSWidgetAdditionalOptions>)controller withAvailableGridPosition:(NSArray<HSWidgetPositionObject *> *)positions {
	return [NSDictionary dictionaryWithDictionary:controller.widgetOptions];
}

+(HSWidgetSize)widgetSizeFromController:(nullable id<HSWidgetAdditionalOptions>)controller withAvailableGridPosition:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	if (controller != nil && controller.requestWidgetSize.numRows > 0 && controller.requestWidgetSize.numCols > 0) {
		return controller.requestWidgetSize;
	}
	return [self minimumSize];
}

+(NSInteger)allowedInstancesPerPage {
	return -1; // -1 = unlimited
}

-(instancetype)initForWidgetFrame:(HSWidgetFrame)frame withOptions:(NSDictionary *)options {
	self = [super init];
	if (self != nil) {
		self.widgetFrame = frame; // grid frame (origin, size) of the widget
		self.requestedSize = CGSizeZero; // request size of the view
		self.cornerRadius = 13.0; // corner radius of the view (used for editing view)
		_isEditing = NO;
		_editingView = nil;
		_isPresentingOrDismissingEditingView = NO;
		_closeAccessoryView = nil;
		_expandAccessoryView = nil;
		_isPresentingOrDismissingExpandAccessoryView = NO;
		_shrinkAccessoryView = nil;
		_isPresentingOrDismissingShrinkAccessoryView = NO;
		_settingsAccessoryView = nil;
		_delegate = nil;
		_zoomAnimatingView = nil;
		_widgetDraggingGesture = nil;
		_isDraggingWidget = NO;
		if (options != nil) {
			widgetOptions = [options mutableCopy]; // need to make copy so we can modify it
		}
	}
	return self;
}

-(NSDictionary *)options {
	return widgetOptions;
}

-(void)setWidgetOptionValue:(id<NSCoding>)object forKey:(NSString *)key {
	if (object == nil) {
		[widgetOptions removeObjectForKey:key];
	} else {
		if (widgetOptions == nil) {
			widgetOptions = [[NSMutableDictionary alloc] init];
		}

		widgetOptions[key] = object;
	}

	[_delegate widgetOptionsChanged:self];
}

-(void)_setDelegate:(id<HSWidgetDelegate>)delegate {
	_delegate = delegate;
}

-(CGRect)calculatedFrame {
	return (CGRect){{0, 0}, self.requestedSize}; // frame of the container view (used for editing view)
}

-(void)setRequestedSize:(CGSize)requestedSize {
	_requestedSize = requestedSize;

	if (_isEditing) {
		[self.view bringSubviewToFront:_editingView];
	}

	_editingView.frame = [self calculatedFrame];
	[self _updateAccessoryViewsAnimated:NO];
}

-(void)setWidgetFrame:(HSWidgetFrame)frame {
	// check for invalid size or position
	if (frame.origin.row == 0 || frame.origin.col == 0 || frame.size.numRows == 0 || frame.size.numCols == 0) {
		return;
	}

	if (!HSWidgetFrameEqualsFrame(_widgetFrame, frame)) {
		self._gridPositions = [HSWidgetGridPositionConverterCache gridPositionsForWidgetFrame:frame];
	}

	_widgetFrame = frame;
}

-(void)setCornerRadius:(CGFloat)cornerRadius {
	_cornerRadius = cornerRadius;
	SetContinuousCornerRadius(_editingView, cornerRadius);

	// re-set the corner radius of the accessories
	// _expandAccessoryView.layer.cornerRadius = cornerRadius / _expandAccessoryView.frame.size.width;
	// _shrinkAccessoryView.layer.cornerRadius = cornerRadius / _shrinkAccessoryView.frame.size.width;
	// _settingsAccessoryView.layer.cornerRadius = cornerRadius / _settingsAccessoryView.frame.size.width;
}

-(SBCloseBoxView *)_createButtonBoxView:(SEL)action withStyle:(BoxViewButtonStyle)buttonStyle {
	SBCloseBoxView *buttonBoxView = nil;
	if (%c(SBXCloseBoxView)) {
		Class boxViewClass = nil;
		if (buttonStyle == BoxViewButtonStyleClose) {
			boxViewClass = %c(SBXCloseBoxView);
		} else if (buttonStyle == BoxViewButtonStyleExpand) {
			boxViewClass = %c(SBExpandBoxView);
		} else if (buttonStyle == BoxViewButtonStyleShrink) {
			boxViewClass = %c(SBShrinkBoxView);
		} else if (buttonStyle == BoxViewButtonStyleSettings) {
			boxViewClass = %c(SBSettingsBoxView);
		}

		if ([%c(SBXCloseBoxView) instancesRespondToSelector:@selector(initWithFrame:backgroundView:)]) {
			// fix the background view on iOS 13
			SBWallpaperEffectView *wallpaperEffectView = nil;
			if ([%c(SBWallpaperEffectView) instancesRespondToSelector:@selector(initWithWallpaperController:variant:transformOptions:)]) {
				wallpaperEffectView = [[%c(SBWallpaperEffectView) alloc] initWithWallpaperController:[%c(SBWallpaperController) sharedInstance] variant:1 transformOptions:0];
			} else if ([%c(SBWallpaperEffectView) instancesRespondToSelector:@selector(initWithWallpaperVariant:transformOptions:)]) {
				wallpaperEffectView = [[%c(SBWallpaperEffectView) alloc] initWithWallpaperVariant:1 transformOptions:0];
			}
			wallpaperEffectView.wallpaperStyle = 29;
			buttonBoxView = [[boxViewClass alloc] initWithFrame:CGRectZero backgroundView:wallpaperEffectView];
			
			[wallpaperEffectView release];
		} else {
			buttonBoxView = [[boxViewClass alloc] initWithFrame:CGRectZero];
		}
	} else {
		buttonBoxView = [[%c(SBCloseBoxView) alloc] initWithFrame:CGRectZero];
	}
	[buttonBoxView addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
	[buttonBoxView sizeToFit];
	return buttonBoxView;
}

-(void)loadView {
	HSWidgetUnclippedView *unclippedView = [[HSWidgetUnclippedView alloc] initWithFrame:CGRectZero];
	self.view = unclippedView;
	[unclippedView release];
}

-(void)viewDidLoad {
	[super viewDidLoad];

	@autoreleasepool {
		CGRect frame = [self calculatedFrame];

		// fix negative size causing incorrect bounds initialization
		frame.size.width = MAX(frame.size.width, 0);
		frame.size.height = MAX(frame.size.height, 0);

		_editingView = [[HSWidgetUnclippedView alloc] initWithFrame:frame];
		SetContinuousCornerRadius(_editingView, self.cornerRadius);

		[self.view addSubview:_editingView];
		_editingView.hidden = YES;

		_closeAccessoryView = [self _createButtonBoxView:@selector(_closeTapped) withStyle:BoxViewButtonStyleClose];
		_closeAccessoryView.center = CGPointZero;
		[_editingView addSubview:_closeAccessoryView];

		_expandAccessoryView = [self _createButtonBoxView:@selector(_expandTapped) withStyle:BoxViewButtonStyleExpand];
		UIImage *expandImage = [HSWidgetResources imageNamed:HSWidgetExpandImageName];
		if (![_expandAccessoryView isKindOfClass:%c(SBXCloseBoxView)]) {
			((UIImageView *)[_expandAccessoryView valueForKey:@"xColorBurnView"]).image = expandImage;
			((UIImageView *)[_expandAccessoryView valueForKey:@"xPlusDView"]).image = expandImage;
		}
		_expandAccessoryView.center = CGPointMake(_editingView.frame.size.width, _editingView.frame.size.height);
		// _expandAccessoryView.layer.cornerRadius = self.cornerRadius / _expandAccessoryView.frame.size.width;
		_expandAccessoryView.hidden = YES;
		[_editingView addSubview:_expandAccessoryView];

		_shrinkAccessoryView = [self _createButtonBoxView:@selector(_shrinkTapped) withStyle:BoxViewButtonStyleShrink];
		UIImage *shrinkImage = [HSWidgetResources imageNamed:HSWidgetShrinkImageName];
		if (![_shrinkAccessoryView isKindOfClass:%c(SBXCloseBoxView)]) {
			((UIImageView *)[_shrinkAccessoryView valueForKey:@"xColorBurnView"]).image = shrinkImage;
			((UIImageView *)[_shrinkAccessoryView valueForKey:@"xPlusDView"]).image = shrinkImage;
		}
		_shrinkAccessoryView.center = CGPointMake(_editingView.frame.size.width - _expandAccessoryView.frame.size.width * 3.0 / 2.0, _editingView.frame.size.height);
		// _shrinkAccessoryView.layer.cornerRadius = self.cornerRadius / _shrinkAccessoryView.frame.size.width;
		_shrinkAccessoryView.hidden = YES;
		[_editingView addSubview:_shrinkAccessoryView];

		_settingsAccessoryView = [self _createButtonBoxView:@selector(_settingsTapped) withStyle:BoxViewButtonStyleSettings];
		UIImage *settingsImage = [HSWidgetResources imageNamed:HSWidgetSettingsImageName];
		if (![_settingsAccessoryView isKindOfClass:%c(SBXCloseBoxView)]) {
			((UIImageView *)[_settingsAccessoryView valueForKey:@"xColorBurnView"]).image = settingsImage;
			((UIImageView *)[_settingsAccessoryView valueForKey:@"xPlusDView"]).image = settingsImage;
		}
		_settingsAccessoryView.center = CGPointMake(_editingView.frame.size.width, 0);
		// _settingsAccessoryView.layer.cornerRadius = self.cornerRadius / _settingsAccessoryView.frame.size.width;
		_settingsAccessoryView.hidden = YES;
		[_editingView addSubview:_settingsAccessoryView];

		_widgetDraggingGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_editingWidgetMoved:)];
		_widgetDraggingGesture.minimumPressDuration = EDITING_LONG_PRESS_DELAY;
		_widgetDraggingGesture.allowableMovement = INFINITY;
		[_editingView addGestureRecognizer:_widgetDraggingGesture];

		[self _updateViewsForEditingStateChange:[[[%c(SBIconController) sharedInstance] _rootFolderController] isEditing]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_editingStateChanged:) name:HSWidgetEditingStateChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_availableSpaceDidChange) name:HSWidgetAvailableSpaceDidChangeNotification object:nil];
	}
}

-(void)_closeTapped {
	[self _forceEndWidgetDragging:YES];
	[_delegate closeTapped:self];
}

-(void)_expandTapped {
	// notify the widget of tap for custom actions
	[self accessoryTypeTapped:AccessoryTypeExpand];
}

-(void)_shrinkTapped {
	// notify the widget of tap for custom actions
	[self accessoryTypeTapped:AccessoryTypeShrink];
}

-(void)_settingsTapped {
	[self _forceEndWidgetDragging:NO];

	// display the preferences class if provided
	[_delegate settingsTapped:self];

	// notify the widget of tap for custom actions
	[self accessoryTypeTapped:AccessoryTypeSettings];
}

-(BOOL)isAccessoryTypeEnabled:(AccessoryType)accessory {
	// if accessory type is settings then check if there is a controller provided
	if (accessory == AccessoryTypeSettings) {
		return [[self class] preferencesOptionsControllerClass] != nil;
	}

	// default disable accessories
	return NO;
}

-(void)accessoryTypeTapped:(AccessoryType)accessory {
	// do nothing
}

-(HSWidgetPosition)_positionForExpandOrShrinkToWidgetSize:(HSWidgetSize)size {
	NSInteger diffRow = size.numRows - self.widgetFrame.size.numRows;
	NSInteger diffCol = size.numCols - self.widgetFrame.size.numCols;

	// create positions based on corner anchors (set makes sure there are no duplicates)
	std::vector<HSWidgetPosition> positions;
	positions.push_back(self.widgetFrame.origin); // anchor current position (top left corner)
	if (diffRow % 2 == 0 && diffCol % 2 == 0) {
		positions.push_back(HSWidgetPositionAdd(self.widgetFrame.origin, -diffRow / 2, -diffCol / 2)); // anchor center middle
	} else {
		if (diffRow % 2 == 0) {
			positions.push_back(HSWidgetPositionAdd(self.widgetFrame.origin, 0, -diffCol / 2)); // anchor left middle
			positions.push_back(HSWidgetPositionAdd(self.widgetFrame.origin, -diffRow, -diffCol / 2)); // anchor right middle
		} else if (diffCol % 2 == 0) {
			positions.push_back(HSWidgetPositionAdd(self.widgetFrame.origin, 0, -diffCol / 2)); // anchor top middle
			positions.push_back(HSWidgetPositionAdd(self.widgetFrame.origin, -diffRow, -diffCol / 2)); // anchor bottom middle
		}
	}
	positions.push_back(HSWidgetPositionAdd(self.widgetFrame.origin, -diffRow, -diffCol)); // anchor bottom right corner
	positions.push_back(HSWidgetPositionAdd(self.widgetFrame.origin, 0, -diffCol)); // anchor top right corner
	positions.push_back(HSWidgetPositionAdd(self.widgetFrame.origin, -diffRow, 0)); //anchor bottom left corner

	for (auto iter = positions.begin(); iter != positions.end(); ++iter) {
		HSWidgetPosition position = *iter;
		auto endIter = std::find_if(positions.begin(), iter, [&position](const HSWidgetPosition &otherPosition) {
			return position.row == otherPosition.row && position.col == otherPosition.col;
		});
		if (endIter != iter) {
			continue; // duplicate entry so skip it since we already tried earlier
		}

		// convert position to a valid position for size, expanding using this position may put the widget out of page bounds
		HSWidgetPosition validPosition = [_delegate widgetOriginForWidgetSize:size withPreferredOrigin:position];
	
		if (!HSWidgetPositionEqualsPosition(validPosition, HSWidgetPositionZero)) {
			// check if there is grid positions for this position and size
			HSWidgetFrame resultWidgetFrame = HSWidgetFrameMake(validPosition, size);
			NSMutableArray<HSWidgetPositionObject *> *positions = [HSWidgetGridPositionConverterCache gridPositionsForWidgetFrame:resultWidgetFrame];
			if ([self containsSpaceToExpandOrShrinkToGridPositions:positions]) {
				return validPosition;
			}
		}
	}

	// can't fit so return invalid position
	return HSWidgetPositionZero;
}

-(BOOL)containsSpaceToExpandOrShrinkToGridPositions:(NSArray<HSWidgetPositionObject *> *)positions {
	return [_delegate canWidget:self expandOrShrinkToGridPositions:positions];
}

-(BOOL)containsSpaceToExpandOrShrinkToWidgetSize:(HSWidgetSize)size {
	return !HSWidgetPositionEqualsPosition([self _positionForExpandOrShrinkToWidgetSize:size], HSWidgetPositionZero);
}

-(void)updateForExpandOrShrinkToGridPositions:(NSArray<HSWidgetPositionObject *> *)positions {
	self._gridPositions = positions;

	[_delegate updatePageForExpandOrShrinkOfWidget:self toGridPositions:positions];
}

-(void)updateForExpandOrShrinkToWidgetSize:(HSWidgetSize)size {
	// check if can fit (maybe size isn't valid)
	HSWidgetPosition newPosition = [self _positionForExpandOrShrinkToWidgetSize:size];
	if (!HSWidgetPositionEqualsPosition(newPosition, HSWidgetPositionZero)) {
		self.widgetFrame = HSWidgetFrameMake(newPosition, size);

		// self._gridPositions gets updated in setWidgetFrame: so tell delegate to update visually
		[_delegate updatePageForExpandOrShrinkOfWidget:self toGridPositions:self._gridPositions];
	}
}

-(ZoomAnimationViewStyle)viewStyleForZoomAnimaton {
	return ZoomAnimationViewStyleDefault;
}

-(UIView *)zoomAnimatingView {
	if ([self viewStyleForZoomAnimaton] == ZoomAnimationViewStyleDefault) {
		return self.view;
	}

	if ([self viewStyleForZoomAnimaton] == ZoomAnimationViewStyleImageCopy && _zoomAnimatingView == nil) {
		CGRect frame = [self calculatedFrame];
		// create an image of the layer for animation purposes
		UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0.0);
		// [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
		[self.view drawViewHierarchyInRect:(CGRect){CGPointZero, frame.size} afterScreenUpdates:NO];
		UIImage *widgetViewImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		_zoomAnimatingView = [[UIImageView alloc] initWithImage:widgetViewImage];
		_zoomAnimatingView.frame = (CGRect){self.view.frame.origin, frame.size};
	}
	return _zoomAnimatingView;
}

-(void)clearZoomAnimatingView {
	if ([self viewStyleForZoomAnimaton] == ZoomAnimationViewStyleDefault) {
		return; // do nothing if we are using viewcontroller's view
	}

	if ([self viewStyleForZoomAnimaton] == ZoomAnimationViewStyleImageCopy || _zoomAnimatingView != nil) {
		[_zoomAnimatingView removeFromSuperview];
		[_zoomAnimatingView release];
	}

	_zoomAnimatingView = nil;
}

-(void)_updateAccessoryViewsAnimated:(BOOL)animated {
	if (_isPresentingOrDismissingEditingView) {
		// disable changes to accessory views when we are presenting or dismissing editing view
		return;
	}

	// Use _closeAccessoryView for sizing animations since all the buttons should have same size
	CGFloat buttonWidth = _closeAccessoryView.frame.size.width;
	CGFloat buttonHeight = _closeAccessoryView.frame.size.height;

	BOOL isExpandEnabled = [self isAccessoryTypeEnabled:AccessoryTypeExpand];
	BOOL isShrinkEnabled = [self isAccessoryTypeEnabled:AccessoryTypeShrink];
	BOOL isSettingEnabled = [self isAccessoryTypeEnabled:AccessoryTypeSettings];

	// if both expand and shrink accessories are enabled and
	BOOL useAlternativeExpandOrShrinkLayout = isExpandEnabled && isShrinkEnabled && self.requestedSize.width < buttonWidth * 3;

	BOOL isCompactMode = self.widgetFrame.size.numCols == 1 || self.widgetFrame.size.numRows == 1;
	CGPoint globalShrinkOrExpandOffset = isCompactMode ? CGPointZero : CGPointMake(buttonWidth, buttonHeight);
	CGPoint globalSettingsOffset = isCompactMode ? CGPointZero : CGPointMake(buttonWidth, -buttonHeight);
	CGSize expandOrShrinkContainerSize = _editingView.frame.size;
	CGSize settingsContainerSize = CGSizeMake(_editingView.frame.size.width, 0);

	// update position of close box view
	CGPoint closeCenter = isCompactMode ? CGPointZero : CGPointMake(buttonWidth, buttonHeight);
	if (animated) {
		[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
			_closeAccessoryView.center = closeCenter;
		} completion:nil];
	} else {
		_closeAccessoryView.center = closeCenter;
	}

	// update position/transform of expand box view
	BOOL didUpdateExpandAccessory = SetupAccessory(_expandAccessoryView, isExpandEnabled, CGPointZero, globalShrinkOrExpandOffset, expandOrShrinkContainerSize, animated, _isPresentingOrDismissingExpandAccessoryView);

	// update position/transform of shrink box view
	CGPoint shrinkPreviousButtonOffset;
	if (useAlternativeExpandOrShrinkLayout) {
		shrinkPreviousButtonOffset = CGPointMake(0.0, isExpandEnabled ? buttonWidth * 3.0 / 2.0 : 0.0);
	} else {
		shrinkPreviousButtonOffset = CGPointMake(isExpandEnabled ? buttonWidth * 3.0 / 2.0 : 0.0, 0.0);
	}
	BOOL didUpdateShrinkAccessory = SetupAccessory(_shrinkAccessoryView, isShrinkEnabled, shrinkPreviousButtonOffset, globalShrinkOrExpandOffset, expandOrShrinkContainerSize, animated, _isPresentingOrDismissingShrinkAccessoryView);

	// update position/transform of settings box view
	BOOL isPresentingOrDismissingSettings = NO;
	SetupAccessory(_settingsAccessoryView, isSettingEnabled, CGPointZero, globalSettingsOffset, settingsContainerSize, animated, isPresentingOrDismissingSettings);

	// fix accessories sometimes not being updated when released too soon
	if (!didUpdateExpandAccessory || !didUpdateShrinkAccessory) {
		// always animate the accessory update when being called after a delay
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateAccessoryViewsAnimated:) object:@YES];
		[self performSelector:@selector(_updateAccessoryViewsAnimated:) withObject:@YES afterDelay:UPDATE_ACCESSORIES_DELAY];
	}
}

-(void)_editingWidgetMoved:(UILongPressGestureRecognizer *)sender {
	if ([_delegate canDragWidget:self]) {
		if (sender.state == UIGestureRecognizerStateBegan) {
			_isDraggingWidget = YES;
			[self _removeEditingAnimations];
			[_delegate setDraggingWidget:self];
			_editingWidgetTranslationPoint = [sender locationInView:sender.view.superview]; // translate to self.view
		} else if (sender.state == UIGestureRecognizerStateChanged) {
			CGPoint translatedPoint = [sender locationInView:sender.view.superview.superview]; // translate to icon list view
			translatedPoint.x -= _editingWidgetTranslationPoint.x;
			translatedPoint.y -= _editingWidgetTranslationPoint.y;
			[_delegate widgetDragged:self toPoint:translatedPoint];
		} else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateFailed) {
			[self _insertEditingAnimations];
			[_delegate setDraggingWidget:nil];
			_isDraggingWidget = NO;
		}
	}
}

-(void)_animateInEditingView {
	_isPresentingOrDismissingEditingView = YES;
	_closeAccessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
	_expandAccessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
	_shrinkAccessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
	_settingsAccessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
	@autoreleasepool {
		_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
		[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
			_closeAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_expandAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_shrinkAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_settingsAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
		} completion:^(BOOL finished) {
			_closeAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_expandAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_shrinkAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_settingsAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
			_isPresentingOrDismissingEditingView = NO;
		}];
	}
}

-(void)_animateOutEditingView {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateAccessoryViewsAnimated:) object:@YES];

	_isPresentingOrDismissingEditingView = YES;
	_closeAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
	_expandAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
	_shrinkAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
	_settingsAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
	@autoreleasepool {
		_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
		[UIView animateWithDuration:HSWidgetAnimationDuration animations:^{
			_closeAccessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
			_expandAccessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
			_shrinkAccessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
			_settingsAccessoryView.transform = CGAffineTransformMakeScale(0.1, 0.1);
			_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
		} completion:^(BOOL finished) {
			_editingView.hidden = YES;
			_closeAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_expandAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_shrinkAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_settingsAccessoryView.transform = CGAffineTransformMakeScale(1, 1);
			_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
			_isPresentingOrDismissingEditingView = NO;
		}];
	}
}

-(void)_editingStateChanged:(NSNotification *)notification {
	[self _updateViewsForEditingStateChange:[notification.userInfo[HSWidgetEditingStateKey] boolValue]];
}

-(void)_updateViewsForEditingStateChange:(BOOL)isEditing {
	if (isEditing != _isEditing) {
		_isEditing = isEditing;
		if (isEditing) {
			[self _updateAccessoryViewsAnimated:NO];
			[self _insertEditingAnimations];

			if (_editingView.hidden) {
				_editingView.frame = [self calculatedFrame];
				[self.view bringSubviewToFront:_editingView];

				_editingView.hidden = NO;

				// fix zoom animation adding a visual delay for going into editing mode when not using default style
				if (_zoomAnimatingView != nil) {
					[self clearZoomAnimatingView];
					self.view.alpha = 1.0;
				}

				[self _animateInEditingView];
			}
		} else {
			[self _forceEndWidgetDragging:YES];

			if (!_editingView.hidden) {
				[self _animateOutEditingView];
			}
		}
	}
}

-(void)_forceEndWidgetDragging:(BOOL)removingAnimations {
	_widgetDraggingGesture.enabled = NO;
	_widgetDraggingGesture.enabled = YES;

	if (removingAnimations) {
		[self _removeEditingAnimations];
	}

	if (_isDraggingWidget) {
		[_delegate setDraggingWidget:nil];
		_isDraggingWidget = NO;
	}
}

-(void)_insertEditingAnimations {
	// translation/position
	if ([%c(SBIconView) respondsToSelector:@selector(_jitterPositionAnimation)])
		[self.view.layer addAnimation:[%c(SBIconView) _jitterPositionAnimation] forKey:@"HSWidgetPosition"];
	if ([%c(SBIconView) respondsToSelector:@selector(_jitterXTranslationAnimation)])
		[self.view.layer addAnimation:[%c(SBIconView) _jitterXTranslationAnimation] forKey:@"HSWidgetPositionX"];
	if ([%c(SBIconView) respondsToSelector:@selector(_jitterYTranslationAnimation)])
		[self.view.layer addAnimation:[%c(SBIconView) _jitterYTranslationAnimation] forKey:@"HSWidgetPositionY"];

	// rotation/transformation
	if ([%c(SBIconView) respondsToSelector:@selector(_jitterTransformAnimation)])
		[self.view.layer addAnimation:[%c(SBIconView) _jitterTransformAnimation] forKey:@"HSWidgetTransform"];
	if ([%c(SBIconView) respondsToSelector:@selector(_jitterRotationAnimation)])
		[self.view.layer addAnimation:[%c(SBIconView) _jitterRotationAnimation] forKey:@"HSWidgetRotation"];
}

-(void)_removeEditingAnimations {
	// translation/position
	[self.view.layer removeAnimationForKey:@"HSWidgetPosition"];
	[self.view.layer removeAnimationForKey:@"HSWidgetPositionX"];
	[self.view.layer removeAnimationForKey:@"HSWidgetPositionY"];

	// rotation/transformation
	[self.view.layer removeAnimationForKey:@"HSWidgetTransform"];
	[self.view.layer removeAnimationForKey:@"HSWidgetRotation"];
}

-(void)_availableSpaceDidChange {
	[self _updateAccessoryViewsAnimated:YES];
}

-(void)dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateAccessoryViewsAnimated:) object:@YES];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:HSWidgetEditingStateChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:HSWidgetAvailableSpaceDidChangeNotification object:nil];

	[_widgetDraggingGesture release];
	_widgetDraggingGesture = nil;

	[_editingView removeFromSuperview];
	[_editingView release];
	_editingView = nil;

	[_closeAccessoryView removeFromSuperview];
	[_closeAccessoryView release];
	_closeAccessoryView = nil;

	[_expandAccessoryView removeFromSuperview];
	[_expandAccessoryView release];
	_expandAccessoryView = nil;

	[_shrinkAccessoryView removeFromSuperview];
	[_shrinkAccessoryView release];
	_shrinkAccessoryView = nil;

	[_settingsAccessoryView removeFromSuperview];
	[_settingsAccessoryView release];
	_settingsAccessoryView = nil;

	[self clearZoomAnimatingView];

	_delegate = nil;

	[widgetOptions release];
	widgetOptions = nil;

	[super dealloc];
}
@end
