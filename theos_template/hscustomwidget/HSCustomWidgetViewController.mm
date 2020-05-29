#import "HSCustomWidgetViewController.h"

@implementation HSCustomWidgetViewController
-(void)viewDidLoad {
	[super viewDidLoad];

	NSInteger colorPicked = [widgetOptions[@"WidgetColor"] integerValue];

	self.square = [[UIView alloc] initWithFrame:[self calculatedFrame]];
	if (colorPicked == 0)
		self.square.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
	else if (colorPicked == 1)
		self.square.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
	else if (colorPicked == 2)
		self.square.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
	self.square.layer.cornerRadius = self.cornerRadius;
	[self.view addSubview:self.square];
}

-(void)setWidgetOptionValue:(id<NSCoding>)object forKey:(NSString *)key {
	[super setWidgetOptionValue:object forKey:key];

	if ([key isEqualToString:@"WidgetColor"]) {
		NSInteger colorPicked = [widgetOptions[@"WidgetColor"] integerValue];
		if (colorPicked == 0)
        	        self.square.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
	        else if (colorPicked == 1)
                	self.square.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
        	else if (colorPicked == 2)
	                self.square.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
	}
}

-(CGRect)calculatedFrame {
	CGFloat length = MIN(self.requestedSize.width, self.requestedSize.height);
	return CGRectMake(5, 5, length - 10, length - 10);
}

-(BOOL)isAccessoryTypeEnabled:(AccessoryType)accessory {
	if (accessory == AccessoryTypeExpand) {
		HSWidgetSize finalExpandedSize = HSWidgetSizeAdd(self.widgetFrame.size, 1, 1);
		return [super containsSpaceToExpandOrShrinkToWidgetSize:finalExpandedSize];
	} else if (accessory == AccessoryTypeShrink) {
		return self.widgetFrame.size.numRows > 1 && self.widgetFrame.size.numCols > 1;
	}

	// anything else we don't support but let super class handle it incase new accessory types are added
	return [super isAccessoryTypeEnabled:accessory];
}

-(void)accessoryTypeTapped:(AccessoryType)accessory {
	if (accessory == AccessoryTypeExpand) {
		HSWidgetSize finalExpandSize = HSWidgetSizeAdd(self.widgetFrame.size, 1, 1);
		[super updateForExpandOrShrinkToWidgetSize:finalExpandSize];
	} else if (accessory == AccessoryTypeShrink) {
		HSWidgetSize finalShrinkSize = HSWidgetSizeAdd(self.widgetFrame.size, -1, -1);
		[super updateForExpandOrShrinkToWidgetSize:finalShrinkSize];
	}
}

-(void)setRequestedSize:(CGSize)size {
	[super setRequestedSize:size];

	CGFloat length = MIN(size.width, size.height);
	self.square.frame = CGRectMake(5, 5, length - 10, length - 10);
}

+(HSWidgetSize)minimumSize {
	return HSWidgetSizeMake(1, 1); // least amount of rows and cols the widget needs
}
@end
