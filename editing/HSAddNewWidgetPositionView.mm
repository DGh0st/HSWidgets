#import "HSAddNewWidgetPositionView.h"

@interface HSAddNewWidgetPositionView ()
@property (nonatomic, assign) BOOL _isTouchDown;
@property (nonatomic, assign) BOOL _isTouchInside;
@end

@implementation HSAddNewWidgetPositionView
-(instancetype)initWithWidgetPosition:(HSWidgetPositionObject *)position {
	self = [self init];
	if (self != nil) {
		_delegate = nil;
		self._isTouchDown = NO;
		self._isTouchInside = NO;
		self.position = position;
		self.backgroundColor = [UIColor clearColor];
		self.tintColor = [UIColor whiteColor];
		self.bezierShape = HSWidgetBezierShapeDefault;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_bezierShapeChanged) name:HSWidgetBezierShapeChangedNotification object:nil];
	}
	return self;
}

-(void)_bezierShapeChanged {
	// foce widget relayout
	[self setNeedsDisplay];
}

-(void)setDelegate:(id<HSAddNewWidgetPositionViewDelegate>)delegate {
	_delegate = delegate;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	self._isTouchDown = YES;
	self._isTouchInside = YES;
	[self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(id)event {
	if (self._isTouchDown) {
		CGPoint point = [[touches anyObject] locationInView:self];
		self._isTouchInside = [self pointInside:point withEvent:event];
		[self setNeedsDisplay];
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self._isTouchDown) {
		self._isTouchInside = NO;

		CGPoint point = [[touches anyObject] locationInView:self];
		if ([self pointInside:point withEvent:event]) {
			[_delegate addNewWidgetPositionViewTapped:self];
		}

		[self setNeedsDisplay];
	}
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	if (self._isTouchDown) {
		self._isTouchDown = NO;
		self._isTouchInside = NO;
		[self setNeedsDisplay];
	}
}

-(void)drawRect:(CGRect)arg1 {
	if (arg1.size.width > 0 && arg1.size.height > 0) {
		@autoreleasepool {
			CGFloat lineWidth = 2.0;
			UIBezierPath *borderPath = [HSWidgetResources bezierPathForRect:self.bounds withShape:self.bezierShape lineThickness:lineWidth];
			if (self._isTouchInside) {
				[[self.tintColor colorWithAlphaComponent:0.25] setFill];
			} else {
				[[UIColor clearColor] setFill];
			}
			[borderPath fill];

			borderPath.lineWidth = lineWidth;
			CGFloat dashedLines[2] = {15.0, 5.0};
			[borderPath setLineDash:dashedLines count:2 phase:0.0];
			[[self.tintColor colorWithAlphaComponent:0.5] setStroke];
			[borderPath stroke];
		}
	}
}

-(void)dealloc {
	_delegate = nil;
	self.position = nil;

	[super dealloc];
}
@end