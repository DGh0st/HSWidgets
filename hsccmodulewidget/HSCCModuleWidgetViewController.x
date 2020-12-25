#import "HSCCModuleWidgetViewController.h"
#import "HSCCModuleController.h"
#import "HSCCNotifications.h"
#import "CCSModuleMetadata.h"
#import "CCUIContentModule.h"
#import "CCUIContentModuleContext.h"
#import "CCUIContentModuleBackgroundView.h"
#import "CCUIContentModuleContainerView.h"
#import "CCUIContentModuleContainerViewController.h"
#import "CCUIContentModulePresentationContext.h"
#import "CCUILayoutOptions.h"
#import "CCUILayoutSize.h"
#import "CCUIModuleInstance.h"
#import "CCUIModuleSettings.h"
#import "SBIconController.h"
#import "UIViewController+bs.h"
#import "UIViewController+ccui.h"

#define MIN_NUM_ROWS 1U
#define MIN_NUM_COLS 1U

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

static inline void ForceLayoutViews(NSArray *views) {
	for (UIView *view in views) {
		[view setNeedsLayout];
		[view layoutIfNeeded];
	}
}

@implementation HSCCModuleWidgetViewController {
	BOOL _isInteractingWithModule;
}

-(instancetype)initForWidgetFrame:(HSWidgetFrame)frame withOptions:(NSDictionary *)options {
	self = [super initForWidgetFrame:frame withOptions:options];
	if (self != nil) {
		_moduleIdentifier = options[@"moduleIdentifier"];
		_isInteractingWithModule = NO;

		self.cornerRadius = ceil([HSCCModuleController sharedInstance].layoutOptions.itemEdgeSize / 4.0);
	}
	return self;
}

+(HSWidgetSize)minimumSize {
	return HSWidgetSizeMake(MIN_NUM_ROWS, MIN_NUM_COLS); // least amount of rows and cols the widget needs
}

+(BOOL)isAvailable {
	// TODO: Fix for pre-iOS 13 to remove this check
	NSOperatingSystemVersion version;
	version.majorVersion = 13;
	version.minorVersion = 0;
	version.patchVersion = 0;
	return %c(CCUIContentModuleContainerViewController) != nil && [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version];
}

-(void)loadView {
	[super loadView];

	if (self.moduleIdentifier != nil) {
		HSCCModuleController *moduleController = [HSCCModuleController sharedInstance];
		CCUIModuleInstance *moduleInstance = [moduleController moduleInstanceForIdentifier:self.moduleIdentifier];
		if ([moduleInstance.module respondsToSelector:@selector(setContentModuleContext:)]) {
			CCUIContentModuleContext *moduleContext = [[%c(CCUIContentModuleContext) alloc] initWithModuleIdentifier:self.moduleIdentifier];
			moduleContext.delegate = self;
			[moduleInstance.module setContentModuleContext:moduleContext];
			[moduleContext release];
		}

		if ([%c(CCUIContentModuleContainerViewController) instancesRespondToSelector:@selector(initWithModuleIdentifier:contentModule:presentationContext:)]) {
			self.moduleContainerViewController = [[%c(CCUIContentModuleContainerViewController) alloc] initWithModuleIdentifier:self.moduleIdentifier contentModule:moduleInstance.module presentationContext:[%c(CCUIContentModulePresentationContext) defaultControlCenterPresentationContext]];
		} else if ([%c(CCUIContentModuleContainerViewController) instancesRespondToSelector:@selector(initWithModuleIdentifier:contentModule:)]) {
			self.moduleContainerViewController = [[%c(CCUIContentModuleContainerViewController) alloc] initWithModuleIdentifier:self.moduleIdentifier contentModule:moduleInstance.module];
		}

		self.moduleSettings = [moduleController moduleSettingForIdentifier:self.moduleIdentifier];

		if ([self.moduleContainerViewController respondsToSelector:@selector(setMaterialGroupName:)]) {
			[self.moduleContainerViewController setMaterialGroupName:@"CCUIContentModuleContainerViewControllerGroupName"];
		}

		self.moduleContainerViewController.delegate = self;
		[self addChildViewController:self.moduleContainerViewController];
		[self.moduleContainerViewController didMoveToParentViewController:self];

		self.moduleContainerView = [[%c(CCUIContentModuleContainerView) alloc] initWithModuleIdentifier:self.moduleIdentifier options:3];
		self.moduleContainerView.frame = [self calculatedFrame];
		[self.moduleContainerView.containerView addSubview:self.moduleContainerViewController.view];
		[self.view addSubview:self.moduleContainerView];

		if ([self.moduleContainerViewController respondsToSelector:@selector(displayWillTurnOff)])
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_displayDidTurnoff) name:HSCCDisplayTurnOffNotification object:nil];

		ForceLayoutViews(@[self.view, self.moduleContainerViewController.view, self.moduleContainerViewController.contentView]);
	}
}

