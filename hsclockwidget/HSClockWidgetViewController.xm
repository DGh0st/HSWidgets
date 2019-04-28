#import "HSClockWidgetViewController.h"

#define kNumRows 2 // clock takes 2 rows
#define kDisplayName @"Time & Date"
#define kIconImageName @"HSClock"
#define kBundlePath @"/Library/Application Support/HSWidgets/Assets.bundle"

@implementation HSClockWidgetViewController
-(id)initForOriginRow:(NSUInteger)originRow withOptions:(NSDictionary *)options {
	self = [super initForOriginRow:originRow withOptions:options];
	if (self != nil) {
		self.dateViewController = [[%c(SBLockScreenDateViewController) alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
		_numRows = options[@"NumRows"] ? [options[@"NumRows"] integerValue] : kNumRows;
	}
	return self;
}

-(NSUInteger)numRows {
	return _numRows;
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
	return @{
		@"NumRows" : @(kNumRows)
	};
}

+(NSInteger)allowedInstancesPerPage {
	return 1; // there only needs to be one clock/date per page
}

-(CGRect)calculatedFrame {
	return (CGRect){{0, 0}, self.requestedSize};
}

-(void)setRequestedSize:(CGSize)requestedSize {
	[super setRequestedSize:requestedSize];

	if (self.dateViewController != nil) {
		CGFloat twoRowHeight = 74 * kNumRows;
		[self.dateViewController dateView].frame = CGRectMake(0, (self.requestedSize.height - twoRowHeight) / 2, self.requestedSize.width, twoRowHeight);
	}
}

-(void)loadView {
	[super loadView];

	[self addChildViewController:self.dateViewController];
	MSHookIvar<BOOL>(self.dateViewController, "_disablesUpdates") = NO;
	CGFloat twoRowHeight = 74 * kNumRows;
	[self.dateViewController dateView].frame = CGRectMake(0, (self.requestedSize.height - twoRowHeight) / 2, self.requestedSize.width, twoRowHeight);
	[self.view addSubview:[self.dateViewController dateView]];
	[self.dateViewController didMoveToParentViewController:self];
	[self.dateViewController _updateView];
}

-(BOOL)canExpandWidget {
	return [self availableRows] >= 1;
}

-(BOOL)canShrinkWidget {
	return _numRows > kNumRows;
}

-(void)expandBoxTapped {
	++_numRows;
	_options[@"NumRows"] = @(_numRows);

	[self updateForExpandOrShrinkFromRows:_numRows - 1];
}

-(void)shrinkBoxTapped {
	--_numRows;
	_options[@"NumRows"] = @(_numRows);

	[self updateForExpandOrShrinkFromRows:_numRows + 1];
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
	
	if (self.superview != nil && self.superview.superview != nil && [self.superview.superview isKindOfClass:%c(SBRootIconListView)]) {
		CGFloat twoRowHeight = 74 * kNumRows;
		self.frame = CGRectMake(0, (self.superview.frame.size.height - twoRowHeight) / 2, self.superview.frame.size.width, twoRowHeight);
	}
}
%end