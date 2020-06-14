#define HSWidgetAddMinimumHeaderHeight 100

__attribute__((visibility("hidden")))
@interface HSWidgetHeaderTableView : UITableViewHeaderFooterView
@property (nonatomic, retain) UILabel *sectionName;
@property (nonatomic, retain) UILabel *sectionDescription;
@end
