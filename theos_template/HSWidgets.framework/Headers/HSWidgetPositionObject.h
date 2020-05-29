#import "HSWidgets-structs.h"

@interface HSWidgetPositionObject : NSObject <NSCopying>
@property (nonatomic, assign) HSWidgetPosition position;
@property (nonatomic, assign, getter=row, setter=setRow:) NSUInteger row;
@property (nonatomic, assign, getter=col, setter=setCol:) NSUInteger col;
+(instancetype)objectWithWidgetPosition:(HSWidgetPosition)position;
-(instancetype)initWithWidgetPosition:(HSWidgetPosition)position;
-(BOOL)isEqualToWidgetPositionObject:(HSWidgetPositionObject *)object;
-(BOOL)isEqual:(id)object;
@end
