#import <UIKit/UIKit.h>
#import "HSWidgets-core.h"
#import "HSWidgetPageController.h"
#import "HSWidgetViewController.h"
#import "SBIconController.h"
#import "SBIconCoordinate.h"
#import "SBIconListModel.h"
#import "SBIconListView.h"
#import "SBRootFolderController.h"

@interface AnimationSettings // iOS 7 - 12 (SBAnimationSettings), iOS 13 (SBFAnimationSettings)
-(id)BSAnimationSettings; // iOS 8 - 13
@property (assign,nonatomic) CGFloat mass; // iOS 7 - 13
@property (assign,nonatomic) NSTimeInterval delay; // iOS 7 - 13
@end

@interface CenterZoomSettings // iOS 7 - 12 (SBCenterZoomSettings), iOS 13 (SBHCenterZoomSettings)
@property (assign) CGFloat centerRowCoordinate; // iOS 7 - 13
-(AnimationSettings *)centralAnimationSettings; // inherited
-(NSInteger)distanceEffect; // iOS 7 - 13
-(CGFloat)firstHopIncrement; // iOS 7 - 13
-(double)hopIncrementAcceleration; // iOS 7 - 13
@end

@interface SBCenterIconZoomAnimator : NSObject // iOS 7 - 13
@property (nonatomic,retain) CenterZoomSettings *settings; // iOS 7 - 13
@property (nonatomic,readonly) SBIconListView *iconListView; // inherited
@property (nonatomic,readonly) UIView * zoomView; // iOS 7 - 13
-(CGFloat)_iconZoomDelay; // iOS 7 - 13
-(CGPoint)cameraPosition; // iOS 7 - 13
-(id)_animationFactoryForWidget:(id)widgetViewController;
@end

@interface SBCoverSheetIconFlyInAnimator : SBCenterIconZoomAnimator // iOS 11 - 13
@end

@interface BSAnimationSettings // iOS 8 - 13
-(void)applyToCAAnimation:(id)arg1; // iOS 9 - 13
-(void)_setDelay:(NSTimeInterval)arg1; // iOS 8 - 13
-(NSTimeInterval)delay; // iOS 8 - 13
-(void)_setSpeed:(float)arg1; // iOS 10 - 13
-(CGFloat)speed; // iOS 10 - 13
@end

@interface BSUIAnimationFactory // iOS 9 - 13
@property (nonatomic,copy,readonly) BSAnimationSettings *settings; // iOS 9 - 13
+(id)factoryWithSettings:(id)arg1; // iOS 9 - 13
+(CGFloat)globalSlowDownFactor; // iOS 9 - 13
-(void)setAllowsAdditiveAnimations:(BOOL)arg1; // iOS 10 - 13
// +(void)animateWithFactory:(id)arg1 additionalDelay:(NSTimeInterval)arg2 options:(NSUInteger)arg3 actions:(id)arg4 completion:(id)arg5; // iOS 9 - 13
@end

@interface CoverSheetTransitionSettings : NSObject // SBCoverSheetTransitionSettings in iOS 11 - 12 and CSCoverSheetTransitionSettings in iOS 13
-(BOOL)iconsFlyIn; // iOS 11 - 13
@end

@interface SBCoverSheetPresentationManager : NSObject // iOS 11 - 13
+(id)sharedInstance;
-(CoverSheetTransitionSettings *)transitionSettings;; // iOS 13
@end

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

// fix widgets being lost on respring when reduce motion is enabled or fly in animations are disabled
%hook SBCoverSheetPresentationManager
-(void)_prepareForDismissalTransition {
	%orig;

	static BOOL isFirstIconAnimationAfterRespring = YES;
	if (isFirstIconAnimationAfterRespring && (UIAccessibilityIsReduceMotionEnabled() || ![[self transitionSettings] iconsFlyIn])) {
		SBIconController *iconController = [%c(SBIconController) sharedInstance];
		SBRootFolderController *rootFolderController = [iconController _rootFolderController];
		ConfigureWidgetsIfNeeded(rootFolderController.iconListViews);

		isFirstIconAnimationAfterRespring = NO;
	}
}
%end

