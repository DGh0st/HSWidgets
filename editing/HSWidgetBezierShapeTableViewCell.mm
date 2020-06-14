#import "HSWidgetBezierShapeTableViewCell.h"
#import "HSAddNewWidgetPositionView.h"

#define MINIMUM_IMAGE_LENGTH 60

@interface HSAddNewWidgetPositionView ()
@property (nonatomic, assign) BOOL _isTouchInside;
@end

@interface HSWidgetBezierShapeTableViewCell () {
	HSAddNewWidgetPositionView *_bezierShapeView;
	HSAddNewWidgetPositionView *_bezierShapeSelectedView;
}
@end

@implementation HSWidgetBezierShapeTableViewCell
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	if (self != nil) {
		// shape name label
		self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		self.nameLabel.text = @"";
		self.nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
		self.nameLabel.numberOfLines = 0;
		self.nameLabel.backgroundColor = [UIColor clearColor];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
		self.nameLabel.textColor = [UIColor respondsToSelector:@selector(labelColor)] ? [UIColor labelColor] : [UIColor blackColor];
#pragma clang diagnostic pop
		self.nameLabel.textAlignment = NSTextAlignmentLeft;

		// create bezier shape view
		_bezierShapeView = [[HSAddNewWidgetPositionView alloc] initWithWidgetPosition:nil];
		_bezierShapeView.userInteractionEnabled = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
		_bezierShapeView.tintColor = [UIColor respondsToSelector:@selector(systemFillColor)] ? [UIColor systemFillColor] : [UIColor darkGrayColor];
#pragma clang diagnostic pop

		// create bezier selected shape view
		_bezierShapeSelectedView = [[HSAddNewWidgetPositionView alloc] initWithWidgetPosition:nil];
		_bezierShapeSelectedView.userInteractionEnabled = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
		_bezierShapeSelectedView.tintColor = [UIColor respondsToSelector:@selector(systemFillColor)] ? [UIColor systemFillColor] : [UIColor darkGrayColor];
#pragma clang diagnostic pop
		_bezierShapeSelectedView._isTouchInside = YES;

		// create container view to center the two bezier shapes
		UIView *bezierShapeContainerView = [[UIView alloc] init];
		[bezierShapeContainerView addSubview:_bezierShapeView];
		[bezierShapeContainerView addSubview:_bezierShapeSelectedView];

		// add views to heiarchy
		[self.contentView addSubview:self.nameLabel];
		[self.contentView addSubview:bezierShapeContainerView];

		// add constraints
		self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
		[self.nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
		[self.nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8].active = YES;
		[self.nameLabel.bottomAnchor constraintEqualToAnchor:bezierShapeContainerView.topAnchor constant:-16].active = YES;

		bezierShapeContainerView.translatesAutoresizingMaskIntoConstraints = NO;
		[bezierShapeContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
		[bezierShapeContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
		[bezierShapeContainerView.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:-16].active = YES;
		[bezierShapeContainerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:16].active = YES;
		[bezierShapeContainerView.heightAnchor constraintGreaterThanOrEqualToConstant:MINIMUM_IMAGE_LENGTH + 32].active = YES;

		_bezierShapeView.translatesAutoresizingMaskIntoConstraints = NO;
		[_bezierShapeView.leadingAnchor constraintEqualToAnchor:bezierShapeContainerView.leadingAnchor].active = YES;
		[_bezierShapeView.topAnchor constraintEqualToAnchor:bezierShapeContainerView.topAnchor].active = YES;
		[_bezierShapeView.widthAnchor constraintEqualToConstant:MINIMUM_IMAGE_LENGTH].active = YES;
		[_bezierShapeView.heightAnchor constraintEqualToConstant:MINIMUM_IMAGE_LENGTH].active = YES;

		_bezierShapeSelectedView.translatesAutoresizingMaskIntoConstraints = NO;
		[_bezierShapeSelectedView.leadingAnchor constraintEqualToAnchor:_bezierShapeView.trailingAnchor constant:16].active = YES;
		[_bezierShapeSelectedView.topAnchor constraintEqualToAnchor:bezierShapeContainerView.topAnchor].active = YES;
		[_bezierShapeSelectedView.widthAnchor constraintEqualToConstant:MINIMUM_IMAGE_LENGTH].active = YES;
		[_bezierShapeSelectedView.heightAnchor constraintEqualToConstant:MINIMUM_IMAGE_LENGTH].active = YES;

		[bezierShapeContainerView release];
	}
	return self;
}

-(void)setBezierShape:(HSWidgetBezierShape)shape {
	_bezierShape = shape;

	_bezierShapeView.bezierShape = shape;
	[_bezierShapeView setNeedsLayout];

	_bezierShapeSelectedView.bezierShape = shape;
	[_bezierShapeSelectedView setNeedsLayout];
}

-(void)dealloc {
	[self.nameLabel release];
	self.nameLabel = nil;

	[_bezierShapeView release];
	_bezierShapeView = nil;

	[_bezierShapeSelectedView release];
	_bezierShapeSelectedView = nil;

	[super dealloc];
}
@end