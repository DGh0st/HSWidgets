#import "HSAddNewWidgetView.h"
#import "HSWidgetViewController.h"

@interface HSAddNewWidgetView ()
@property (nonatomic, retain) NSMutableArray<HSAddNewWidgetPositionView *> *_addNewPositionViews;
@end

@implementation HSAddNewWidgetView
-(instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self != nil) {
		_delegate = nil;
		self._addNewPositionViews = nil;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

-(void)updateAvailableSpaces:(NSArray<HSWidgetPositionObject *> *)availableSpaces withAnimationDuration:(CGFloat)animationDuration {
	NSMutableArray<HSWidgetPositionObject *> *newAvailableSpaces = [NSMutableArray arrayWithArray:availableSpaces];
	NSMutableArray<HSAddNewWidgetPositionView *> *addNewPositionViews = [NSMutableArray arrayWithCapacity:availableSpaces.count];
	for (HSAddNewWidgetPositionView *view in self._addNewPositionViews) {
		NSUInteger newAvailableSpacesIndex = [newAvailableSpaces indexOfObject:view.position];
		if (newAvailableSpacesIndex != NSNotFound) {
			// position still available
			[newAvailableSpaces removeObjectAtIndex:newAvailableSpacesIndex];
			[addNewPositionViews addObject:view];
		} else {
			// remove views for positions that are not available anymore
			[UIView animateWithDuration:animationDuration animations:^{
				view.transform = CGAffineTransformMakeScale(0.01, 0.01);
			} completion:^(BOOL finished) {
				if (finished) {
					[view removeFromSuperview];
				}
			}];
		}
	}

	// new positions added so create and add them
	for (HSWidgetPositionObject *position in newAvailableSpaces) {
		HSAddNewWidgetPositionView *newWidgetPositionView = [[HSAddNewWidgetPositionView alloc] initWithWidgetPosition:position];
		newWidgetPositionView.frame = [_delegate rectForWidgetPosition:position.position];
		[newWidgetPositionView setDelegate:self];
		[self addSubview:newWidgetPositionView];
		[addNewPositionViews addObject:newWidgetPositionView];

		newWidgetPositionView.transform = CGAffineTransformMakeScale(0.01, 0.01);
		// fix animation issues
		[newWidgetPositionView.layer removeAllAnimations];
		[UIView animateWithDuration:animationDuration animations:^{
			newWidgetPositionView.transform = CGAffineTransformMakeScale(1.0, 1.0);
		} completion:nil];

		[newWidgetPositionView release];
	}

	self._addNewPositionViews = addNewPositionViews.count > 0 ? addNewPositionViews : nil;
}

-(void)setDelegate:(id<HSAddNewWidgetDelegate>)delegate {
	_delegate = delegate;
}

-(void)addNewWidgetPositionViewTapped:(HSAddNewWidgetPositionView *)view {
	[_delegate addNewWidgetTappedForPosition:view.position.position];
}

-(void)layoutSubviews {
	[super layoutSubviews];

	for (HSAddNewWidgetPositionView *view in self._addNewPositionViews) {
		view.frame = [_delegate rectForWidgetPosition:view.position.position];
	}
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	for (UIView *subview in [[self subviews] reverseObjectEnumerator]) {
		if (subview.hidden || subview.alpha == 0 || !subview.userInteractionEnabled) {
			continue;
		}

		CGPoint convertedPoint = [self convertPoint:point toView:subview];
		if ([subview isKindOfClass:[HSWidgetUnclippedView class]]) {
			UIView *subviewHitTest = [subview hitTest:convertedPoint withEvent:event];
			if (subviewHitTest != nil) {
				return subviewHitTest;
			}
		} else if (CGRectContainsPoint(subview.bounds, convertedPoint)) {
			return subview;
		}
	}
	return [super hitTest:point withEvent:event];
}

-(void)dealloc {
	_delegate = nil;
	self._addNewPositionViews = nil;

	[super dealloc];
}
@end