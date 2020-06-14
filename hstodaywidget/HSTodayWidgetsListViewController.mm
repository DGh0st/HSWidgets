#import "HSTodayWidgetsListViewController.h"
#import "HSTodayWidgetController.h"
#import "NSExtension.h"
#import "WGWidgetDiscoveryController.h"
#import "WGWidgetInfo.h"

@interface UIImage ()
+(id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2; // iOS 12 - 13
@end

static UIImage *CreateEmptyImageWithSize(CGSize size) {
	UIGraphicsBeginImageContext(size);
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

@implementation HSTodayWidgetsListViewController
-(instancetype)initWithWidgetsOptionsToExclude:(NSArray *)optionsToExclude withDelegate:(id<HSWidgetAddNewAdditionalOptionsDelegate>)delegate availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	self = [super initWithWidgetsOptionsToExclude:optionsToExclude withDelegate:delegate availablePositions:positions];
	if (self != nil) {
		NSDictionary *_identifiersToWidgetInfos = [[HSTodayWidgetController sharedInstance] availableWidgetIdentifiersToWidgetInfos];
		NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
		if (_identifiersToWidgetInfos != nil) {
			_widgetInfos = [[[_identifiersToWidgetInfos allValues] sortedArrayUsingDescriptors:@[sort]] retain];
		} else {
			_widgetInfos = [[NSArray alloc] init];
		}
	}
	return self;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_widgetInfos count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *const ReusableCellIdentifier = @"HSCustomTodayWidgetsCell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReusableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReusableCellIdentifier] autorelease];
	}

	WGWidgetInfo *widgetInfo = [_widgetInfos objectAtIndex:indexPath.row];
	if ([widgetInfo respondsToSelector:@selector(_icon)]) {
		if ([widgetInfo _icon] != nil) {
			cell.imageView.image = [widgetInfo _icon];
		} else if ([widgetInfo _outlineIcon] != nil) {
			cell.imageView.image = [widgetInfo _outlineIcon];
		} else {
			if ([widgetInfo.extension respondsToSelector:@selector(_containingAppIdentifer)] && [UIImage respondsToSelector:@selector(_applicationIconImageForBundleIdentifier:format:)]) {
				UIImage *image = [UIImage _applicationIconImageForBundleIdentifier:[widgetInfo.extension _containingAppIdentifer] format:5];
				if (image == nil) {
					image = CreateEmptyImageWithSize(CGSizeMake(20, 20));
				}
				cell.imageView.image = image;
			}

			[widgetInfo requestSettingsIconWithHandler:^(UIImage *image) {
				dispatch_async(dispatch_get_main_queue(), ^{
					UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
					if (image != nil) {
						cell.imageView.image = image;
						cell.textLabel.text = widgetInfo.displayName;
					}
				});
			}];
		}
	} else {
		cell.imageView.image = [widgetInfo icon];
	}
	cell.textLabel.text = widgetInfo.displayName;
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	WGWidgetInfo *widgetInfo = [_widgetInfos objectAtIndex:indexPath.row];
	self.widgetOptions[@"widgetIdentifier"] = widgetInfo.widgetIdentifier;
	[self addWidget]; // this begins the dismiss animation so its better to do it at the end
}

-(void)dealloc {
	if (_widgetInfos != nil) {
		[_widgetInfos release];
		_widgetInfos = nil;
	}

	[super dealloc];
}
@end
