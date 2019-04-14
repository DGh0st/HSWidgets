#import "HSClockWidgetViewController.h"

#define kNumRows 2 // clock takes 2 rows
#define kDisplayName @"Time & Date"
#define kIconImageName @"HSClock"
#define kBundlePath @"/Library/Application Support/HSWidgets/Assets.bundle"

@implementation HSClockWidgetViewController
-(id)initForOriginRow:(NSUInteger)originRow withOptions:(NSDictionary *)options {
	self = [super initForOriginRow:originRow withOptions:options];
	if (self != nil)
		self.dateViewController = [[%c(SBLockScreenDateViewController) alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
	return self;
}

-(NSUInteger)numRows {
	return kNumRows;
}

+(BOOL)canAddWidgetForAvailableRows:(NSUInteger)rows {
	return rows >= kNumRows; // least amount of rows needed
}

+(NSString *)displayName {
	return kDisplayName;
}

+(UIImage *)icon {
	return [UIImage imageNamed:kIconImageName inBundle:[NSBundle bundleWithPath:kBundlePath] compatibleWithTraitCollection:nil];
}

+(Class)addNewWidgetAdditionalOptionsClass {
	return nil; // we don't have any additional options for this so we don't want to display anything when add new widget selection is being displayed
}

+(NSDictionary *)createOptionsFromController:(id)controller {
	return nil; // we don't need any options
}

+(NSInteger)allowedInstancesPerPage {
	return 1; // there only needs to be one clock/date per page
}

-(CGRect)calculatedFrame {
	return (CGRect){{0, 0}, self.requestedSize};
}

-(void)setRequestedSize:(CGSize)requestedSize {
	[super setRequestedSize:requestedSize];

	if (self.dateViewController != nil)
		[self.dateViewController dateView].frame = [self calculatedFrame];
}

-(void)loadView {
	[super loadView];

	[self.dateViewController dateView].frame = [self calculatedFrame];
	[self.view addSubview:[self.dateViewController dateView]];
	MSHookIvar<BOOL>(self.dateViewController, "_disablesUpdates") = NO;
	[self.dateViewController _updateView];
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self.dateViewController dateView].frame = [self calculatedFrame];
	MSHookIvar<BOOL>(self.dateViewController, "_disablesUpdates") = NO;
	[self.dateViewController _updateView];
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	MSHookIvar<BOOL>(self.dateViewController, "_disablesUpdates") = YES;
	[self.dateViewController _updateView];
}

-(void)dealloc {
	if (self.dateViewController != nil) {
		[self.dateViewController release];
		self.dateViewController = nil;
	}

	[super dealloc];
}
@end

%hook SBFLockscreenDateView
-(void)layoutSubviews {
	%orig;
	
	if (self.superview != nil && self.superview.superview != nil && [self.superview.superview isKindOfClass:%c(SBRootIconListView)])
		self.frame = (CGRect){{0, 0}, self.superview.frame.size};
}
%end