#import "HSAddWidgetRootViewController.h"
#import "HSWidgetBezierShapeDisclosureTableViewCell.h"
#import "HSWidgetBezierShapeSelectorViewController.h"
#import "HSWidgetHeaderTableView.h"
#import "HSWidgetSubtitleTableViewCell.h"
#import "HSWidgetViewController.h"

#define REUSABLE_HEADER_IDENTIFIER @"HSAddWidgetHeader"
#define REUSABLE_BEZIER_SHAPE_IDENTIIFER @"HSWidgetAddBezierShapeCell"
#define REUSABLE_WIDGET_CELL_IDENTIFIER @"HSAddWidgetClassesCell"
#define REUSABLE_WIDGET_DISABLED_CELL_IDENTIFIER @"HSAddWidgetInsufficientSpaceClassesCell"
#define NAVIGATION_TITLE @"HSWidgets"
// totally isn't copied from apple's add widgets description
#define ADD_WIDGETS_TITLE @"Add HSWidgets"
#define ADD_WIDGETS_DESCRIPTION @"Get timely information from your favorite apps, on your homescreen. Select your HSWidget below."
#define BEZIER_SHAPE_TITLE @"Placeholder Shape"
#define BEZIER_SHAPE_DESCRIPTION @"Select the shape that is used in place of available icon positions"
#define MORE_WIDGETS_TITLE @"More Widgets"
#define INSUFFICIENT_TITLE @"Disabled Widgets (Insufficient space)"

#define COMMON_SECTION 0
#define MORE_SECTION 1
#define INSUFFICIENT_SPACE_SECTION 2
#define TOTAL_SECTIONS 3 // make sure to update this when adding more sections

@interface UINavigationBar ()
-(void)_setShadowAlpha:(CGFloat)arg1; // iOS 8 - 13
@end

@interface HSAddWidgetRootViewController ()
@property (nonatomic, retain, setter=_setAvailableWidgetClasses:) NSArray *_availableWidgetClasses;
@property (nonatomic, retain, setter=_setInsufficientSpaceWidgets:) NSArray *_insufficientSpaceClasses;
@property (nonatomic, retain, setter=_setExcludeWidgetsWithOptions:) NSDictionary *_excludeWidgetsWithOptions;
@end

@implementation HSAddWidgetRootViewController
-(instancetype)initWithWidgets:(NSArray *)availableClasses insufficientSpaceWidgets:(NSArray *)insufficientSpaceClasses excludingWidgetsOptions:(NSDictionary *)excludes {
	BOOL isAtLeastiOS13 = [[[UIDevice currentDevice] systemVersion] compare:@"13.0" options:NSNumericSearch] == NSOrderedDescending;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
	self = [super initWithStyle:isAtLeastiOS13 ? UITableViewStyleInsetGrouped : UITableViewStyleGrouped];
#pragma clang diagnostic pop
	if (self != nil) {
		_delegate = nil;
		self.preferredPosition = HSWidgetPositionZero;
		self.availablePositions = nil;

		// filter available classes
		NSMutableArray *filteredAvailableWidgetClasses = [NSMutableArray array];
		for (Class widgetClass in availableClasses) {
			if ([widgetClass allowedInstancesPerPage] == -1) { // unlimited instances allowed or filtered via additional options
				[filteredAvailableWidgetClasses addObject:widgetClass];
			} else {
				NSArray *widgetsForCurrentClass = [excludes objectForKey:NSStringFromClass(widgetClass)];
				if (widgetsForCurrentClass == nil || widgetsForCurrentClass.count < [widgetClass allowedInstancesPerPage]) {
					[filteredAvailableWidgetClasses addObject:widgetClass];
				}
			}
		}

		self._availableWidgetClasses = filteredAvailableWidgetClasses;
		self._insufficientSpaceClasses = insufficientSpaceClasses;
		self._excludeWidgetsWithOptions = excludes;
	}
	return self;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	@autoreleasepool {
		// set the title for back button of next page
		self.navigationItem.title = NAVIGATION_TITLE;
		
		// remove navigation bar shadow
		[self _updateNavigationbarShadow:NO];

		// make title invisible for current view controller
		UIView *invisibleTitleView = [[UIView alloc] init];
		invisibleTitleView.hidden = YES;
		self.navigationItem.titleView = invisibleTitleView;
		[invisibleTitleView release];

		// add cancel button
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissAddWidget)];
		self.navigationItem.rightBarButtonItems = @[cancelButton];
		[cancelButton release];

		// hide scroll indicator
		[self.tableView setShowsHorizontalScrollIndicator:NO];
		[self.tableView setShowsVerticalScrollIndicator:NO];

		// setup editing mode
		[self.tableView setEditing:YES animated:NO];
		self.tableView.allowsSelectionDuringEditing = YES;

		[self.tableView registerClass:[HSWidgetHeaderTableView class] forHeaderFooterViewReuseIdentifier:REUSABLE_HEADER_IDENTIFIER];
		[self.tableView registerClass:[HSWidgetBezierShapeDisclosureTableViewCell class] forCellReuseIdentifier:REUSABLE_BEZIER_SHAPE_IDENTIIFER];
		[self.tableView registerClass:[HSWidgetSubtitleTableViewCell class] forCellReuseIdentifier:REUSABLE_WIDGET_CELL_IDENTIFIER];
		[self.tableView registerClass:[HSWidgetSubtitleTableViewCell class] forCellReuseIdentifier:REUSABLE_WIDGET_DISABLED_CELL_IDENTIFIER];
	}
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// update navigation bar shadow based on scroll position
	[self _updateNavigationbarShadow:NO];
}

