#import "HSWidgetPositionObject.h"

@interface HSWidgetAvailablePositionObject : HSWidgetPositionObject <NSCopying>
@property (nonatomic, assign) BOOL containsIcon;
+(instancetype)objectWithAvailableWidgetPosition:(HSWidgetPosition)position containingIcon:(BOOL)containsIcon;
-(instancetype)initWithAvailableWidgetPosition:(HSWidgetPosition)position containingIcon:(BOOL)containsIcon;
@end
