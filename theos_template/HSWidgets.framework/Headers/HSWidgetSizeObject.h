#import "HSWidgets-structs.h"

@interface HSWidgetSizeObject : NSObject <NSCopying>
@property (nonatomic, assign) HSWidgetSize size;
@property (nonatomic, assign) NSUInteger numRows;
@property (nonatomic, assign) NSUInteger numCols;
+(instancetype)objectWithWidgetSize:(HSWidgetSize)size;
-(instancetype)initWithWidgetSize:(HSWidgetSize)size;
-(BOOL)isEqualToWidgetSizeObject:(HSWidgetSizeObject *)object;
-(BOOL)isEqual:(id)object;
@end
