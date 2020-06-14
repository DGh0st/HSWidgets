#import "HSWidgetSizeObject.h"

@implementation HSWidgetSizeObject
+(instancetype)objectWithWidgetSize:(HSWidgetSize)size {
	return [[[self alloc] initWithWidgetSize:size] autorelease];
}

-(instancetype)initWithWidgetSize:(HSWidgetSize)size {
	self = [super init];
	self.size = size;
	return self;
}

-(instancetype)copyWithZone:(NSZone *)zone {
	return [[[self class] allocWithZone:zone] initWithWidgetSize:self.size];
}

-(NSUInteger)numRows {
	return self.size.numRows;
}

-(void)setNumRows:(NSUInteger)numRows {
	self.size = HSWidgetSizeMake(numRows, self.size.numCols);
}

-(NSUInteger)numCols {
	return self.size.numCols;
}

-(void)setNumCols:(NSUInteger)numCols {
	self.size = HSWidgetSizeMake(self.size.numCols, numCols);
}

-(BOOL)isEqualToWidgetSizeObject:(HSWidgetSizeObject *)object {
	return HSWidgetSizeEqualsSize(self.size, object.size);
}

-(BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[HSWidgetSizeObject class]])
		return [self isEqualToWidgetSizeObject:object];
	return [super isEqual:object];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"(%zu, %zu)", self.size.numRows, self.size.numCols];
}
@end
