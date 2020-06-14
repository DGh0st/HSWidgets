#import "HSTodayWidgetRootPreferencesViewController.h"
#import "HSTodayWidgetViewController.h"
#import "WGWidgetHostingViewController.h"
#import "WGWidgetInfo.h"

#define WIDTH_STYLE_DESCRIPTER_ID @"WidthStyleDescriptor"
#define WIDTH_STYLE_PICKER_ID @"WidthStylePicker"
#define CUSTOM_WIDTH_ID @"CustomWidth"
#define SPACES_ROW_STEPPER_ID @"SpacesRowStepper"
#define SPACES_COL_STEPPER_ID @"SpacesColStepper"

#define PICKER_DESCRIPTION @"Pick the style used for determining the widget width."
#define CUSTOM_WIDTH_DESCRIPTION @"Set the custom width used for the widget."

@interface PSListController (Private)
-(BOOL)containsSpecifier:(id)arg1; // iOS 3 - 13
@end

typedef NS_ENUM(NSUInteger, HSTodayWidgetUpdateStyle) {
	HSTodayWidgetUpdateStyleBoth = 0,
	HSTodayWidgetUpdateStyleRows,
	HSTodayWidgetUpdateStyleCols
};

@implementation HSTodayWidgetRootPreferencesViewController
-(NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	// setup everything
	[self _setupNavigationTitle];
	[self _setupSpecifiersForWidthStyle];
	[self _setupSpecifiersForIconSpaces];
	[self _updateSpecifiersForChangesToWidthStyleAnimated:NO];
	[self _updateSpecifiersForChangesToIconSpacesAnimated:NO];
}

-(void)resetAllSettings {
	[self setPreferenceValue:@(HSTodayWidgetMinNumRows) specifier:_spacesRowSpecifier];
	[self setPreferenceValue:@(HSTodayWidgetMinNumCols) specifier:_spacesColSpecifier];

	[super resetAllSettings];
}

-(void)reloadSpecifiers {
	// clear previous specifiers
	[self _clearSpecifiersForWidthStyle];
	[self _clearSpecifiersForIconSpaces];

	[super reloadSpecifiers];

	// setup everything again
	[self _setupNavigationTitle];
	[self _setupSpecifiersForWidthStyle];
	[self _setupSpecifiersForIconSpaces];
	[self _updateSpecifiersForChangesToWidthStyleAnimated:NO];
	[self _updateSpecifiersForChangesToIconSpacesAnimated:NO];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	if ([specifier isEqual:_spacesRowSpecifier]) {
		HSWidgetSize newWidgetSize = self.widgetViewController.widgetFrame.size;

		// expand the number of rows of the widget
		newWidgetSize.numRows = value != nil ? [(NSNumber *)value unsignedIntegerValue] : HSTodayWidgetMinNumRows;
		[self.widgetViewController updateForExpandOrShrinkToWidgetSize:newWidgetSize];

		// update maximum rows/columns
		[self _updateSpecifiersForChangesToIconSpacesAnimated:YES];
	} else if ([specifier isEqual:_spacesColSpecifier]) {
		HSWidgetSize newWidgetSize = self.widgetViewController.widgetFrame.size;

		// expand the number of cols of the widget
		newWidgetSize.numCols = value != nil ? [(NSNumber *)value unsignedIntegerValue] : HSTodayWidgetMinNumCols;
		[self.widgetViewController updateForExpandOrShrinkToWidgetSize:newWidgetSize];

		// update maximum rows/columns
		[self _updateSpecifiersForChangesToIconSpacesAnimated:YES];
	} else {
		[super setPreferenceValue:value specifier:specifier];

		if ([specifier isEqual:_pickerSpecifier]) {
			[self _updateSpecifiersForChangesToWidthStyleAnimated:YES];
		}
	}
}

-(id)readPreferenceValue:(PSSpecifier *)specifier {
	if ([specifier isEqual:_spacesRowSpecifier]) {
		return @(self.widgetViewController.widgetFrame.size.numRows);
	} else if ([specifier isEqual:_spacesColSpecifier]) {
		return @(self.widgetViewController.widgetFrame.size.numCols);
	} else {
		return [super readPreferenceValue:specifier];
	}
}

