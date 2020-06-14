#import "HSWidgetPositionObject.h"

@implementation HSWidgetPositionObject
+(instancetype)objectWithWidgetPosition:(HSWidgetPosition)position {
	return [[[self alloc] initWithWidgetPosition:position] autorelease];
}

-(instancetype)initWithWidgetPosition:(HSWidgetPosition)position {
	self = [super init];
	self.position = position;
	return self;
}

-(instancetype)copyWithZone:(NSZone *)zone {
	return [[[self class] allocWithZone:zone] initWithWidgetPosition:self.position];
}

-(NSUInteger)row {
	return self.position.row;
}

-(void)setRow:(NSUInteger)row {
	self.position = HSWidgetPositionMake(row, self.position.col);
}

-(NSUInteger)col {
	return self.position.col;
}

-(void)setCol:(NSUInteger)col {
	self.position = HSWidgetPositionMake(self.position.row, col);
}

-(BOOL)isEqualToWidgetPositionObject:(HSWidgetPositionObject *)object {
	return HSWidgetPositionEqualsPosition(self.position, object.position);
}

-(BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[HSWidgetPositionObject class]])
		return [self isEqualToWidgetPositionObject:object];
	return [super isEqual:object];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"(%zu, %zu)", self.position.row, self.position.col];
}
@end
