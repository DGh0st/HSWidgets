#import "HSAdditionalOptionsViewController.h"

@interface HSAdditionalOptionsTableViewController : HSAdditionalOptionsViewController <UITableViewDelegate, UITableViewDataSource> {
	UITableView *_tableView;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end