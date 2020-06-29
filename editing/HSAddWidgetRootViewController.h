#import "HSAddWidgetSelectionDelegate.h"
#import "HSWidgets-structs.h"
#import "HSWidgetAddNewAdditionalOptionsDelegate.h"

@class HSWidgetAvailablePositionObject;

__attribute__((visibility("hidden")))
@interface HSAddWidgetRootViewController : UITableViewController <HSWidgetAddNewAdditionalOptionsDelegate> {
@private
	id<HSAddWidgetSelectionDelegate> _delegate;
}
@property (nonatomic, assign) HSWidgetPosition preferredPosition;
@property (nonatomic, retain) NSArray<HSWidgetAvailablePositionObject *> *availablePositions;
-(instancetype)initWithWidgets:(NSArray *)availableClasses insufficientSpaceWidgets:(NSArray *)insufficientSpaceClasses excludingWidgetsOptions:(NSDictionary *)excludes;
-(void)setDelegate:(id<HSAddWidgetSelectionDelegate>)delegate;
@end
