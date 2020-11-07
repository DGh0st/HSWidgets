#import "HSModernWidgetViewController.h"

@interface CALayer ()
@property (nonatomic) BOOL continuousCorners;
@end

#define LABEL_YOFFSET 5.0
#define FONT_SIZE 12.0
#define CORNER_RADIUS 20.0
#define EXPANDED_KEY @"isExpanded"

static void SetContinuousCornerRadius(UIView *view, CGFloat cornerRadius) {
	view.layer.cornerRadius = cornerRadius;
	// enable continuous corner radius
	if ([view.layer respondsToSelector:@selector(setCornerCurve:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
		// iOS 13+
		view.layer.cornerCurve = kCACornerCurveContinuous;
#pragma clang diagnostic pop
	} else if ([view.layer respondsToSelector:@selector(setContinuousCorners:)]) {
		// iOS 11 - 12
		view.layer.continuousCorners = YES;
	}
}

@implementation HSModernWidgetViewController
+(HSWidgetSize)minimumSize {
	return HSWidgetSizeMake(2, 2);
}

+(NSInteger)allowedInstancesPerPage {
	return 1; // there only needs to be one these modern widget types
}

-(instancetype)initForWidgetFrame:(HSWidgetFrame)frame withOptions:(NSDictionary *)options {
	self = [super initForWidgetFrame:frame withOptions:options];
	if (self != nil) {
		self.cornerRadius = CORNER_RADIUS;
		self.blurView = nil;
		self.titleLabel = nil;
		self.isExpanded = options[EXPANDED_KEY] ? [options[EXPANDED_KEY] boolValue] : NO;
	}
	return self;
}

-(CGRect)calculatedFrame {
	BOOL isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
	CGFloat fontHeightInFrame = isiPad ? (FONT_SIZE + 1) : (FONT_SIZE / 2.0 + 2.0);
	return CGRectMake(0, 0, self.requestedSize.width, self.requestedSize.height - LABEL_YOFFSET - fontHeightInFrame);
}

-(void)setCornerRadius:(CGFloat)cornerRadius {
	[super setCornerRadius:cornerRadius];
	SetContinuousCornerRadius(self.blurView, cornerRadius);
}

-(BOOL)isAccessoryTypeEnabled:(AccessoryType)accessory {
	if (accessory == AccessoryTypeExpand)
		return !self.isExpanded && [super containsSpaceToExpandOrShrinkToWidgetSize:HSWidgetSizeMake(2, 4)];
	else if (accessory == AccessoryTypeShrink)
		return self.isExpanded && [super containsSpaceToExpandOrShrinkToWidgetSize:HSWidgetSizeMake(2, 2)];
	return [super isAccessoryTypeEnabled:accessory];
}

-(void)accessoryTypeTapped:(AccessoryType)accessory {
	if (accessory == AccessoryTypeExpand) {
		HSWidgetSize expandSize = HSWidgetSizeMake(2, 4);
		if (!self.isExpanded && [super containsSpaceToExpandOrShrinkToWidgetSize:expandSize]) {
			self.isExpanded = YES;
			[self expandWidget];
			[super updateForExpandOrShrinkToWidgetSize:expandSize];
		}
	} else if (accessory == AccessoryTypeShrink) {
		HSWidgetSize shrinkSize = HSWidgetSizeMake(2, 2);
		if (self.isExpanded && [super containsSpaceToExpandOrShrinkToWidgetSize:shrinkSize]) {
			self.isExpanded = NO;
			[self shrinkWidget];
			[super updateForExpandOrShrinkToWidgetSize:shrinkSize];
		}
	}
}

-(void)expandWidget {
	// subclass implements this to perform additional actions
}

-(void)shrinkWidget {
	// subclass implements this to perform additional actions
}

-(void)viewDidLoad {
	[super viewDidLoad];

	BOOL isiPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;

	// setup label
	self.titleLabel = [[UILabel alloc] init];
	self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE weight:UIFontWeightMedium];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.titleLabel.text = [[self class] widgetDisplayInfo][HSWidgetDisplayNameKey];
	self.titleLabel.textColor = [UIColor whiteColor];
	self.titleLabel.numberOfLines = 0;
	[self.view addSubview:self.titleLabel];

	[self.titleLabel sizeToFit];

	self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[self.titleLabel.heightAnchor constraintEqualToConstant:FONT_SIZE].active = YES;
	if (isiPad)
		[self.titleLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:1].active = YES;
	else
		[self.titleLabel.centerYAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-2].active = YES;
	[self.titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
	[self.titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
	
	// setup background
	UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
	self.blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	self.blurView.layer.masksToBounds = YES;

	SetContinuousCornerRadius(self.blurView, self.cornerRadius);

	[self.view addSubview:self.blurView];

	self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.blurView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
	[self.blurView.bottomAnchor constraintEqualToAnchor:self.titleLabel.topAnchor constant:-LABEL_YOFFSET].active = YES;
	[self.blurView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
#ifdef FORCE_SQUARE
	[self.blurView.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor].active = YES;
	[self.blurView.heightAnchor constraintEqualToAnchor:self.blurView.widthAnchor].active = YES;
	[self.blurView.widthAnchor constraintEqualToAnchor:self.blurView.heightAnchor].active = YES;
#else
	[self.blurView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
#endif
}

-(UIView *)contentView {
	return self.blurView.contentView;
}

-(void)setIsExpanded:(BOOL)expanded {
	_isExpanded = expanded;
	[self setWidgetOptionValue:@(expanded) forKey:EXPANDED_KEY];
}

-(void)dealloc {
	[self.titleLabel release];
	self.titleLabel = nil;

	[self.blurView release];
	self.blurView = nil;

	[super dealloc];
}
@end