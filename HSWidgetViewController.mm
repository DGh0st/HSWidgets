#import "HSWidgetViewController.h"
#import <objc/runtime.h>

#define kLongPressDelay 0.08293075930093222 // I found this value btw
#define kExpandImageName @"HSExpand"
#define kShrinkImageName @"HSShrink"

@interface SBIconView // iOS 5 - 12
+(id)_jitterPositionAnimation; // iOS 5 - 10
+(id)_jitterTransformAnimation; // iOS 5 - 10
+(id)_jitterXTranslationAnimation; // iOS 12
+(id)_jitterYTranslationAnimation; // iOS 12
+(id)_jitterRotationAnimation; // iOS 12
@end

@interface SBIconController // 3 - 12
+(id)sharedInstance; // iOS 3 - 12
-(BOOL)isEditing; // iOS 3 - 12
@end

@implementation HSWidgetViewController
-(id)initForOriginRow:(NSUInteger)originRow withOptions:(NSDictionary *)options {
	self = [super init];
	if (self != nil) {
		self.originRow = originRow; // starting row of the widget
		self.requestedSize = (CGSize){0, 0}; // request size of the view
		_isEditing = NO;
		_editingView = nil;
		_closeBoxView = nil;
		_expandBoxView = nil;
		_shrinkBoxView = nil;
		_delegate = nil;
		_zoomAnimatingView = nil;
		if (options != nil)
			_options = [options mutableCopy]; // need to make copy so we can modify it
	}
	return self;
}

-(NSDictionary *)options {
	return _options;
}

-(NSUInteger)numRows {
	return 0; // number of rows the widget will take
}

+(BOOL)canAddWidgetForAvailableRows:(NSUInteger)rows {
	return NO; // should never be able to create widgets of this type
}

+(NSString *)displayName {
	return NSStringFromClass([self class]);
}

+(UIImage *)icon {
	return nil;
}

+(Class)addNewWidgetAdditionalOptionsClass {
	return nil;
}

+(NSDictionary *)createOptionsFromController:(id)controller {
	// controller will be nil if no additional options class is specified or the class wasn't used for some reason
	return nil;
}

+(NSInteger)allowedInstancesPerPage {
	return -1; // -1 = unlimited
}

-(CGRect)calculatedFrame {
	return (CGRect){{0, 0}, self.requestedSize}; // frame of the container view (used for editing view)
}

-(CGFloat)_cornerRadius {
	return 13.0f; // corner radius of the view (used for editing view)
}

-(void)setRequestedSize:(CGSize)requestedSize {
	_requestedSize = requestedSize;

	if (_editingView != nil)
		_editingView.frame = [self calculatedFrame];
}

-(void)viewDidLoad {
	[super viewDidLoad];

	CGRect frame = [self calculatedFrame];
	_editingView = [[UIView alloc] initWithFrame:frame];
	_editingView.layer.cornerRadius = [self _cornerRadius];
	[self.view addSubview:_editingView];
	_editingView.hidden = YES;

	_closeBoxView = [[objc_getClass("SBCloseBoxView") alloc] initWithFrame:CGRectZero];
	[_closeBoxView addTarget:self action:@selector(_closeBoxTapped) forControlEvents:UIControlEventTouchUpInside];
	[_closeBoxView sizeToFit];
	_closeBoxView.center = CGPointMake(_closeBoxView.frame.size.width, _closeBoxView.frame.size.height);
	[_editingView addSubview:_closeBoxView];

	_expandBoxView = [[objc_getClass("SBCloseBoxView") alloc] initWithFrame:CGRectZero];
	[_expandBoxView addTarget:self action:@selector(expandBoxTapped) forControlEvents:UIControlEventTouchUpInside];
	UIImage *expandImage = [UIImage imageNamed:kExpandImageName inBundle:[NSBundle bundleWithPath:kBundlePath] compatibleWithTraitCollection:nil];
	try {
		((UIImageView *)[_expandBoxView valueForKey:@"_xColorBurnView"]).image = expandImage;
		((UIImageView *)[_expandBoxView valueForKey:@"_xPlusDView"]).image = expandImage;
	} catch (NSException *exception) {
		_expandBoxView.imageView.image = expandImage;
	}
	[_expandBoxView sizeToFit];
	_expandBoxView.center = CGPointMake(_editingView.frame.size.width - _expandBoxView.frame.size.width, _expandBoxView.frame.size.height);
	_expandBoxView.layer.cornerRadius = [self _cornerRadius] / _expandBoxView.frame.size.width;
	[_editingView addSubview:_expandBoxView];

	_shrinkBoxView = [[objc_getClass("SBCloseBoxView") alloc] initWithFrame:CGRectZero];
	[_shrinkBoxView addTarget:self action:@selector(shrinkBoxTapped) forControlEvents:UIControlEventTouchUpInside];
	UIImage *shrinkImage = [UIImage imageNamed:kShrinkImageName inBundle:[NSBundle bundleWithPath:kBundlePath] compatibleWithTraitCollection:nil];
	try {
		((UIImageView *)[_shrinkBoxView valueForKey:@"_xColorBurnView"]).image = shrinkImage;
		((UIImageView *)[_shrinkBoxView valueForKey:@"_xPlusDView"]).image = shrinkImage;
	} catch (NSException *exception) {
		_expandBoxView.imageView.image = shrinkImage;
	}
	[_shrinkBoxView sizeToFit];
	_shrinkBoxView.center = CGPointMake(_editingView.frame.size.width - _expandBoxView.frame.size.width * 3.0 / 2.0 - _shrinkBoxView.frame.size.width, _shrinkBoxView.frame.size.height);
	_shrinkBoxView.layer.cornerRadius = [self _cornerRadius] / _shrinkBoxView.frame.size.width;
	[_editingView addSubview:_shrinkBoxView];

	UILongPressGestureRecognizer  *pan = [[UILongPressGestureRecognizer  alloc] initWithTarget:self action:@selector(_editingWidgetMoved:)];
	pan.minimumPressDuration = kLongPressDelay;
	pan.allowableMovement = INFINITY;
	[_editingView addGestureRecognizer:pan];
	[pan release];

	[self _editingStateChanged];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_editingStateChanged) name:kEditingStateChangedNotification object:nil];
}

