#import "HSWidgets-structs.h"

@interface HSWidgetFrameObject : NSObject <NSCopying>
@property (nonatomic, assign) HSWidgetFrame frame;
@property (nonatomic, assign) HSWidgetPosition origin;
@property (nonatomic, assign) HSWidgetSize size;
+(instancetype)objectWithWidgetFrame:(HSWidgetFrame)frame;
-(instancetype)initWithWidgetFrame:(HSWidgetFrame)frame;
-(BOOL)isEqualToWidgetFrameObject:(HSWidgetFrameObject *)object;
-(BOOL)isEqual:(id)object;
@end
