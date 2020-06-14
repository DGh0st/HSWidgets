#import "HSWidgetAvailablePositionObject.h"

@implementation HSWidgetAvailablePositionObject
+(instancetype)objectWithAvailableWidgetPosition:(HSWidgetPosition)position containingIcon:(BOOL)containsIcon {
	return [[[self alloc] initWithAvailableWidgetPosition:position containingIcon:containsIcon] autorelease];
}

-(instancetype)initWithAvailableWidgetPosition:(HSWidgetPosition)position containingIcon:(BOOL)containsIcon {
	self = [super initWithWidgetPosition:position];
	self.containsIcon = containsIcon;
	return self;
}

-(instancetype)copyWithZone:(NSZone *)zone {
	return [[[self class] allocWithZone:zone] initWithAvailableWidgetPosition:self.position containingIcon:self.containsIcon];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"(%zu, %zu) %@ icon", self.position.row, self.position.col, self.containsIcon ? @"contains" : @"does not contain"];
}
@end
