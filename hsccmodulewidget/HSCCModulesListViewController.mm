#import "HSCCModulesListViewController.h"
#import "HSCCModuleController.h"
#import "CCUILayoutSize.h"
#import "CCUIModuleSettings.h"

#import <HSWidgets/HSWidgetSizeObject.h>

@implementation HSCCModulesListViewController
-(instancetype)initWithWidgetsOptionsToExclude:(NSArray *)optionsToExclude withDelegate:(id<HSWidgetAddNewAdditionalOptionsDelegate>)delegate availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	self = [super initWithWidgetsOptionsToExclude:optionsToExclude withDelegate:delegate availablePositions:positions];
	if (self != nil) {
		HSCCModuleController *moduleController = [HSCCModuleController sharedInstance];
		NSSet *identifiers = [moduleController loadableModuleIdentifiers];
		
		_moduleInfos = [[NSMutableArray alloc] initWithCapacity:identifiers.count];
		for (NSString *identifier in identifiers) {
			CCUIModuleSettings *settings = [moduleController moduleSettingForIdentifier:identifier];
			CCUILayoutSize portraitSize = [settings layoutSizeForInterfaceOrientation:UIInterfaceOrientationPortrait];
			CCUILayoutSize landscapeSize =[settings layoutSizeForInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
			HSWidgetSize widgetSize = HSWidgetSizeMake(MAX(portraitSize.height, landscapeSize.height), MAX(portraitSize.width, landscapeSize.width));
			if ([super containsSpaceForWidgetSize:widgetSize]) {
				[_moduleInfos addObject:@{
					@"identifier" : identifier,
					@"widgetSize" : [HSWidgetSizeObject objectWithWidgetSize:widgetSize]
				}];
			}
		}
	}
	return self;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_moduleInfos count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *const ReusableCellIdentifier = @"HSCustomCCModuleCell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReusableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReusableCellIdentifier] autorelease];
	}

	NSDictionary *moduleInfo = [_moduleInfos objectAtIndex:indexPath.row];
	cell.textLabel.text = moduleInfo[@"identifier"];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *moduleInfo = [_moduleInfos objectAtIndex:indexPath.row];
	self.widgetOptions[@"moduleIdentifier"] = moduleInfo[@"identifier"];
	self.requestWidgetSize = ((HSWidgetSizeObject *)moduleInfo[@"widgetSize"]).size;
	[self addWidget]; // this begins the dismiss animation so its better to do it at the end
}

-(void)dealloc {
	[_moduleInfos release];
	_moduleInfos = nil;

	[super dealloc];
}
@end