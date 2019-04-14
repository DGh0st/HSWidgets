#import "HSAdditionalOptionsViewController.h"

@implementation HSAdditionalOptionsViewController
-(id)initWithDelegate:(id<HSAddWidgetAdditionalOptionsDelegate>)delegate withWidgetsOptionsToExclude:(NSArray *)optionsToExclude {
	self = [super init];
	if (self != nil)
		self.delegate = delegate;
	return self;
}

-(void)_setWidgetClass:(Class)widgetClass {
	_widgetClass = widgetClass;
}

-(void)viewDidLoad {
	[super viewDidLoad];

	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(addWidget)];
	self.navigationItem.rightBarButtonItems = @[doneButton];
	[doneButton release];
}

-(void)cancelWidget {
	// perform actions when additional options is cancelled
	if (self.delegate != nil)
		[self.delegate _dismissAddWidget];
}

-(void)addWidget {
	// perform actions when additional options is added/done
	if (self.delegate != nil)
		[self.delegate _addWidgetForClass:_widgetClass withAdditionalOptionsViewContorller:self];
}
@end