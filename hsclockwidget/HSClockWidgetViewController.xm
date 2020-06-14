#import "HSClockWidgetViewController.h"
#import "SBDateTimeController.h"
#import "SBFLockScreenDateView.h"
#import "SBFLegibilityDomain.h"
#import "SBPreciseClockTimer.h"
#import "SBPrototypeController.h"
#import "SBUIPreciseClockTimer.h"
#import "_UILegibilitySettings.h"

#import <algorithm>
#import <vector>

#define MIN_NUM_ROWS 2U // clock takes up atleast 2 row
#define MIN_NUM_COLS 3U // clock takes up atleast 3 col

#define ALIGNMENT_PERCENT_KEY @"AlignmentPercent"
#define JELLYFISH_ALIGNMENT_PERCENTAGE 1.0

@implementation HSClockWidgetViewController
-(instancetype)initForWidgetFrame:(HSWidgetFrame)frame withOptions:(NSDictionary *)options {
	self = [super initForWidgetFrame:frame withOptions:options];
	if (self != nil) {
		self.dateView = nil;
		_legibilitySettings = nil; // TODO: add legibilitySettings
		_timerToken = nil;
	}
	return self;
}

+(HSWidgetSize)minimumSize {
	return HSWidgetSizeMake(MIN_NUM_ROWS, MIN_NUM_COLS);
}

+(NSInteger)allowedInstancesPerPage {
	return 1; // there only needs to be one clock/date per page
}

-(void)createDateViewIfNeeded {
	if (self.dateView == nil) {
		self.dateView = [[%c(SBFLockScreenDateView) alloc] initWithFrame:CGRectZero];
		[self.dateView setUserInteractionEnabled:NO];
		[self.dateView setLegibilitySettings:_legibilitySettings];
		if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Jellyfish.dylib"]) {
			[self.dateView setAlignmentPercent:JELLYFISH_ALIGNMENT_PERCENTAGE];
		} else if (widgetOptions[ALIGNMENT_PERCENT_KEY] != nil) {
			[self.dateView setAlignmentPercent:[widgetOptions[ALIGNMENT_PERCENT_KEY] doubleValue]];
		}
		[self.view addSubview:self.dateView];

		/*
		self.dateView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.dateView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
		[self.dateView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
		[self.dateView.heightAnchor constraintEqualToConstant:74 * MIN_NUM_ROWS].active = YES;
		[self.dateView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor].active = YES;
		*/
	}
}

-(void)setWidgetOptionValue:(id<NSCoding>)object forKey:(NSString *)key {
	[super setWidgetOptionValue:object forKey:key];

	if ([key isEqualToString:ALIGNMENT_PERCENT_KEY]) {
		[self.dateView setAlignmentPercent:[(NSNumber *)object doubleValue]];
	}
}

-(void)setRequestedSize:(CGSize)requestedSize {
	[super setRequestedSize:requestedSize];

	CGFloat twoRowHeight = 74 * MIN_NUM_ROWS;
	self.dateView.frame = CGRectMake(0, (self.requestedSize.height - twoRowHeight) / 2, self.requestedSize.width, twoRowHeight);
}

-(void)loadView {
	[super loadView];

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
	LegibilitySettings *settings = nil;
	if (%c(SBFLegibilityDomain)) {
		settings = [%c(SBFLegibilityDomain) rootSettings];
	} else {
		settings = [[[%c(SBPrototypeController) sharedInstance] rootSettings] legibilitySettings];
	}
	CGFloat style = [_legibilitySettings style];
	[self.dateView setTimeLegibilityStrength:[settings timeStrengthForStyle:style]];
	[self.dateView setSubtitleLegibilityStrength:[settings dateStrengthForStyle:style]];
}

-(void)controller:(id)arg1 didChangeOverrideDateFromDate:(id)arg2 {
	[self _updateFormat];
}

-(void)settings:(id)arg1 changedValueForKey:(id)arg2 {
	Class LegibilitySettings = %c(SBLegibilitySettings) ?: %c(SBFLegibilitySettings);
	if ([arg1 isMemberOfClass:LegibilitySettings]) {
		[self _updateLegibilityStrength];
	}
}