-(void)_updateSpecifiersForChangesToWidthStyleAnimated:(BOOL)animated {
	WidthStyle widthStype = (WidthStyle)[[self readPreferenceValue:_pickerSpecifier] unsignedIntegerValue];
	if (widthStype == WidthStyleAuto || widthStype == WidthStyleFillSpace) {
		// update the description for the picker
		[_descriptorSpecifier setProperty:PICKER_DESCRIPTION forKey:@"footerText"];
		[self reloadSpecifier:_descriptorSpecifier animated:animated];

		if ([self containsSpecifier:_widthSpecifier]) {
			[self removeSpecifier:_widthSpecifier animated:animated];
		}
	} else if (widthStype == WidthStyleCustom) {
		// update the description for custom width
		[_descriptorSpecifier setProperty:CUSTOM_WIDTH_DESCRIPTION forKey:@"footerText"];
		[self reloadSpecifier:_descriptorSpecifier animated:animated];

		if (![self containsSpecifier:_widthSpecifier]) {
			[self insertSpecifier:_widthSpecifier afterSpecifier:_pickerSpecifier];
		}
	}
}

-(void)_updateSpecifiersForChangesToIconSpacesAnimated:(BOOL)animated {
	// update maximum rows
	NSUInteger currentMaximumRows = self.widgetViewController.widgetFrame.size.numRows;
	HSWidgetSize expandRowSize = HSWidgetSizeMake(currentMaximumRows, self.widgetViewController.widgetFrame.size.numCols);
	while ([self.widgetViewController containsSpaceToExpandOrShrinkToWidgetSize:expandRowSize]) {
		currentMaximumRows = expandRowSize.numRows;
		++expandRowSize.numRows;
	}

	// update the rows specifier to the new maximum
	[_spacesRowSpecifier setProperty:@(currentMaximumRows) forKey:PSControlMaximumKey];
	[self reloadSpecifier:_spacesRowSpecifier animated:animated];

	// update maximum columns
	NSUInteger currentMaximumCols = self.widgetViewController.widgetFrame.size.numCols;
	HSWidgetSize expandColSize = HSWidgetSizeMake(self.widgetViewController.widgetFrame.size.numRows, currentMaximumCols);
	while ([self.widgetViewController containsSpaceToExpandOrShrinkToWidgetSize:expandColSize]) {
		currentMaximumCols = expandColSize.numCols;
		++expandColSize.numCols;
	}

	// update the cols specifier to the new maximum
	[_spacesColSpecifier setProperty:@(currentMaximumCols) forKey:PSControlMaximumKey];
	[self reloadSpecifier:_spacesColSpecifier animated:animated];
}

-(void)_setupNavigationTitle {
	if ([self.widgetViewController isKindOfClass:[HSTodayWidgetViewController class]]) {
		HSTodayWidgetViewController *todayWidgetViewController = (HSTodayWidgetViewController *)self.widgetViewController;
		self.navigationItem.title = todayWidgetViewController.hostingViewController.widgetInfo.displayName;
	}
}

-(void)_setupSpecifiersForWidthStyle {
	_descriptorSpecifier = [[self specifierForID:WIDTH_STYLE_DESCRIPTER_ID] retain];
	_pickerSpecifier = [[self specifierForID:WIDTH_STYLE_PICKER_ID] retain];
	_widthSpecifier = [[self specifierForID:CUSTOM_WIDTH_ID] retain];
}

-(void)_setupSpecifiersForIconSpaces {
	_spacesRowSpecifier = [[self specifierForID:SPACES_ROW_STEPPER_ID] retain];
	_spacesColSpecifier = [[self specifierForID:SPACES_COL_STEPPER_ID] retain];
}

-(void)_clearSpecifiersForWidthStyle {
	[_descriptorSpecifier release];
	_descriptorSpecifier = nil;

	[_pickerSpecifier release];
	_pickerSpecifier = nil;

	[_widthSpecifier release];
	_widthSpecifier = nil;
}

-(void)_clearSpecifiersForIconSpaces {
	[_spacesRowSpecifier release];
	_spacesRowSpecifier = nil;

	[_spacesColSpecifier release];
	_spacesColSpecifier = nil;	
}

-(void)dealloc {
	[self _clearSpecifiersForWidthStyle];
	[self _clearSpecifiersForIconSpaces];

	[super dealloc];
}
@end