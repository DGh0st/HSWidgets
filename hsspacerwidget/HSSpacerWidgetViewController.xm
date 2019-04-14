#import "HSSpacerWidgetViewController.h"

#define kMinNumRows 1 // spacer needs atleast 1 row
#define kDisplayName @"Empty Spacer"
#define kIconImageName @"HSSpacer"
#define kBundlePath @"/Library/Application Support/HSWidgets/Assets.bundle"

@implementation HSSpacerWidgetViewController
-(id)initForOriginRow:(NSUInteger)originRow withOptions:(NSDictionary *)options {
	self = [super initForOriginRow:originRow withOptions:options];
	if (self != nil)
		_numRows = options[@"NumRows"] ? [options[@"NumRows"] integerValue] : kMinNumRows;
	return self;
}

-(NSUInteger)numRows {
	return _numRows < kMinNumRows ? kMinNumRows : _numRows;
}

+(BOOL)canAddWidgetForAvailableRows:(NSUInteger)rows {
	return rows >= kMinNumRows; // least amount of rows needed
}

+(NSString *)displayName {
	return kDisplayName;
}

+(UIImage *)icon {
	return [UIImage imageNamed:kIconImageName inBundle:[NSBundle bundleWithPath:kBundlePath] compatibleWithTraitCollection:nil];
}

+(Class)addNewWidgetAdditionalOptionsClass {
	return nil; // we don't have any additional options for this so we don't want to display anything when add new widget selection is being displayed
}

+(NSDictionary *)createOptionsFromController:(id)controller {
	return @{
		@"NumRows" : @(kMinNumRows)
	};
}

+(NSInteger)allowedInstancesPerPage {
	return -1; // you can have unlimited spacers per page
}

-(CGRect)calculatedFrame {
	return (CGRect){{0, 0}, self.requestedSize};
}

-(BOOL)canExpandWidget {
	return [super availableRows] >= 1;
}

-(BOOL)canShrinkWidget {
	return _numRows > kMinNumRows;
}

-(void)expandBoxTapped {
	++_numRows;
	_options[@"NumRows"] = @(_numRows);

	[self updateForExpandOrShrinkFromRows:_numRows - 1];
}

-(void)shrinkBoxTapped {
	--_numRows;
	_options[@"NumRows"] = @(_numRows);

	[self updateForExpandOrShrinkFromRows:_numRows + 1];
}
@end