#import "HSWidgetCombinedAdditionalOptionsAndPreferencesViewController.h"
#import "HSWidgetAvailablePositionObject.h"
#import "HSWidgetViewController.h"

#define ADD_NAVIGATION_ITEM_TITLE @"Add"

@interface HSWidgetPreferencesListController ()
-(void)_postNotificationForSpecifierIfProvided:(PSSpecifier *)specifier;
@end

@implementation HSWidgetCombinedAdditionalOptionsAndPreferencesViewController
-(instancetype)initWithWidgetsOptionsToExclude:(NSArray *)optionsToExclude withDelegate:(id<HSWidgetAddNewAdditionalOptionsDelegate>)delegate availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	self = [super initWithWidgetViewController:nil availablePositions:positions];
	if (self != nil) {
		self.delegate = delegate;
		self.widgetClass = nil;
		self.widgetOptions = [NSMutableDictionary dictionary];
	}
	return self;
}

-(instancetype)initWithWidgetViewController:(HSWidgetViewController *)widgetViewController availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	self = [super initWithWidgetViewController:widgetViewController availablePositions:positions];
	if (self != nil) {
		self.delegate = nil;
		self.widgetClass = nil;
		self.widgetOptions = nil;
	}
	return self;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	BOOL isPresentedAsAdditionalOptionsViewController = self.widgetViewController == nil;

	if (isPresentedAsAdditionalOptionsViewController && [self respondsToSelector:@selector(table)]) {
		// hide the scroll indicators when we are beign presented as additional options view controller
		UITableView *tableView = [self table];
		[tableView setShowsHorizontalScrollIndicator:NO];
		[tableView setShowsVerticalScrollIndicator:NO];
	}

	if ([self.widgetClass isSubclassOfClass:[HSWidgetViewController class]]) {
		self.navigationItem.title = [self.widgetClass widgetDisplayInfo][HSWidgetDisplayNameKey];
	}

	if (isPresentedAsAdditionalOptionsViewController) {
		// add "add" button
		UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:ADD_NAVIGATION_ITEM_TITLE style:UIBarButtonItemStyleDone target:self action:@selector(addWidget)];
		self.navigationItem.rightBarButtonItems = @[addButton];
		[addButton release];
	}
}

-(void)resetAllSettings {
	if (self.widgetViewController != nil) {
		// if widget view controller is set then we are being presented as preferences view controller
		[super resetAllSettings];
	} else {
		for (PSSpecifier *specifier in [self specifiers]) {
			NSString *key = specifier.properties[PSKeyNameKey];
			if (key != nil) {
				[self.widgetOptions removeObjectForKey:key];
				[self _postNotificationForSpecifierIfProvided:specifier];
			}
		}

		[self reloadSpecifiers];
	}
}

-(id)readPreferenceValue:(PSSpecifier *)specifier {
	if (self.widgetViewController != nil) {
		// if widget view controller is set then we are being presented as preferences view controller
		return [super readPreferenceValue:specifier];
	} else {
		return self.widgetOptions[specifier.properties[PSKeyNameKey]] ?: specifier.properties[PSDefaultValueKey];
	}
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	if (self.widgetViewController != nil) {
		// if widget view controller is set then we are being presented as preferences view controller
		[super setPreferenceValue:value specifier:specifier];
	} else {
		NSString *key = specifier.properties[PSKeyNameKey];
		if (key != nil) {
			[self.widgetOptions setObject:value forKey:key];
			[self _postNotificationForSpecifierIfProvided:specifier];
		}
	}
}

-(void)cancelAdditionalOptions {
	// perform actions when additional options is cancelled
	[self.delegate dismissAddWidget];
}

-(void)addWidget {
	// perform actions when additional options is added/done
	[self.delegate additionalOptionsViewController:self addWidgetForClass:self.widgetClass];
}

-(void)dealloc {
	self.delegate = nil;
	self.widgetClass = nil;
	self.widgetOptions = nil;

	[super dealloc];
}
@end