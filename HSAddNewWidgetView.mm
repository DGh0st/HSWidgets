#import "HSAddNewWidgetView.h"

@implementation HSAddNewWidgetView
-(id)initWithFrame:(CGRect)frame withAvailableSpace:(HSWidgetAvailableSpace)availableSpace {
	self = [super initWithFrame:frame];
	if (self != nil) {
		_availableSpace = availableSpace;
		@autoreleasepool {
			self.backgroundColor = [UIColor clearColor];
			self.fillColor = [UIColor clearColor];
		}
	}
	return self;
}

-(void)setAddNewWidgetDelegate:(id<HSAddNewWidgetDelegate>)addNewWidgetDelegate {
	_addNewWidgetDelegate = addNewWidgetDelegate;
}

-(void)setAvailableSpace:(HSWidgetAvailableSpace)availableSpace {
	_availableSpace = availableSpace;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.isTouchDown = YES;
    @autoreleasepool {
    	self.fillColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25];
    }
	[self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(id)event {
	if (self.isTouchDown) {
		@autoreleasepool {
			if (![self pointInside:[[touches anyObject] locationInView: self] withEvent:event])
				self.fillColor = [UIColor clearColor];
			else
				self.fillColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25];
		}
		[self setNeedsDisplay];
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isTouchDown) {
    	@autoreleasepool {
        	self.fillColor = [UIColor clearColor];
        }
		[self setNeedsDisplay];
        self.isTouchDown = NO;

        if ([self pointInside:[[touches anyObject] locationInView: self] withEvent:event])
        	[_addNewWidgetDelegate _addNewWidgetTappedWithAvailableSpace:_availableSpace];
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isTouchDown) {
    	@autoreleasepool {
	        self.fillColor = [UIColor clearColor];
	    }
		[self setNeedsDisplay];
        self.isTouchDown = NO;
    }
}

-(void)drawRect:(CGRect)arg1 {
	@autoreleasepool {
		if (arg1.size.height > 0) {
			CGRect roundedRectFrame = CGRectMake(arg1.origin.x + 3, arg1.origin.y + 3, arg1.size.width - 6, arg1.size.height - 6);
			UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:roundedRectFrame cornerRadius:15.0];
			[self.fillColor setFill];
			[borderPath fill];
			borderPath.lineWidth = 3;
			CGFloat dashedLine[2] = {15.0, 5.0};
			[borderPath setLineDash:dashedLine count:2 phase:0.0];
			[[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] setStroke];
			[borderPath stroke];

			UIBezierPath *plusPath = [UIBezierPath bezierPath];
			plusPath.lineWidth = 3;
			[plusPath moveToPoint:CGPointMake(arg1.size.width / 2 - 15, arg1.size.height / 2)];
			[plusPath addLineToPoint:CGPointMake(arg1.size.width / 2 + 15, arg1.size.height / 2)];
			[plusPath moveToPoint:CGPointMake(arg1.size.width / 2, arg1.size.height / 2 - 15)];
			[plusPath addLineToPoint:CGPointMake(arg1.size.width / 2, arg1.size.height / 2 + 15)];
			[[UIColor whiteColor] setStroke];
			[plusPath stroke];
		}
	}
}
@end