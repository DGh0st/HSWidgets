#import "HSWidgetBezierShapeSelectorViewController.h"
#import "HSAddNewWidgetPositionView.h"
#import "HSWidget-Availability.h"
#import "HSWidgetAddNewAdditionalOptionsDelegate.h"
#import "HSWidgetBezierShapeTableViewCell.h"
#import "HSWidgetResources.h"
#import "NSUserDefaults.h"

#define NAVIGATION_TITLE @"Placeholder Shape"
#define REUSABLE_CELL_IDENTIFIER @"HSWidgetBezierShapeReusableCell"

@implementation HSWidgetBezierShapeSelectorViewController
-(instancetype)initWithDelegate:(id<HSWidgetAddNewAdditionalOptionsDelegate>)delegate {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
	self = [super initWithStyle:isAtLeastiOS13() ? UITableViewStyleInsetGrouped : UITableViewStyleGrouped];
#pragma clang diagnostic pop
	if (self != nil) {
		_delegate = delegate;
		_bezierShapes = [[HSWidgetResources allBezierShapes] retain];

		// figure out selected bezier shape index
		NSNumber *selectedBezierShapeEnum = [[NSUserDefaults standardUserDefaults] objectForKey:HSWidgetBezierShapeKey inDomain:HSWidgetDomain];
		HSWidgetBezierShape selectedBezierShape = selectedBezierShapeEnum ? (HSWidgetBezierShape)[selectedBezierShapeEnum unsignedIntegerValue] : HSWidgetBezierShapeRoundedRect;
		selectedBezierShapeIndex = [_bezierShapes indexOfObjectPassingTest:^(NSDictionary *bezierShapeInfo, NSUInteger index, BOOL *stop) {
			return (BOOL)((HSWidgetBezierShape)[bezierShapeInfo[HSWidgetBezierShapeEnumKey] unsignedIntegerValue] == selectedBezierShape);
		}];
	}
	return self;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	@autoreleasepool {
		// set the title for back button of next page
		self.navigationItem.title = NAVIGATION_TITLE;

		// add done button
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelAddWidget)];
		self.navigationItem.rightBarButtonItems = @[doneButton];
		[doneButton release];

		self.tableView.allowsSelection = YES;
		self.tableView.allowsMultipleSelection = NO;

		// register cell class
		[self.tableView registerClass:[HSWidgetBezierShapeTableViewCell class] forCellReuseIdentifier:REUSABLE_CELL_IDENTIFIER];
	}
}

-(void)cancelAddWidget {
	// cancel widget addition
	[_delegate dismissAddWidget];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _bezierShapes.count;
}

-(HSWidgetBezierShapeTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *bezierShapeInfo = _bezierShapes[indexPath.row];
	HSWidgetBezierShapeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:REUSABLE_CELL_IDENTIFIER forIndexPath:indexPath];
	cell.nameLabel.text = bezierShapeInfo[HSWidgetBezierShapeDisplayNameKey];
	cell.bezierShape = (HSWidgetBezierShape)[bezierShapeInfo[HSWidgetBezierShapeEnumKey] unsignedIntegerValue];
	if (indexPath.row == selectedBezierShapeIndex) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// unhighlight the view
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	// update user defaults with the selected one
	NSDictionary *bezierShapeInfo = _bezierShapes[indexPath.row];
	[[NSUserDefaults standardUserDefaults] setObject:bezierShapeInfo[HSWidgetBezierShapeEnumKey] forKey:HSWidgetBezierShapeKey inDomain:HSWidgetDomain];
	[[NSNotificationCenter defaultCenter] postNotificationName:HSWidgetBezierShapeChangedNotification object:nil userInfo:nil];

	[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedBezierShapeIndex inSection:0]].accessoryType = UITableViewCellAccessoryNone;
	selectedBezierShapeIndex = indexPath.row;

	// add checkmark
	[self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedBezierShapeIndex inSection:0]].accessoryType = UITableViewCellAccessoryNone;
}

-(void)dealloc {
	_delegate = nil;

	[_bezierShapes release];
	_bezierShapes = nil;

	[super dealloc];
}
@end