-(void)_updateAvailableSpace:(HSWidgetAvailableSpace)space {
	_availableSpace = space;

	[self _updateAccessoryViewsAnimated:YES];
}

-(NSUInteger)availableRows {
	return _availableSpace.numRows;
}

-(NSUInteger)availableStartRow {
	return _availableSpace.startRow;
}

-(BOOL)canExpandWidget {
	return NO;
}

-(BOOL)canShrinkWidget {
	return NO;
}

-(BOOL)shouldUseCustomViewForAnimation {
	return NO;
}

-(UIView *)zoomAnimatingView {
	if (![self shouldUseCustomViewForAnimation])
		return self.view;
	if (_zoomAnimatingView == nil) {
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
	if (![self shouldUseCustomViewForAnimation])
		return; // do nothing if we are using viewcontroller's view
	if (_zoomAnimatingView != nil) {
		[_zoomAnimatingView removeFromSuperview];
		[_zoomAnimatingView release];
	}
	_zoomAnimatingView = nil;
}

-(void)_setDelegate:(id<HSWidgetDelegate>)delegate {
	_delegate = delegate;
}

-(void)_closeBoxTapped {
	if (_delegate != nil)
		[_delegate _closeTapped:self];
}

-(void)expandBoxTapped {
	// do nothing
}

-(void)shrinkBoxTapped {
	// do nothing
}

-(void)updateForExpandOrShrinkFromRows:(NSUInteger)rows {
	if (_delegate != nil)
		[_delegate _updatePageForExpandOrShrinkOfWidget:self fromRows:rows];
}

-(void)_updateAccessoryViewsAnimated:(BOOL)animated {
	if (_editingView != nil) {
		// Use _closeBoxView for sizing animations since all the buttons should have same size
		CGFloat buttonWidth = _closeBoxView.frame.size.width;
		CGFloat buttonHeight = _closeBoxView.frame.size.height;

		if ([self canExpandWidget]) {
			if (animated) {
				if (_expandBoxView.hidden) {
					_expandBoxView.alpha = 0.0;
					_expandBoxView.hidden = NO;
					_expandBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
				}
				CGPoint center = CGPointMake(_editingView.frame.size.width - buttonWidth, buttonHeight);
				[UIView animateWithDuration:kAnimationDuration animations:^{
					_expandBoxView.transform = CGAffineTransformMakeScale(1.0 , 1.0);
					_expandBoxView.alpha = 1.0;
					_expandBoxView.center = center;
				} completion:nil];
			} else {
				_expandBoxView.hidden = NO;
				_expandBoxView.center = CGPointMake(_editingView.frame.size.width - _expandBoxView.frame.size.width, _expandBoxView.frame.size.height);
			}
		} else {
			if (animated) {
				if (!_expandBoxView.hidden) {
					_expandBoxView.alpha = 1.0;
					_expandBoxView.transform = CGAffineTransformMakeScale(1.0 , 1.0);
				}
				CGPoint center = CGPointMake(_editingView.frame.size.width - _expandBoxView.frame.size.width, _expandBoxView.frame.size.height);
				[UIView animateWithDuration:kAnimationDuration animations:^{
					_expandBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
					_expandBoxView.alpha = 0.0;
					_expandBoxView.center = center;
				} completion:^(BOOL finished) {
					_expandBoxView.hidden = YES;
					_expandBoxView.alpha = 1.0;
				}];
			} else {
				_expandBoxView.hidden = YES;
				_expandBoxView.center = CGPointMake(_editingView.frame.size.width - _expandBoxView.frame.size.width, _expandBoxView.frame.size.height);
			}
		}

		if ([self canShrinkWidget]) {
			if (animated) {
				if (_shrinkBoxView.hidden) {
					_shrinkBoxView.alpha = 0.0;
					_shrinkBoxView.hidden = NO;
					_shrinkBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
				}
				CGPoint center = CGPointMake(_editingView.frame.size.width - ([self canExpandWidget] ? buttonWidth * 3.0 / 2.0 : 0.0) - buttonWidth, buttonHeight);
				[UIView animateWithDuration:kAnimationDuration animations:^{
					_shrinkBoxView.transform = CGAffineTransformMakeScale(1.0 , 1.0);
					_shrinkBoxView.alpha = 1.0;
					_shrinkBoxView.center = center;
				} completion:nil];
			} else {
				_shrinkBoxView.hidden = NO;
				_shrinkBoxView.center = CGPointMake(_editingView.frame.size.width - ([self canExpandWidget] ? _expandBoxView.frame.size.width * 3.0 / 2.0 : 0.0) - _shrinkBoxView.frame.size.width, _shrinkBoxView.frame.size.height);
			}
		} else {
			if (animated) {
				if (!_shrinkBoxView.hidden) {
					_shrinkBoxView.alpha = 1.0;
					_shrinkBoxView.transform = CGAffineTransformMakeScale(1.0 , 1.0);
				}
				CGPoint center = CGPointMake(_editingView.frame.size.width - ([self canExpandWidget] ? _expandBoxView.frame.size.width * 3.0 / 2.0 : 0.0) - _shrinkBoxView.frame.size.width, _shrinkBoxView.frame.size.height);
				[UIView animateWithDuration:kAnimationDuration animations:^{
					_shrinkBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
					_shrinkBoxView.alpha = 0.0;
					_shrinkBoxView.center = center;
				} completion:^(BOOL finished) {
					_shrinkBoxView.hidden = YES;
					_shrinkBoxView.alpha = 1.0;
				}];
			} else {
				_shrinkBoxView.hidden = YES;
				_shrinkBoxView.center = CGPointMake(_editingView.frame.size.width - ([self canExpandWidget] ? _expandBoxView.frame.size.width * 3.0 / 2.0 : 0.0) - _shrinkBoxView.frame.size.width, _shrinkBoxView.frame.size.height);
			}
		}
	}
}

-(void)_editingWidgetMoved:(UILongPressGestureRecognizer *)sender {
	if (_delegate != nil && [_delegate _canDragWidget:self]) {
		if (sender.state == UIGestureRecognizerStateBegan) {
			[self _removeEditingAnimations];
			[_delegate _setDraggingWidget:self];
			_editingWidgetTranslationPoint = [sender locationInView:sender.view.superview]; // translate to self.view
		} else if (sender.state == UIGestureRecognizerStateChanged) {
			CGPoint translatedPoint = [sender locationInView:sender.view.superview.superview]; // translate to icon list view
			translatedPoint.x -= _editingWidgetTranslationPoint.x;
			translatedPoint.y -= _editingWidgetTranslationPoint.y;
			[_delegate _widgetDraggedToPoint:translatedPoint];
		} else if (sender.state == UIGestureRecognizerStateEnded || UIGestureRecognizerStateCancelled || UIGestureRecognizerStateFailed) {
			[self _insertEditingAnimations];
			[_delegate _setDraggingWidget:nil];
		}
	}
}

-(void)_editingStateChanged {
	BOOL isEditing = [[objc_getClass("SBIconController") sharedInstance] isEditing];
	if (isEditing != _isEditing) {
		_isEditing = isEditing;
		if (isEditing) {
			[self _updateAccessoryViewsAnimated:NO];
			[self _insertEditingAnimations];

			if (_editingView != nil && _editingView.hidden && _closeBoxView != nil) {
				_editingView.frame = [self calculatedFrame];
				[self.view bringSubviewToFront:_editingView];

				_editingView.hidden = NO;
				_closeBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
				if (_expandBoxView != nil)
					_expandBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
				if (_shrinkBoxView != nil)
					_shrinkBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
				_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
				[UIView animateWithDuration:kAnimationDuration animations:^{
					_closeBoxView.transform = CGAffineTransformMakeScale(1, 1);
					if (_expandBoxView != nil)
						_expandBoxView.transform = CGAffineTransformMakeScale(1, 1);
					if (_shrinkBoxView != nil)
						_shrinkBoxView.transform = CGAffineTransformMakeScale(1, 1);
					_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
				} completion:^(BOOL finished) {
					_closeBoxView.transform = CGAffineTransformMakeScale(1, 1);
					if (_expandBoxView != nil)
						_expandBoxView.transform = CGAffineTransformMakeScale(1, 1);
					if (_shrinkBoxView != nil)
						_shrinkBoxView.transform = CGAffineTransformMakeScale(1, 1);
					_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
				}];
			}
		} else {
			[self _removeEditingAnimations];

			if (_editingView != nil && !_editingView.hidden && _closeBoxView != nil) {
				_closeBoxView.transform = CGAffineTransformMakeScale(1, 1);
				if (_expandBoxView != nil)
					_expandBoxView.transform = CGAffineTransformMakeScale(1, 1);
				if (_shrinkBoxView != nil)
					_shrinkBoxView.transform = CGAffineTransformMakeScale(1, 1);
				_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
				[UIView animateWithDuration:kAnimationDuration animations:^{
					_closeBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
					if (_expandBoxView != nil)
						_expandBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
					if (_shrinkBoxView != nil)
						_shrinkBoxView.transform = CGAffineTransformMakeScale(0.1, 0.1);
					_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
				} completion:^(BOOL finished) {
					_editingView.hidden = YES;
					_closeBoxView.transform = CGAffineTransformMakeScale(1, 1);
					if (_expandBoxView != nil)
						_expandBoxView.transform = CGAffineTransformMakeScale(1, 1);
					if (_shrinkBoxView != nil)
						_shrinkBoxView.transform = CGAffineTransformMakeScale(1, 1);
					_editingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
				}];
			}
		}
	}
}

-(void)_insertEditingAnimations {
	// translation/position
	if ([objc_getClass("SBIconView") respondsToSelector:@selector(_jitterPositionAnimation)])
		[self.view.layer addAnimation:[objc_getClass("SBIconView") _jitterPositionAnimation] forKey:@"HSWidgetPosition"];
	if ([objc_getClass("SBIconView") respondsToSelector:@selector(_jitterXTranslationAnimation)])
		[self.view.layer addAnimation:[objc_getClass("SBIconView") _jitterXTranslationAnimation] forKey:@"HSWidgetPositionX"];
	if ([objc_getClass("SBIconView") respondsToSelector:@selector(_jitterYTranslationAnimation)])
		[self.view.layer addAnimation:[objc_getClass("SBIconView") _jitterYTranslationAnimation] forKey:@"HSWidgetPositionY"];

	// rotation/transformation
	if ([objc_getClass("SBIconView") respondsToSelector:@selector(_jitterTransformAnimation)])
		[self.view.layer addAnimation:[objc_getClass("SBIconView") _jitterTransformAnimation] forKey:@"HSWidgetTransform"];
	if ([objc_getClass("SBIconView") respondsToSelector:@selector(_jitterRotationAnimation)])
		[self.view.layer addAnimation:[objc_getClass("SBIconView") _jitterRotationAnimation] forKey:@"HSWidgetRotation"];
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

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kEditingStateChangedNotification object:nil];

	if (_editingView != nil) {
		[_editingView removeFromSuperview];
		[_editingView release];
		_editingView = nil;
	}

	if (_closeBoxView != nil) {
		[_closeBoxView removeFromSuperview];
		[_closeBoxView release];
		_closeBoxView = nil;
	}

	if (_expandBoxView != nil) {
		[_expandBoxView removeFromSuperview];
		[_expandBoxView release];
		_expandBoxView = nil;
	}

	if (_shrinkBoxView != nil) {
		[_shrinkBoxView removeFromSuperview];
		[_shrinkBoxView release];
		_shrinkBoxView = nil;
	}

	if (_zoomAnimatingView != nil) {
		[_zoomAnimatingView removeFromSuperview];
		[_zoomAnimatingView release];
		_zoomAnimatingView = nil;
	}

	_delegate = nil;

	if (_options != nil) {
		[_options release];
		_options = nil;
	}

	[super dealloc];
}
@end
