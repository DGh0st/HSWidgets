#import "HSWidgetHeaderTableView.h"

@interface UIColor (Private)
+(UIColor *)labelColor;
@end

@implementation HSWidgetHeaderTableView
-(instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithReuseIdentifier:reuseIdentifier];
	if (self != nil) {
		// title/section name label
		self.sectionName = [[UILabel alloc] initWithFrame:CGRectZero];
		self.sectionName.text = @"";
		self.sectionName.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
		self.sectionName.numberOfLines = 0;
		self.sectionName.backgroundColor = [UIColor clearColor];
		self.sectionName.textColor = [UIColor respondsToSelector:@selector(labelColor)] ? [UIColor labelColor] : [UIColor blackColor];
		self.sectionName.textAlignment = NSTextAlignmentCenter;

		// subtitle/section description label
		self.sectionDescription = [[UILabel alloc] initWithFrame:CGRectZero];
		self.sectionDescription.text = @"";
		self.sectionDescription.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
		self.sectionDescription.numberOfLines = 0;
		self.sectionDescription.backgroundColor = [UIColor clearColor];
		self.sectionDescription.textColor = [UIColor respondsToSelector:@selector(labelColor)] ? [UIColor labelColor] : [UIColor blackColor];
		self.sectionDescription.textAlignment = NSTextAlignmentCenter;

		// background view for height constraints (minimum of 200)
		UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
		backgroundView.backgroundColor = [UIColor clearColor];
		
		// add views to heiarchy
		[self.contentView addSubview:backgroundView];
		[self.contentView addSubview:self.sectionName];
		[self.contentView addSubview:self.sectionDescription];

		// add constraints
		backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
		[backgroundView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
		[backgroundView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
		[backgroundView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor].active = YES;
		[backgroundView.heightAnchor constraintGreaterThanOrEqualToConstant:HSWidgetAddMinimumHeaderHeight].active = YES;

		self.sectionName.translatesAutoresizingMaskIntoConstraints = NO;
		[self.sectionName.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
		[self.sectionName.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor constant:-64].active = YES;
		[self.sectionName.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:24].active = YES;
		[self.sectionName.bottomAnchor constraintEqualToAnchor:self.sectionDescription.topAnchor constant:-8].active = YES;

		self.sectionDescription.translatesAutoresizingMaskIntoConstraints = NO;
		[self.sectionDescription.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor].active = YES;
		[self.sectionDescription.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor constant:-64].active = YES;
		[self.sectionDescription.topAnchor constraintEqualToAnchor:self.sectionName.bottomAnchor constant:-8].active = YES;
		[self.sectionDescription.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-24].active = YES;

		[backgroundView release];
	}
	return self;
}

-(void)dealloc {
	[self.sectionName release];
	self.sectionName = nil;

	[self.sectionDescription release];
	self.sectionDescription = nil;

	[super dealloc];
}
@end