%hook SBCenterIconZoomAnimator
-(void)_prepareAnimation {
	%orig;

	static BOOL isFirstZoomAnimationAfterRespring = YES;
	if (isFirstZoomAnimationAfterRespring) {
		SBIconController *iconController = [%c(SBIconController) sharedInstance];
		SBRootFolderController *rootFolderController = [iconController _rootFolderController];
		ConfigureWidgetsIfNeeded(rootFolderController.iconListViews);

		isFirstZoomAnimationAfterRespring = NO;
	}

	SBIconListModel *model = [self.iconListView valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			[self.zoomView addSubview:[widgetViewController zoomAnimatingView]];
		}
	}
}

-(void)_cleanupAnimation {
	%orig;

	SBIconListModel *model = [self.iconListView valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			[[widgetViewController zoomAnimatingView].layer removeAnimationForKey:@"HSWidgetZPosition"];
			[widgetViewController clearZoomAnimatingView];
			if ([widgetViewController viewStyleForZoomAnimaton] != ZoomAnimationViewStyleDefault) {
				widgetViewController.view.alpha = 1.0;
			} else {
				[self.iconListView addSubview:[widgetViewController zoomAnimatingView]]; // move the view back to root icon list view
			}
		}
	}
}

-(void)_calculateCentersAndCameraPosition {
	SBIconListModel *model = [self.iconListView valueForKey:@"_model"];
	PageType currentPageType = model.pageLayoutType;
	model.pageLayoutType = PageTypeNone;
	%orig;
	model.pageLayoutType = currentPageType;
	
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		CGFloat *_centerRow = &MSHookIvar<CGFloat>(self, "_centerRow");
		CGFloat *_centerCol = &MSHookIvar<CGFloat>(self, "_centerCol");
		NSInteger centerRow = *_centerRow;
		NSInteger centerCol = *_centerCol;

		CGFloat offsetY = 0;
		for (NSInteger row = centerRow; row > 0; --row) {
			BOOL rowContainsWidget = NO;
			HSWidgetPosition rowPosition = HSWidgetPositionMake(row, centerCol);
			for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
				if (HSWidgetFrameContainsPosition(widgetViewController.widgetFrame, rowPosition)) {
					rowContainsWidget = YES;
					break;
				}
			}

			if (rowContainsWidget) {
				offsetY += 0.5;
			}
		}

		// update center row to make it look a little better
		*_centerRow = *_centerRow - offsetY;
	}
}

