#import "HSAdditionalOptionsTableViewController.h"

@implementation HSAdditionalOptionsTableViewController
-(void)viewDidLoad {
	[super viewDidLoad];

	_tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.delegate = self;
	_tableView.dataSource = self;
	[self.view addSubview:_tableView];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1; // override this for more sections
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	@throw [NSException exceptionWithName:@"HSAdditionalOptionsTableViewControllerSubclassException" reason:@"subclasses of HSAdditionalOptionsTableViewController must override the required UITableViewDataSource method (tableView:numberOfRowsInSection:)" userInfo:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	@throw [NSException exceptionWithName:@"HSAdditionalOptionsTableViewControllerSubclassException" reason:@"subclasses of HSAdditionalOptionsTableViewController must override the required UITableViewDataSource method (tableView:cellForRowAtIndexPath:)" userInfo:nil];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self addWidget]; // make sure to call super at the end of your overriden method
}

-(void)dealloc {
	if (_tableView != nil)
		[_tableView release];

	[super dealloc];
}
@end