-(CGRect)calculatedFrame {
	CCUILayoutOptions *layoutOptions = [HSCCModuleController sharedInstance].layoutOptions;
	CCUILayoutSize layoutSize = [self.moduleSettings layoutSizeForInterfaceOrientation:[(SBIconController *)[%c(SBIconController) sharedInstance] orientation]];
	CGFloat width = MAX(layoutOptions.itemEdgeSize * layoutSize.width + layoutOptions.itemSpacing * (layoutSize.width - 1), 0);
	CGFloat height = MAX(layoutOptions.itemEdgeSize * layoutSize.height + layoutOptions.itemSpacing * (layoutSize.height - 1), 0);
	CGFloat originX = (self.requestedSize.width - width) / 2;
	CGFloat originY = (self.requestedSize.height - height) / 2;
	if (layoutSize.height == 1) {
		originY = MIN(originY, 0);
	}
	return CGRectMake(originX, originY, width, height);
}

-(void)setRequestedSize:(CGSize)requestedSize {
	[super setRequestedSize:requestedSize];

	if (self.moduleContainerView != nil) {
		self.moduleContainerView.frame = [self calculatedFrame];
	}
}

-(BOOL)shouldAutomaticallyForwardAppearanceMethods {
	return NO;
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	ForceLayoutViews(@[self.view, self.moduleContainerViewController.view, self.moduleContainerViewController.contentView]);
	[self.moduleContainerViewController ccui_safelyBeginAppearanceTransition:YES animated:animated];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	ForceLayoutViews(@[self.view, self.moduleContainerViewController.view, self.moduleContainerViewController.contentView]);
	[self.moduleContainerViewController willBecomeActive];
	[self.moduleContainerViewController ccui_safelyBeginAppearanceTransition:YES animated:animated];
	[self.moduleContainerViewController ccui_safelyEndAppearanceTransition];
}

-(void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self.moduleContainerViewController willResignActive];
	if (self.moduleContainerViewController.expanded)
		[self.moduleContainerViewController dismissPresentedContentAnimated:YES];

	[self.moduleContainerViewController ccui_safelyBeginAppearanceTransition:NO animated:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	[self.moduleContainerViewController ccui_safelyBeginAppearanceTransition:NO animated:animated];
	[self.moduleContainerViewController ccui_safelyEndAppearanceTransition];
}

-(void)_displayDidTurnoff {
	if ([self.moduleContainerViewController respondsToSelector:@selector(displayWillTurnOff)])
		[self.moduleContainerViewController displayWillTurnOff];
}

-(CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
	return self.moduleContainerView.frame.size;
}

-(CGRect)compactModeFrameForContentModuleContainerViewController:(CCUIContentModuleContainerViewController *)moduleContainerViewController {
	if (_isInteractingWithModule)
		return [self.moduleContainerView.superview convertRect:self.moduleContainerView.frame toView:((SBIconController *)[%c(SBIconController) sharedInstance]).view];
	return [self.moduleContainerView.superview convertRect:self.moduleContainerView.frame toView:[moduleContainerViewController bs_presentationContextDefiningViewController].view];
}

-(BOOL)contentModuleContainerViewController:(id)moduleContainerViewController canBeginInteractionWithModule:(id)module {
	return !_isInteractingWithModule;
}

-(void)contentModuleContainerViewController:(CCUIContentModuleContainerViewController *)moduleContainerViewController didBeginInteractionWithModule:(id)module {
	_isInteractingWithModule = YES;
	self.moduleContainerView.ignoreFrameUpdates = YES;
	moduleContainerViewController.backgroundView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.67];
}

