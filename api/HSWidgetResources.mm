#import "HSWidgetResources.h"
#import "NSUserDefaults.h"

NSString *const HSWidgetDomain = @"com.dgh0st.hswidgets";

NSString *const HSWidgetExpandImageName = @"HSExpand";
NSString *const HSWidgetShrinkImageName = @"HSShrink";
NSString *const HSWidgetSettingsImageName = @"HSSettings";
NSString *const HSWidgetPlaceholderImageName = @"HSPlaceholder";
NSString *const HSWidgetPlaceholderShapeImageName = @"HSPlaceholderShape";

NSString *const HSWidgetBezierShapeChangedNotification = @"HSWidgetBezierShapeChangedNotification";
NSString *const HSWidgetBezierShapeKey = @"BezierShapeKey";
NSString *const HSWidgetBezierShapeEnumKey = @"ShapeEnumKey";
NSString *const HSWidgetBezierShapeDisplayNameKey = @"DisplayNameKey";

#define BUNDLE_PATH @"/Library/Application Support/HSWidgets/Assets.bundle"

@interface UIImage (iOS13)
+(UIImage *)systemImageNamed:(NSString *)name;
@end

@implementation HSWidgetResources
+(UIImage *)imageNamed:(NSString *)name {
	UIImage *result = nil;

	if ([name isEqualToString:HSWidgetPlaceholderImageName]) {
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(29, 29), NO, 0.0);

		UIBezierPath *path = [self bezierPathForRect:CGRectMake(0, 0, 29, 29) withShape:HSWidgetBezierShapeRoundedRect lineThickness:2.0];
		CGFloat dashedLines[2] = {6.25, 2.083};
		[path setLineDash:dashedLines count:2 phase:0.0];
		[[[UIColor darkGrayColor] colorWithAlphaComponent:0.5] setStroke];
		[path stroke];

		result = UIGraphicsGetImageFromCurrentImageContext();

		UIGraphicsEndImageContext();
	} else if ([UIImage respondsToSelector:@selector(systemImageNamed:)]) {
		// try get the system icon
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
		if ([name isEqualToString:HSWidgetExpandImageName]) {
			result = [UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"];
		} else if ([name isEqualToString:HSWidgetShrinkImageName]) {
			result = [UIImage systemImageNamed:@"arrow.down.right.and.arrow.up.left"];
		} else if ([name isEqualToString:HSWidgetSettingsImageName]) {
			result = [UIImage systemImageNamed:@"gear"];
		} else {
			result = [UIImage systemImageNamed:name];
		}
#pragma clang diagnostic pop
	}

	// system icon doesn't exist, not available
	if (result == nil) {
		result = [UIImage imageNamed:name inBundle:[NSBundle bundleWithPath:BUNDLE_PATH] compatibleWithTraitCollection:nil];
	}

	return [result imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

+(NSArray *)allBezierShapes {
	return @[
		@{
			HSWidgetBezierShapeEnumKey : @(HSWidgetBezierShapeRoundedRect),
			HSWidgetBezierShapeDisplayNameKey : @"Rounded Rectangle (Default)"
		},
		@{ 
			HSWidgetBezierShapeEnumKey : @(HSWidgetBezierShapeRect),
			HSWidgetBezierShapeDisplayNameKey : @"Rectangle"
		},
		@{
			HSWidgetBezierShapeEnumKey : @(HSWidgetBezierShapeCircle),
			HSWidgetBezierShapeDisplayNameKey : @"Circle"
		},
		@{
			HSWidgetBezierShapeEnumKey : @(HSWidgetBezierShapeTriangle),
			HSWidgetBezierShapeDisplayNameKey : @"Triangle"
		},
		@{
			HSWidgetBezierShapeEnumKey : @(HSWidgetBezierShapeStar),
			HSWidgetBezierShapeDisplayNameKey : @"Star"
		}
	];
}

+(UIBezierPath *)bezierPathForRect:(CGRect)rect withShape:(HSWidgetBezierShape)shape lineThickness:(CGFloat)thickness {
	UIBezierPath *path = nil;
	if (shape == HSWidgetBezierShapeDefault) {
		NSNumber *bezierShapeSelected = [[NSUserDefaults standardUserDefaults] objectForKey:HSWidgetBezierShapeKey inDomain:HSWidgetDomain];
		shape = bezierShapeSelected ? (HSWidgetBezierShape)[bezierShapeSelected unsignedIntegerValue] : HSWidgetBezierShapeRoundedRect;
	}

	if (shape == HSWidgetBezierShapeCustom) {
		// TODO: Load from file
	} else if (shape == HSWidgetBezierShapeRoundedRect) {
		CGRect roundedRect = CGRectMake(rect.origin.x + thickness / 2, rect.origin.y + thickness / 2, rect.origin.x + rect.size.width - thickness, rect.origin.y + rect.size.height - thickness);
		path = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:MAX(rect.size.width, rect.size.height) / 4];
	} else if (shape == HSWidgetBezierShapeRect) {
		CGRect straightRect = CGRectMake(rect.origin.x + thickness / 2, rect.origin.y + thickness / 2, rect.origin.x + rect.size.width - thickness, rect.origin.y + rect.size.height - thickness);
		path = [UIBezierPath bezierPathWithRect:straightRect];
	} else if (shape == HSWidgetBezierShapeCircle) {
		CGRect roundedOval = CGRectMake(rect.origin.x + thickness / 2, rect.origin.y + thickness / 2, rect.origin.x + rect.size.width - thickness, rect.origin.y + rect.size.height - thickness);
		path = [UIBezierPath bezierPathWithOvalInRect:roundedOval];
	} else if (shape == HSWidgetBezierShapeTriangle) {
		path = [UIBezierPath bezierPath];
		[path moveToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + thickness / 2)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width - thickness / 2, rect.origin.y + rect.size.height - thickness / 2)];
		[path addLineToPoint:CGPointMake(rect.origin.x + thickness / 2, rect.origin.y + rect.size.height - thickness / 2)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + thickness / 2)];
	} else if (shape == HSWidgetBezierShapeStar) {
		path = [UIBezierPath bezierPath];
		[path moveToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + thickness / 2)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width / 3, rect.origin.y + rect.size.height / 3)];
		[path addLineToPoint:CGPointMake(rect.origin.x + thickness / 2, rect.origin.y + rect.size.height * 2 / 5)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width / 4, rect.origin.y + rect.size.height * 3 / 5)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width / 5, rect.origin.y + rect.size.height - thickness / 2)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height * 4 / 5)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width * 4 / 5, rect.origin.y + rect.size.height - thickness / 2)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width * 3 / 4, rect.origin.y + rect.size.height * 3 / 5)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width - thickness / 2, rect.origin.y + rect.size.height * 2 / 5)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width * 2 / 3, rect.origin.y + rect.size.height / 3)];
		[path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + thickness / 2)];
	}
	return path;
}
@end