-(void)viewWillDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	// force show navigation bar shadow
	[self _updateNavigationbarShadow:YES];
}

-(void)_updateNavigationbarShadow:(BOOL)forceShow {
	CGFloat scrollOffsetY = self.tableView.contentOffset.y / 32.0;
	if (forceShow)
		scrollOffsetY = 1.0;
	if (scrollOffsetY < 0.0)
		scrollOffsetY = 0.0;
	else if (scrollOffsetY > 1.0)
		scrollOffsetY = 1.0;
	[self.navigationController.navigationBar _setShadowAlpha:scrollOffsetY];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self _updateNavigationbarShadow:NO];
}

-(void)setDelegate:(id<HSAddWidgetSelectionDelegate>)delegate {
	_delegate = delegate;
}

-(void)dismissAddWidget {
	[_delegate cancelAddWidgetAnimated:YES];
}

-(void)additionalOptionsViewController:(id<HSWidgetAdditionalOptions>)additionalOptionsViewController addWidgetForClass:(Class)widgetClass {
	NSDictionary *options = [widgetClass createOptionsFromController:additionalOptionsViewController withAvailableGridPosition:self.availablePositions];
	HSWidgetSize size = [widgetClass minimumSize];
	HSWidgetPosition position = [_delegate widgetOriginForWidgetSize:size withPreferredOrigin:self.preferredPosition];
	HSWidgetFrame widgetFrame = HSWidgetFrameMake(position, size);
	NSMutableArray<HSWidgetPositionObject *> *widgetPositions = [HSWidgetGridPositionConverterCache gridPositionsForWidgetFrame:widgetFrame];

	// check widget can fit at preferred position and find new origin position if it can't
	if (![HSWidgetGridPositionConverterCache canFitWidget:widgetPositions inGridPositions:self.availablePositions]) {
		widgetFrame.origin = [HSWidgetGridPositionConverterCache originForWidgetOfSize:widgetFrame.size inGridPositions:self.availablePositions];
	}

	// add widget with the new widget frame with options
	[_delegate addWidgetOfClass:widgetClass withWidgetFrame:widgetFrame options:options];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self._insufficientSpaceClasses.count > 0 ? TOTAL_SECTIONS : TOTAL_SECTIONS - 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == COMMON_SECTION)
		return 1;
	else if (section == MORE_SECTION)
		return self._availableWidgetClasses.count;
	else if (section == INSUFFICIENT_SPACE_SECTION)
		return self._insufficientSpaceClasses.count;
	return 0;
}

