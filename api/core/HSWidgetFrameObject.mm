#import "HSWidgetFrameObject.h"

@implementation HSWidgetFrameObject
+(instancetype)objectWithWidgetFrame:(HSWidgetFrame)frame {
	return [[[self alloc] initWithWidgetFrame:frame] autorelease];
}

-(instancetype)initWithWidgetFrame:(HSWidgetFrame)frame {
	self = [super init];
	self.frame = frame;
	return self;
}

-(instancetype)copyWithZone:(NSZone *)zone {
	return [[[self class] allocWithZone:zone] initWithWidgetFrame:self.frame];
}

-(HSWidgetPosition)origin
{
	return self.frame.origin;
}

-(void)setOrigin:(HSWidgetPosition)origin {
	self.frame = HSWidgetFrameMake(origin, self.frame.size);
}

-(HSWidgetSize)size
{
	return self.frame.size;
}

-(void)setSize:(HSWidgetSize)size {
	self.frame = HSWidgetFrameMake(self.frame.origin, size);
}

-(BOOL)isEqualToWidgetFrameObject:(HSWidgetFrameObject *)object {
	return HSWidgetFrameEqualsFrame(self.frame, object.frame);
}

-(BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[HSWidgetFrameObject class]])
		return [self isEqualToWidgetFrameObject:object];
	return [super isEqual:object];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"(%zu, %zu, %zu, %zu)", self.frame.origin.row, self.frame.origin.col, self.frame.size.numRows, self.frame.size.numCols];
}
@end
