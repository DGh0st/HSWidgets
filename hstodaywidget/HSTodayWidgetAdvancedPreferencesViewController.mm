#import "HSTodayWidgetAdvancedPreferencesViewController.h"
#import "HSTodayWidgetViewController.h"

#define EXPANSION_MODE_ID @"ExpansionMode"
#define HEIGHT_DESCRIPTOR_ID @"ModeHeightDescriptor"

#define HEIGHT_TITLE_FORMAT @"Custom %@ Height"
#define HEIGHT_DESCRIPTION_FORMAT @"Set the custom height for %@ mode. Leave empty or set to 0 to automatically calculate height."

#define BANNER_DESCRIPTION @"Note: these are beta features and are not officially supported."
#define BANNER_HEIGHT 50

@implementation HSTodayWidgetAdvancedPreferencesViewController
-(NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Advanced" target:self] retain];
	}

	return _specifiers;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	// setup everything
	[self _setupSpecifiers];
	[self _updateSpecifiersForChangesAnimated:NO];

	// setup the banner
	UIView *bannerView = [[UIView alloc] initWithFrame:CGRectZero];
	bannerView.backgroundColor = [UIColor systemRedColor];

	// setup the banner text
	UILabel *bannerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	bannerLabel.text = BANNER_DESCRIPTION;
	bannerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	bannerLabel.numberOfLines = 2;
	bannerLabel.adjustsFontSizeToFitWidth = YES;
	bannerLabel.backgroundColor = [UIColor clearColor];
	bannerLabel.textColor = [UIColor whiteColor];
	bannerLabel.textAlignment = NSTextAlignmentCenter;

	// add to view hierarchy
	[bannerView addSubview:bannerLabel];
	[self.view addSubview:bannerView];

	// setup constraints
	bannerLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[bannerLabel.topAnchor constraintEqualToAnchor:bannerView.layoutMarginsGuide.topAnchor].active = YES;
	[bannerLabel.bottomAnchor constraintEqualToAnchor:bannerView.layoutMarginsGuide.bottomAnchor].active = YES;
	[bannerLabel.leadingAnchor constraintEqualToAnchor:bannerView.layoutMarginsGuide.leadingAnchor].active = YES;
	[bannerLabel.trailingAnchor constraintEqualToAnchor:bannerView.layoutMarginsGuide.trailingAnchor].active = YES;

	bannerView.translatesAutoresizingMaskIntoConstraints = NO;
	[bannerView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
	[bannerView.heightAnchor constraintEqualToConstant:BANNER_HEIGHT].active = YES;
	[bannerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
	[bannerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;

	// add inset so the banner doesn't cover the first specifier
	UITableView *tableView = [self table];
	tableView.contentInset = UIEdgeInsetsMake(BANNER_HEIGHT, 0, 0, 0);

	[bannerView release];
	[bannerLabel release];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];

	if ([specifier isEqual:_expansionModeSpecifier]) {
		[self _updateSpecifiersForChangesAnimated:YES];
	}
}

-(void)reloadSpecifiers {
	// clear previous specifiers
	[self _clearSpecifiers];

	[super reloadSpecifiers];

	// setup everything again
	[self _setupSpecifiers];
	[self _updateSpecifiersForChangesAnimated:NO];
}

-(void)_updateSpecifiersForChangesAnimated:(BOOL)animated {
	BOOL isExpanded = [[self readPreferenceValue:_expansionModeSpecifier] boolValue];
	// update the descriptor to match the current mode
	if (isExpanded) {
		[_heightDescriptorSpecifier setProperty:[NSString stringWithFormat:HEIGHT_TITLE_FORMAT, @"Expanded"] forKey:PSTitleKey];
		[_heightDescriptorSpecifier setProperty:[NSString stringWithFormat:HEIGHT_DESCRIPTION_FORMAT, @"expanded"] forKey:PSFooterTextGroupKey];
	} else {
		[_heightDescriptorSpecifier setProperty:[NSString stringWithFormat:HEIGHT_TITLE_FORMAT, @"Compact"] forKey:PSTitleKey];
		[_heightDescriptorSpecifier setProperty:[NSString stringWithFormat:HEIGHT_DESCRIPTION_FORMAT, @"compact"] forKey:PSFooterTextGroupKey];
	}
	[self reloadSpecifier:_heightDescriptorSpecifier animated:animated];
}

-(void)_setupSpecifiers {
	_expansionModeSpecifier = [[self specifierForID:EXPANSION_MODE_ID] retain];
	_heightDescriptorSpecifier = [[self specifierForID:HEIGHT_DESCRIPTOR_ID] retain];
}

-(void)_clearSpecifiers {
	[_expansionModeSpecifier release];
	_expansionModeSpecifier = nil;

	[_heightDescriptorSpecifier release];
	_heightDescriptorSpecifier = nil;
}

-(void)dealloc {
	[self _clearSpecifiers];

	[super dealloc];
}
@end