-(void)contentModuleContainerViewController:(CCUIContentModuleContainerViewController *)moduleContainerViewController didFinishInteractionWithModule:(id)module {
	_isInteractingWithModule = NO;
	self.moduleContainerView.ignoreFrameUpdates = NO;
	moduleContainerViewController.backgroundView.backgroundColor = nil;
}

-(void)contentModuleContainerViewController:(CCUIContentModuleContainerViewController *)moduleContainerViewController willOpenExpandedModule:(id)module {
	[moduleContainerViewController ccui_safelyBeginAppearanceTransition:YES animated:NO];
	[moduleContainerViewController ccui_safelyEndAppearanceTransition];

	SetFloatingDockHidden(YES);

	[HSCCModuleController sharedInstance].expandedModuleViewController = self;
}

-(void)contentModuleContainerViewController:(id)moduleContainerViewController didOpenExpandedModule:(id)module {
	// do nothing
}

-(void)contentModuleContainerViewController:(CCUIContentModuleContainerViewController *)moduleContainerViewController willCloseExpandedModule:(id)module {
	[moduleContainerViewController ccui_safelyBeginAppearanceTransition:NO animated:NO];
	[moduleContainerViewController ccui_safelyEndAppearanceTransition];

	SetFloatingDockHidden(NO);

	[HSCCModuleController sharedInstance].expandedModuleViewController = nil;
}

-(void)contentModuleContainerViewController:(id)moduleContainerViewController didCloseExpandedModule:(id)module {
	// do nothing
}

-(BOOL)shouldApplyBackgroundEffectsForContentModuleContainerViewController:(id)moduleContainerViewController {
	return NO;
}

-(id)backgroundViewForContentModuleContainerViewController:(CCUIContentModuleContainerViewController *)moduleContainerViewController {
	return moduleContainerViewController.backgroundView; // TODO
}

-(void)contentModuleContainerViewController:(CCUIContentModuleContainerViewController *)moduleContainerViewController willPresentViewController:(id)viewController {
	[moduleContainerViewController ccui_safelyBeginAppearanceTransition:YES animated:YES];
	[moduleContainerViewController ccui_safelyEndAppearanceTransition];
}

-(void)contentModuleContainerViewController:(CCUIContentModuleContainerViewController *)moduleContainerViewController willDismissViewController:(id)viewController {
	[moduleContainerViewController ccui_safelyBeginAppearanceTransition:NO animated:YES];
	[moduleContainerViewController ccui_safelyEndAppearanceTransition];
}

-(void)contentModuleContainerViewControllerDismissPresentedContent:(CCUIContentModuleContainerViewController *)presentedContent {
	[presentedContent dismissPresentedContentAnimated:YES];
}

-(void)contentModuleContext:(id)context enqueueStatusUpdate:(id)status {
	// do nothing
}

-(void)requestExpandModuleForContentModuleContext:(id)context {
	if (!self.moduleContainerViewController.expanded && [HSCCModuleController sharedInstance].expandedModuleViewController == nil)
		[self.moduleContainerViewController expandModule];
}

-(void)dismissExpandedViewForContentModuleContext:(id)context {
	if (self.moduleContainerViewController.expanded)
		[self.moduleContainerViewController dismissPresentedContentAnimated:YES];
}

-(void)dismissExpandedModule {
	if (self.moduleContainerViewController.expanded)
		[self.moduleContainerViewController dismissPresentedContentAnimated:YES];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:HSCCDisplayTurnOffNotification object:nil];

	[self.moduleContainerViewController willMoveToParentViewController:nil];
	[self.moduleContainerViewController.view removeFromSuperview];
	[self.moduleContainerViewController removeFromParentViewController];
	[self.moduleContainerViewController release];
	self.moduleContainerViewController = nil;

	[self.moduleContainerView removeFromSuperview];
	[self.moduleContainerView release];
	self.moduleContainerView = nil;

	self.moduleSettings = nil;

	[[HSCCModuleController sharedInstance] removeModuleInstanceForIdentifier:self.moduleIdentifier];

	[super dealloc];
}
@end
