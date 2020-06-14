#import "HSTodayWidgetStepperCell.h"

@interface PSSpecifier (Private)
-(id)performGetter; // iOS 9 - 13
@end

@interface PSTableCell (Private)
-(void)reloadWithSpecifier:(PSSpecifier *)specifier animated:(BOOL)animated; // iOS 6 -  13
@end

@interface HSTodayWidgetStepperCell ()
@property (nonatomic, retain) UIStepper *control;
@end

@implementation HSTodayWidgetStepperCell
@dynamic control;

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier  {
	self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier specifier:specifier];
	if (self != nil) {
		self.accessoryView = self.control;

		NSNumber *currentValue = [self.specifier performGetter];
		self.control.value = [currentValue unsignedIntegerValue];
		self.detailTextLabel.text = [currentValue stringValue];
	}
	return self;
}

-(void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	[self _configureForSpecifier:specifier];
}

-(void)reloadWithSpecifier:(PSSpecifier *)specifier animated:(BOOL)animated {
	[super reloadWithSpecifier:specifier animated:animated];
	[self _configureForSpecifier:specifier];
}

-(UIStepper *)newControl {
	UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectZero];
	stepper.continuous = NO;
	stepper.minimumValue = [self.specifier.properties[PSControlMinimumKey] unsignedIntegerValue];
	stepper.maximumValue = [self.specifier.properties[PSControlMaximumKey] unsignedIntegerValue];
	stepper.value =  [[self.specifier performGetter] unsignedIntegerValue];
	return stepper;
}

-(NSNumber *)controlValue {
	return @(self.control.value);
}

-(void)setValue:(NSNumber *)value {
	[super setValue:value];
	[self _configureForSpecifier:self.specifier];
}

-(void)controlChanged:(UIStepper *)stepper {
	[super controlChanged:stepper];
	self.detailTextLabel.text = [@(stepper.value) stringValue];
}

-(void)_configureForSpecifier:(PSSpecifier *)specifier {
	NSNumber *currentValue = [specifier performGetter];
	self.control.minimumValue = [specifier.properties[PSControlMinimumKey] unsignedIntegerValue];
	self.control.maximumValue = [specifier.properties[PSControlMaximumKey] unsignedIntegerValue];
	self.control.value = [currentValue unsignedIntegerValue];
	
	self.detailTextLabel.text = [currentValue stringValue];
}
@end
