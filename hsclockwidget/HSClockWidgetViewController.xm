#import "HSClockWidgetViewController.h"

#define kNumRows 2 // clock takes 2 rows
#define kDisplayName @"Time & Date"
#define kIconImageName @"HSClock"
#define kBundlePath @"/Library/Application Support/HSWidgets/Assets.bundle"

@implementation HSClockWidgetViewController
-(id)initForOriginRow:(NSUInteger)originRow withOptions:(NSDictionary *)options {
	self = [super initForOriginRow:originRow withOptions:options];
	if (self != nil) {
		self.dateView = nil;
		_numRows = options[@"NumRows"] ? [options[@"NumRows"] integerValue] : kNumRows;
		_legibilitySettings = nil; // TODO: add legibilitySettings
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

	if (self.dateView != nil) {
		CGFloat twoRowHeight = 74 * kNumRows;
		self.dateView.frame = CGRectMake(0, (self.requestedSize.height - twoRowHeight) / 2, self.requestedSize.width, twoRowHeight);
	}
}

-(void)createDateViewIfNeeded {
	if (self.dateView == nil) {
		CGFloat twoRowHeight = 74 * kNumRows;
		self.dateView = [[%c(SBFLockScreenDateView) alloc] initWithFrame:CGRectMake(0, (self.requestedSize.height - twoRowHeight) / 2, self.requestedSize.width, twoRowHeight)];
		[self.dateView setUserInteractionEnabled:NO];
		[self.dateView setLegibilitySettings:_legibilitySettings];
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Jellyfish.dylib"])
			[self.dateView setAlignmentPercent:1.0];
		else if (_options[@"AlignmentPercent"] != nil)
			[self.dateView setAlignmentPercent:[_options[@"AlignmentPercent"] doubleValue]];
		[self.view addSubview:self.dateView];
	}
}

-(void)loadView {
	[super loadView];

	SBDateTimeController *dateTimeController = [%c(SBDateTimeController) sharedInstance];
	[dateTimeController addObserver:self];

	[self createDateViewIfNeeded];

	[self _updateLegibilityStrength];
	[self updateTimeNow];
	[self _addObservers];
}

-(void)updateTimeNow {
	NSDate *overrideDate = [[%c(SBDateTimeController) sharedInstance] overrideDate];
	if (overrideDate != nil) {
		[self.dateView setDate:overrideDate];
	} else {
		Class PreciseClockTimer = %c(SBUIPreciseClockTimer) ?: %c(SBPreciseClockTimer);
		[self.dateView setDate:[PreciseClockTimer now]];
	}
}

-(void)_updateFormat {
	[self.dateView updateFormat];
	[self updateTimeNow];
}

-(void)_updateLegibilityStrength {
	SBLegibilitySettings *settings = [[[%c(SBPrototypeController) sharedInstance] rootSettings] legibilitySettings];
	CGFloat style = [_legibilitySettings style];
	[self.dateView setTimeLegibilityStrength:[settings timeStrengthForStyle:style]];
	[self.dateView setSubtitleLegibilityStrength:[settings dateStrengthForStyle:style]];
}

-(void)controller:(id)arg1 didChangeOverrideDateFromDate:(id)arg2 {
	[self _updateFormat];
}

-(void)settings:(id)arg1 changedValueForKey:(id)arg2 {
	if ([arg1 isMemberOfClass:%c(SBLegibilitySettings)])
		[self _updateLegibilityStrength];
}

-(void)_addObservers {
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self selector:@selector(_updateFormat) name:@"BSDateTimeCacheChangedNotification" object:nil];
	[defaultCenter addObserver:self selector:@selector(updateTimeNow) name:UIContentSizeCategoryDidChangeNotification object:nil];
	[defaultCenter addObserver:self selector:@selector(updateTimeNow) name:@"UIAccessibilityLargeTextChangedNotification" object:nil];

	[[[[%c(SBPrototypeController) sharedInstance] rootSettings] legibilitySettings] addKeyObserverIfPrototyping:self];
}

-(void)_removeObservers {
	[[%c(SBDateTimeController) sharedInstance] removeObserver:self];
	[[[[%c(SBPrototypeController) sharedInstance] rootSettings] legibilitySettings] removeKeyObserver:self];
}

-(void)updateWidgetAfterRespring {
	// fix clock widget not starting to update after respring
	[super updateWidgetAfterRespring];

	[self updateTimeNow];

	if (_timerToken == nil) {
		Class PreciseClockTimer = %c(SBUIPreciseClockTimer) ?: %c(SBPreciseClockTimer);
		_timerToken = [[[PreciseClockTimer sharedInstance] startMinuteUpdatesWithHandler:^{
			[self updateTimeNow];
		}] retain];
	}
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self updateTimeNow];

	if (_timerToken == nil) {
		Class PreciseClockTimer = %c(SBUIPreciseClockTimer) ?: %c(SBPreciseClockTimer);
		_timerToken = [[[PreciseClockTimer sharedInstance] startMinuteUpdatesWithHandler:^{
			[self updateTimeNow];
		}] retain];
	}
}

-(void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	if (_timerToken != nil) {
		Class PreciseClockTimer = %c(SBUIPreciseClockTimer) ?: %c(SBPreciseClockTimer);
		[[PreciseClockTimer sharedInstance] stopMinuteUpdatesForToken:_timerToken];
		[_timerToken release];
		_timerToken = nil;
	}
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
	[self _removeObservers];

	if (_timerToken != nil) {
		Class PreciseClockTimer = %c(SBUIPreciseClockTimer) ?: %c(SBPreciseClockTimer);
		[[PreciseClockTimer sharedInstance] stopMinuteUpdatesForToken:_timerToken];
		[_timerToken release];
		_timerToken = nil;
	}

	[self.dateView removeFromSuperview];
	[self.dateView release];
	self.dateView = nil;

	[super dealloc];
}
@end

%hook SBFLockScreenDateView
-(void)layoutSubviews {
	%orig;
	
	if (self.superview != nil && self.superview.superview != nil && [self.superview.superview isKindOfClass:%c(SBRootIconListView)]) {
		CGFloat twoRowHeight = 74 * kNumRows;
		self.frame = CGRectMake(0, (self.superview.frame.size.height - twoRowHeight) / 2, self.superview.frame.size.width, twoRowHeight);
	}
}
%end