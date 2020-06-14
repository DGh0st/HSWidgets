#import "HSWidgetUnclippedView.h"

@implementation HSWidgetUnclippedView
-(instancetype)init {
	self = [super init];
	self.clipsToBounds = NO;
	return self;
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	// override the hit test only if the point is outside the view's bounds (unclip the bounds for event)
	if (!CGRectContainsPoint(self.bounds, point)) {
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
	}
	return [super hitTest:point withEvent:event];
}
@end