-(HSWidgetHeaderTableView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	HSWidgetHeaderTableView *headerView = nil;
	if (section == COMMON_SECTION) {
		headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:REUSABLE_HEADER_IDENTIFIER];
		headerView.sectionName.text = ADD_WIDGETS_TITLE;
		headerView.sectionDescription.text = ADD_WIDGETS_DESCRIPTION;
	}
	return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
	if (section == COMMON_SECTION)
		return HSWidgetAddMinimumHeaderHeight;
	return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == MORE_SECTION)
		return MORE_WIDGETS_TITLE;
	else if (section == INSUFFICIENT_SPACE_SECTION)
		return INSUFFICIENT_TITLE;
	return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UITableViewAutomaticDimension;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == MORE_SECTION)
		return YES;
	return NO;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == MORE_SECTION)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleNone;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	if (indexPath.section == COMMON_SECTION) {
		HSWidgetBezierShapeDisclosureTableViewCell *disclosureTableViewCell = [tableView dequeueReusableCellWithIdentifier:REUSABLE_BEZIER_SHAPE_IDENTIIFER forIndexPath:indexPath];
		disclosureTableViewCell.headlineLabel.text = BEZIER_SHAPE_TITLE;
		disclosureTableViewCell.descriptionLabel.text = BEZIER_SHAPE_DESCRIPTION;
		cell = disclosureTableViewCell;
	} else if (indexPath.section == MORE_SECTION) {
		cell = [tableView dequeueReusableCellWithIdentifier:REUSABLE_WIDGET_CELL_IDENTIFIER forIndexPath:indexPath];
		Class widgetClass = [self._availableWidgetClasses objectAtIndex:indexPath.row];
		NSDictionary *widgetDisplayInfo = [widgetClass widgetDisplayInfo];
		cell.textLabel.text = widgetDisplayInfo[HSWidgetDisplayNameKey];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"By %@", widgetDisplayInfo[HSWidgetDisplayCreatorKey]];
		cell.imageView.image = widgetDisplayInfo[HSWidgetDisplayIconKey];
		if ([widgetClass addNewWidgetAdditionalOptionsControllerClass] != nil) {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
		}
	} else if (indexPath.section == INSUFFICIENT_SPACE_SECTION) {
		cell = [tableView dequeueReusableCellWithIdentifier:REUSABLE_WIDGET_DISABLED_CELL_IDENTIFIER forIndexPath:indexPath];
		Class widgetClass = [self._insufficientSpaceClasses objectAtIndex:indexPath.row];
		NSDictionary *widgetDisplayInfo = [widgetClass widgetDisplayInfo];
		cell.textLabel.text = widgetDisplayInfo[HSWidgetDisplayNameKey];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"By %@", widgetDisplayInfo[HSWidgetDisplayCreatorKey]];
		cell.imageView.image = widgetDisplayInfo[HSWidgetDisplayIconKey];
		if ([widgetClass addNewWidgetAdditionalOptionsControllerClass] != nil) {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.contentView.alpha = 0.5;
		cell.userInteractionEnabled = NO;
	}
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == COMMON_SECTION) {
		HSWidgetBezierShapeSelectorViewController *shapeSelectorViewController = [[HSWidgetBezierShapeSelectorViewController alloc] initWithDelegate:self];
		[self.navigationController pushViewController:shapeSelectorViewController animated:YES];
		[shapeSelectorViewController release];
	} else if (indexPath.section == MORE_SECTION) {
		Class widgetClass = [self._availableWidgetClasses objectAtIndex:indexPath.row];
		Class additionalOptionsClass = [widgetClass addNewWidgetAdditionalOptionsControllerClass];
		if (additionalOptionsClass != nil) {
			// makes sure the additional options controller confirms to the HSWidgetAdditionalOptions protocol
			if (![additionalOptionsClass conformsToProtocol:@protocol(HSWidgetAdditionalOptions)]) {
				NSString *reason = [NSString stringWithFormat:@"Additional Options Class (%@) must conform to HSWidgetAdditionalOptions protocol", additionalOptionsClass];
				@throw [NSException exceptionWithName:@"HSWidgetsInvalidAdditionalOptionsClassException" reason:reason userInfo:@{
					@"WidgetClass" : widgetClass,
					@"AdditionalOptionsClass" : additionalOptionsClass
				}];
			}
			
			// make sure the additional options controller is a view controller
			if (![additionalOptionsClass isSubclassOfClass:[UIViewController class]]) {
				NSString *reason = [NSString stringWithFormat:@"Additional Options Class (%@) must be a subclass of UIViewController", additionalOptionsClass];
				@throw [NSException exceptionWithName:@"HSWidgetsInvalidAdditionalOptionsClassException" reason:reason userInfo:@{
					@"WidgetClass" : widgetClass,
					@"AdditionalOptionsClass" : additionalOptionsClass
				}];
			}

			// create the additional options view controller
			UIViewController<HSWidgetAdditionalOptions> *additionalOptionsViewController = [additionalOptionsClass alloc];
			if ([additionalOptionsViewController respondsToSelector:@selector(initWithWidgetsOptionsToExclude:withDelegate:availablePositions:)]) {
				NSArray *optionsToExclude = [self._excludeWidgetsWithOptions objectForKey:NSStringFromClass(widgetClass)];
				additionalOptionsViewController = [additionalOptionsViewController initWithWidgetsOptionsToExclude:optionsToExclude withDelegate:self availablePositions:self.availablePositions];
			} else if ([additionalOptionsViewController respondsToSelector:@selector(initForContentSize:)]) {
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wobjc-method-access"
				additionalOptionsViewController = [additionalOptionsViewController initForContentSize:self.navigationController.view.bounds.size];
	#pragma clang diagnostic pop
			} else {
				additionalOptionsViewController = [additionalOptionsViewController init];
			}
			additionalOptionsViewController.widgetClass = widgetClass;
			additionalOptionsViewController.delegate = self;

			[self.navigationController pushViewController:additionalOptionsViewController animated:YES];

			// add cancel button if there isn't a right bar button already
			if (additionalOptionsViewController.navigationItem.rightBarButtonItems.count == 0) {
				UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissAddWidget)];
				additionalOptionsViewController.navigationItem.rightBarButtonItems = @[cancelButton];
				[cancelButton release];
			}
			
			[additionalOptionsViewController release];
		} else {
			[self additionalOptionsViewController:nil addWidgetForClass:widgetClass];
		}
	} else if (indexPath.section == INSUFFICIENT_SPACE_SECTION) {
		// do nothing (something went wrong if this happens)
	}
}

-(void)dealloc {
	_delegate = nil;
	self.availablePositions = nil;
	self._availableWidgetClasses = nil;
	self._excludeWidgetsWithOptions = nil;

	[super dealloc];
}
@end
