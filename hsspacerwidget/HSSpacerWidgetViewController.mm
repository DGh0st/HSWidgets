#import "HSSpacerWidgetViewController.h"

#import <algorithm>
#import <vector>

#define MIN_NUM_ROWS 1U // spacer needs atleast 1 row
#define MIN_NUM_COLS 1U // spacer needs atleast 1 col

@implementation HSSpacerWidgetViewController
+(HSWidgetSize)minimumSize {
	return HSWidgetSizeMake(MIN_NUM_ROWS, MIN_NUM_COLS); // least amount of rows and cols the widget needs
}

-(BOOL)_canExpand:(inout HSWidgetSize *)expandSize {
	std::vector<HSWidgetSize> expandSizes;
	expandSizes.push_back(HSWidgetSizeAdd(self.widgetFrame.size, 1, 1)); // expand row and col
	expandSizes.push_back(HSWidgetSizeAdd(self.widgetFrame.size, 0, 1)); // expand col
	expandSizes.push_back(HSWidgetSizeAdd(self.widgetFrame.size, 1, 0)); // expand row

	// sort by biggest to smalles spaces
	std::sort(expandSizes.begin(), expandSizes.end(), [](const HSWidgetSize &first, const HSWidgetSize &second) {
		return SpacesForWidgetSize(first) > SpacesForWidgetSize(second);
	});

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
@end