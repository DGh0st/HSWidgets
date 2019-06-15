#import "HSAddWidgetRootViewController.h"
#import "HSWidgetViewController.h"

@implementation HSAddWidgetRootViewController
-(void)viewDidLoad {
	[super viewDidLoad];

	@autoreleasepool { // only need it for colors
		// set the title for back button and make it invisible for current view controller
		self.navigationItem.title = @"HSWidgets";
		UIView *invisibleTitleView = [[UIView alloc] init];
		invisibleTitleView.hidden = YES;
		self.navigationItem.titleView = invisibleTitleView;
		[invisibleTitleView release];

		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_dismissAddWidget)];
		self.navigationItem.rightBarButtonItems = @[cancelButton];
		[cancelButton release];

		// title/section name label
		UILabel *sectionName = [[UILabel alloc] initWithFrame:(CGRect){{32.0f, 24.0f}, {self.view.frame.size.width - 64.0f, 0}}];
		sectionName.text = @"Add HSWidgets"; // totally isn't copied from apple's add widgets description
		sectionName.font = [UIFont systemFontOfSize:28];
		sectionName.numberOfLines = 1;
		sectionName.adjustsFontSizeToFitWidth = YES;
		sectionName.clipsToBounds = YES;
		sectionName.backgroundColor = [UIColor clearColor];
		sectionName.textColor = [UIColor blackColor];
		sectionName.textAlignment = NSTextAlignmentCenter;
		[sectionName sizeToFit];

		// fix size
		CGRect frame = sectionName.frame;
		frame.size.width = self.view.frame.size.width - 64.0f;
		sectionName.frame = frame;

		// subtitle/section description label
		UILabel *sectionDescription = [[UILabel alloc] initWithFrame:(CGRect){{32.0f, sectionName.frame.origin.y + sectionName.frame.size.height + 8.0f}, {self.view.frame.size.width - 64.0f, 0}}];
		sectionDescription.text = @"Get timely information from your favorite apps, on your homescreen. Select your HSWidget below."; // totally isn't copied from apple's add widgets description
		sectionDescription.font = [UIFont systemFontOfSize:18];
		sectionDescription.numberOfLines = 3;
		sectionDescription.adjustsFontSizeToFitWidth = YES;
		sectionDescription.clipsToBounds = YES;
		sectionDescription.backgroundColor = [UIColor clearColor];
		sectionDescription.textColor = [UIColor blackColor];
		sectionDescription.textAlignment = NSTextAlignmentCenter;
		[sectionDescription sizeToFit];

		// header view
		UIView *headerView = [[UIView alloc] initWithFrame:(CGRect){{0, 0}, {self.view.frame.size.width, 24.0f + sectionName.frame.size.height + 8.0f + sectionDescription.frame.size.height}}];
		headerView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[headerView addSubview:sectionName];
		[headerView addSubview:sectionDescription];

		self.tableView.tableHeaderView = headerView;

		[sectionName release];
		[sectionDescription release];
		[headerView release];
	}
}

-(void)_dismissAddWidget {
	if (self.addWidgetSelectionDelegate != nil)
		[self.addWidgetSelectionDelegate _cancelAddWidgetWithCompletion];
}

-(void)_addWidgetForClass:(Class)widgetClass withAdditionalOptionsViewContorller:(id)additionalOptionsViewController {
	if (self.addWidgetSelectionDelegate != nil) {
		NSDictionary *optionsDictionary = [widgetClass createOptionsFromController:additionalOptionsViewController];
		[self.addWidgetSelectionDelegate addWidgetOfClass:widgetClass forAvailableSpace:self.availableSpace withOptions:optionsDictionary];
	}
}

-(void)updateAvailableWidgetsForExclusions {
	NSMutableArray *filteredAvailableWidgetClasses = [NSMutableArray array];
	if (self.availableWidgetClasses == nil || self.availableWidgetClasses.count == 0) {
		self.availableWidgetClasses = [self.addWidgetSelectionDelegate updatedAvailableClassesForController:self];
		if (self.availableWidgetClasses.count == 0) // if it is still 0 then there is not enough space available so dismiss
			[self.addWidgetSelectionDelegate _cancelAddWidgetWithCompletion];
	}
	for (Class widgetClass in self.availableWidgetClasses) {
		if ([widgetClass allowedInstancesPerPage] == -1) { // unlimited instances allowed or filtered via additional options which is managed by the additional options subclass
			[filteredAvailableWidgetClasses addObject:widgetClass];
		} else {
			NSArray *widgetsForCurrentClass = [self.widgetsToExclude objectForKey:NSStringFromClass(widgetClass)];
			if (widgetsForCurrentClass == nil || [widgetsForCurrentClass count] < [widgetClass allowedInstancesPerPage])
				[filteredAvailableWidgetClasses addObject:widgetClass];
		}
	}
	self.availableWidgetClasses = filteredAvailableWidgetClasses;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.availableWidgetClasses count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *reusableCellIdentifier = @"HSAddWidgetClassesCell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellIdentifier];
	if (cell == nil)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reusableCellIdentifier] autorelease];

	Class widgetClass = [self.availableWidgetClasses objectAtIndex:indexPath.row];
	cell.textLabel.text = [widgetClass displayName];
	cell.imageView.image = [widgetClass icon];
	if ([widgetClass addNewWidgetAdditionalOptionsClass] != nil)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Class widgetClass = [self.availableWidgetClasses objectAtIndex:indexPath.row];
	Class additionalOptionsClass = [widgetClass addNewWidgetAdditionalOptionsClass];
	if (additionalOptionsClass != nil) {
		if ([additionalOptionsClass isSubclassOfClass:[HSAdditionalOptionsViewController class]]) {
			NSArray *currentOptionsToExclude = [self.widgetsToExclude objectForKey:NSStringFromClass(widgetClass)];
			HSAdditionalOptionsViewController *additionalOptionsViewController = [[additionalOptionsClass alloc] initWithDelegate:self withWidgetsOptionsToExclude:currentOptionsToExclude];
			[additionalOptionsViewController _setWidgetClass:widgetClass];
			[self.navigationController pushViewController:additionalOptionsViewController animated:YES];
			[additionalOptionsViewController release];
		} else {
			@throw [NSException exceptionWithName:@"HSWidgetsInvalidAdditionalOptionsClassException" reason:@"Additional Options Class must be a subclass of HSAdditionalOptionsViewController" userInfo:nil];
		}
	} else {
		[self _addWidgetForClass:widgetClass withAdditionalOptionsViewContorller:nil];
	}
}
@end