-(void)_addObservers {
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self selector:@selector(_updateFormat) name:@"BSDateTimeCacheChangedNotification" object:nil];
	[defaultCenter addObserver:self selector:@selector(updateTimeNow) name:UIContentSizeCategoryDidChangeNotification object:nil];
	[defaultCenter addObserver:self selector:@selector(updateTimeNow) name:@"UIAccessibilityLargeTextChangedNotification" object:nil];

	[[%c(SBDateTimeController) sharedInstance] addObserver:self];
	if (%c(SBFLegibilityDomain)) {
		[[%c(SBFLegibilityDomain) rootSettings] addKeyObserver:self];
	} else {
		[[[[%c(SBPrototypeController) sharedInstance] rootSettings] legibilitySettings] addKeyObserverIfPrototyping:self];
	}

	[defaultCenter addObserver:self selector:@selector(updateWidgetAfterRespring) name:HSWidgetAllWidgetsConfiguredNotification object:nil];
}

-(void)_removeObservers {
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter removeObserver:self name:@"BSDateTimeCacheChangedNotification" object:nil];
	[defaultCenter removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
	[defaultCenter removeObserver:self name:@"UIAccessibilityLargeTextChangedNotification" object:nil];

	[[%c(SBDateTimeController) sharedInstance] removeObserver:self];
	if (%c(SBFLegibilityDomain)) {
		[[%c(SBFLegibilityDomain) rootSettings] removeKeyObserver:self];
	} else {
		[[[[%c(SBPrototypeController) sharedInstance] rootSettings] legibilitySettings] removeKeyObserver:self];
	}

	[defaultCenter removeObserver:self name:HSWidgetAllWidgetsConfiguredNotification object:nil];
}

-(void)updateWidgetAfterRespring {
	// fix clock widget not starting to update after respring
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

-(BOOL)_canExpand:(inout HSWidgetSize *)expandSize {
	std::vector<HSWidgetSize> expandSizes;
	expandSizes.push_back(HSWidgetSizeAdd(self.widgetFrame.size, 1, 1)); // expand row and col
	expandSizes.push_back(HSWidgetSizeAdd(self.widgetFrame.size, 0, 1)); // expand col
	expandSizes.push_back(HSWidgetSizeAdd(self.widgetFrame.size, 1, 0)); // expand row

	for (const HSWidgetSize &size : expandSizes) {
		if ([super containsSpaceToExpandOrShrinkToWidgetSize:size]) {
			if (expandSize != nil) {
				*expandSize = size;
			}
			return YES;
		}
	}

	// we can't expand
	return NO;
}

-(BOOL)_canShrink:(inout HSWidgetSize *)shrinkSize {
	// try shrinking row and/or col
	HSWidgetSize shrunkWidgetSize;
	shrunkWidgetSize.numRows = MAX(self.widgetFrame.size.numRows - 1, MIN_NUM_ROWS);
	shrunkWidgetSize.numCols = MAX(self.widgetFrame.size.numCols - 1, MIN_NUM_COLS);
	if (!HSWidgetSizeEqualsSize(self.widgetFrame.size, shrunkWidgetSize)) {
		if (shrinkSize != nil) {
			*shrinkSize = shrunkWidgetSize;
		}
		return YES;
	}

	// we can't shrink
	return NO;
}

-(BOOL)isAccessoryTypeEnabled:(AccessoryType)accessory {
	// check if expand or shrink
	if (accessory == AccessoryTypeExpand) {
		return [self _canExpand:nil];
	} else if (accessory == AccessoryTypeShrink) {
		return [self _canShrink:nil];
	} else if (accessory == AccessoryTypeSettings) {
		// currently we only support Alignment Percentage which Jellyfish forces to 1.0 so if we are using Jellyfish don't add settings
		return ![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Jellyfish.dylib"];
	}

	// anything else we don't support but let super class handle it incase new accessory types are added
	return [super isAccessoryTypeEnabled:accessory];
}

-(void)accessoryTypeTapped:(AccessoryType)accessory {
	if (accessory == AccessoryTypeExpand) {
		// handle expand tapped
		HSWidgetSize expandSize;
		if ([self _canExpand:&expandSize]) {
			[super updateForExpandOrShrinkToWidgetSize:expandSize];
		}
	} else if (accessory == AccessoryTypeShrink) {
		// handle shrink tapped
		HSWidgetSize shrinkSize;
		if ([self _canShrink:&shrinkSize]) {
			[super updateForExpandOrShrinkToWidgetSize:shrinkSize];
		}
	}
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
	%orig();

	if (self.superview != nil && [self.superview isKindOfClass:%c(HSWidgetUnclippedView)]) {
		CGFloat twoRowHeight = 74 * MIN_NUM_ROWS;
		self.frame = CGRectMake(0, (self.superview.frame.size.height - twoRowHeight) / 2, self.superview.frame.size.width, twoRowHeight);
	}
}
%end
