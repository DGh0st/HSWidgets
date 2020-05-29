NS_ASSUME_NONNULL_BEGIN

extern NSString *const HSWidgetDomain;

extern NSString *const HSWidgetExpandImageName;
extern NSString *const HSWidgetShrinkImageName;
extern NSString *const HSWidgetSettingsImageName;
extern NSString *const HSWidgetPlaceholderImageName;
extern NSString *const HSWidgetPlaceholderShapeImageName;

extern NSString *const HSWidgetBezierShapeChangedNotification;
extern NSString *const HSWidgetBezierShapeKey;
extern NSString *const HSWidgetBezierShapeEnumKey;
extern NSString *const HSWidgetBezierShapeDisplayNameKey;

typedef NS_ENUM(NSUInteger, HSWidgetBezierShape) {
	HSWidgetBezierShapeDefault = 0,
	HSWidgetBezierShapeCustom,
	HSWidgetBezierShapeRoundedRect,
	HSWidgetBezierShapeRect,
	HSWidgetBezierShapeCircle,
	HSWidgetBezierShapeTriangle,
	HSWidgetBezierShapeStar
};

@interface HSWidgetResources : NSObject
+(nullable UIImage *)imageNamed:(NSString *)name;
+(NSArray *)allBezierShapes;
+(nullable UIBezierPath *)bezierPathForRect:(CGRect)rect withShape:(HSWidgetBezierShape)shape lineThickness:(CGFloat)thickness;
@end

NS_ASSUME_NONNULL_END
