#import "HSWidgetBezierShapeDisclosureTableViewCell.h"
#import "HSAddNewWidgetPositionView.h"

#define MINIMUM_IMAGE_LENGTH 60

@interface UIColor (Private)
+(UIColor *)labelColor;
@end

@implementation HSWidgetBezierShapeDisclosureTableViewCell
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	if (self != nil) {
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		// create the bezier shape cell left image view
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[HSWidgetResources imageNamed:HSWidgetPlaceholderShapeImageName]];
		
		// title/section name label
		self.headlineLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		self.headlineLabel.text = @"";
		self.headlineLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
		self.headlineLabel.numberOfLines = 0;
		self.headlineLabel.backgroundColor = [UIColor clearColor];
		self.headlineLabel.textColor = [UIColor respondsToSelector:@selector(labelColor)] ? [UIColor labelColor] : [UIColor blackColor];
		self.headlineLabel.textAlignment = NSTextAlignmentLeft;

		// subtitle/section description label
		self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		self.descriptionLabel.text = @"";
		self.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
		self.descriptionLabel.numberOfLines = 0;
		self.descriptionLabel.backgroundColor = [UIColor clearColor];
		self.descriptionLabel.textColor = [UIColor respondsToSelector:@selector(labelColor)] ? [UIColor labelColor] : [UIColor blackColor];
		self.descriptionLabel.textAlignment = NSTextAlignmentLeft;

		// disclosure view
		HSAddNewWidgetPositionView *bezierShapeDisclosure = [[HSAddNewWidgetPositionView alloc] initWithWidgetPosition:nil];
		bezierShapeDisclosure.userInteractionEnabled = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
		bezierShapeDisclosure.tintColor = [UIColor respondsToSelector:@selector(systemFillColor)] ? [UIColor systemFillColor] : [UIColor darkGrayColor];
#pragma clang diagnostic pop

		BOOL isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
		CGFloat constraintSpacing = isiPad ? 30.0 : 15.0;

		// add views to heiarchy
		[self.contentView addSubview:imageView];
		[self.contentView addSubview:self.headlineLabel];
		[self.contentView addSubview:self.descriptionLabel];
		if (isiPad) {
			[self.contentView addSubview:bezierShapeDisclosure];
		}

		// add constraints
		imageView.translatesAutoresizingMaskIntoConstraints = NO;
		if (isiPad) {
			[imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:constraintSpacing].active = YES;
		} else {
			[imageView.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
		}
		[imageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
		[imageView.widthAnchor constraintEqualToConstant:MINIMUM_IMAGE_LENGTH].active = YES;
		[imageView.heightAnchor constraintEqualToConstant:MINIMUM_IMAGE_LENGTH].active = YES;

		self.headlineLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.headlineLabel.leadingAnchor constraintEqualToAnchor:imageView.trailingAnchor constant:constraintSpacing].active = YES;
		if (isiPad) {
			[self.headlineLabel.trailingAnchor constraintEqualToAnchor:bezierShapeDisclosure.leadingAnchor constant:-constraintSpacing].active = YES;
		} else {
			[self.headlineLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
		}
		[self.headlineLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:24].active = YES;
		[self.headlineLabel.bottomAnchor constraintEqualToAnchor:self.descriptionLabel.topAnchor constant:-8].active = YES;

		self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.descriptionLabel.leadingAnchor constraintEqualToAnchor:imageView.trailingAnchor constant:constraintSpacing].active = YES;
		if (isiPad) {
			[self.descriptionLabel.trailingAnchor constraintEqualToAnchor:bezierShapeDisclosure.leadingAnchor constant:-constraintSpacing].active = YES;
		} else {
			[self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
		}
		[self.descriptionLabel.topAnchor constraintEqualToAnchor:self.headlineLabel.bottomAnchor constant:-8].active = YES;
		[self.descriptionLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-24].active = YES;

		if (isiPad) {
			bezierShapeDisclosure.translatesAutoresizingMaskIntoConstraints = NO;
			[bezierShapeDisclosure.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-constraintSpacing].active = YES;
			[bezierShapeDisclosure.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
			[bezierShapeDisclosure.widthAnchor constraintEqualToConstant:MINIMUM_IMAGE_LENGTH].active = YES;
			[bezierShapeDisclosure.heightAnchor constraintEqualToConstant:MINIMUM_IMAGE_LENGTH].active = YES;
		}

		[imageView release];
		[bezierShapeDisclosure release];
	}
	return self;
}

-(void)dealloc {
	[self.headlineLabel release];
	self.headlineLabel = nil;

	[self.descriptionLabel release];
	self.descriptionLabel = nil;

	[super dealloc];
}
@end