-(void)_performAnimationToFraction:(CGFloat)arg1 withCentralAnimationSettings:(id)arg2 delay:(NSTimeInterval)arg3 alreadyAnimating:(BOOL)arg4 sharedCompletion:(void (^)(BOOL finished))arg5 {
	// TODO: Fix the bug where the widget animation is quicker/less delayed than the icon animaiton (seems to be an iOS issue)
	SBIconListModel *model = [self.iconListView valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		NSTimeInterval additionalDelay = arg3 + [self _iconZoomDelay];
		CGFloat iconZoomedZ = MSHookIvar<CGFloat>(self, "_iconZoomedZ");
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			/* // doesn't animate since zPosition isn't animated by default but this is the approach used by apple
			[%c(BSUIAnimationFactory) animateWithFactory:[self _animationFactoryForWidget:widgetViewController] additionalDelay:additionalDelay options:2 actions:^{
				[widgetViewController zoomAnimatingView].layer.zPosition = arg1 * iconZoomedZ;
			} completion:arg5];*/
			BSUIAnimationFactory *animationFactory = [self _animationFactoryForWidget:widgetViewController];
			BSAnimationSettings *animationSettings = animationFactory.settings;
			[animationSettings _setSpeed:1.0 / [%c(BSUIAnimationFactory) globalSlowDownFactor]];
			[animationSettings _setDelay:[animationSettings delay] + additionalDelay];

			[CATransaction begin];
			[CATransaction setCompletionBlock:^{
				if ([widgetViewController viewStyleForZoomAnimaton] != ZoomAnimationViewStyleDefault) {
					if (arg1 == 0) {
						widgetViewController.view.alpha = 1.0;
					}
					[widgetViewController zoomAnimatingView].alpha = 0.0;
				}

				if (arg5 != nil) {
					arg5(YES);
				}
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
	SBIconListModel *model = [self.iconListView valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		result += [model.widgetViewControllers count];
	}
	return result;
}

-(void)_setAnimationFraction:(CGFloat)arg1 {
	SBIconListModel *model = [self.iconListView valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil && ![self respondsToSelector:@selector(_setAnimationFraction:withCenter:)]) {
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			[widgetViewController zoomAnimatingView].layer.zPosition = arg1 * MSHookIvar<CGFloat>(self, "_iconZoomedZ");
			if ([widgetViewController viewStyleForZoomAnimaton] != ZoomAnimationViewStyleDefault) {
				widgetViewController.view.alpha = 0.0;
				[widgetViewController zoomAnimatingView].alpha = 1.0;
			}
			[[widgetViewController zoomAnimatingView].layer removeAnimationForKey:@"HSWidgetZPosition"];
		}
	}

	%orig(arg1);
}

-(void)_setAnimationFraction:(CGFloat)arg1 withCenter:(CGPoint)arg2 {
	// On iOS 11+, SBCoverSheetPresentationManager manages the icon animator which creates a custom function to animate zPosition
	SBIconListModel *model = [self.iconListView valueForKey:@"_model"];
	if (model.pageLayoutType != PageTypeNone && model.widgetViewControllers != nil) {
		for (HSWidgetViewController *widgetViewController in model.widgetViewControllers) {
			[widgetViewController zoomAnimatingView].layer.zPosition = arg1 * MSHookIvar<CGFloat>(self, "_iconZoomedZ");
			if ([widgetViewController viewStyleForZoomAnimaton] != ZoomAnimationViewStyleDefault) {
				widgetViewController.view.alpha = 0.0;
				[widgetViewController zoomAnimatingView].alpha = 1.0;
			}
			[[widgetViewController zoomAnimatingView].layer removeAnimationForKey:@"HSWidgetZPosition"];
		}
	}

	%orig(arg1, arg2);
}

%new
-(id)_animationFactoryForWidget:(HSWidgetViewController *)widgetViewController {
	AnimationSettings *animationSettings = [self.settings centralAnimationSettings];
	CGFloat distanceEffect = [self.settings distanceEffect];
	if (distanceEffect > 0 && widgetViewController != nil) {
		HSWidgetFrame widgetFrame = widgetViewController.widgetFrame;
		CGFloat widgetCenterRow = (widgetFrame.origin.row + widgetFrame.size.numRows) / 2.0;
		CGFloat widgetCenterCol = (widgetFrame.origin.col + widgetFrame.size.numCols) / 2.0;
		CGFloat diffRow = fabs(widgetCenterRow - MSHookIvar<CGFloat>(self, "_centerRow"));
		CGFloat diffCol = fabs(widgetCenterCol - MSHookIvar<CGFloat>(self, "_centerCol"));
		NSInteger totalIncrements = floorf(diffRow + diffCol);
		CGFloat currentIncrement = [self.settings firstHopIncrement];
		CGFloat currentMass = animationSettings.mass;
		if (currentIncrement > 0.0 && totalIncrements != 0) {
			NSInteger i = 1;
			do {
				currentMass += currentIncrement * distanceEffect;
				currentIncrement += [self.settings hopIncrementAcceleration];
				++i;
			} while (currentIncrement > 0.0 && i < totalIncrements);
		}

		CGFloat newMass = MAX(currentMass, 0.1);
		if (newMass != animationSettings.mass) {
			animationSettings.mass = newMass;
		}
	}

	BSUIAnimationFactory *animationFactory = [%c(BSUIAnimationFactory) factoryWithSettings:[animationSettings BSAnimationSettings]];
	[animationFactory setAllowsAdditiveAnimations:YES];
	return animationFactory;
}
%end
