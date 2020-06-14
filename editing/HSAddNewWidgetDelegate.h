#import "HSWidgets-core.h"

@protocol HSAddNewWidgetDelegate
@required
-(CGRect)rectForWidgetPosition:(HSWidgetPosition)position;
-(void)addNewWidgetTappedForPosition:(HSWidgetPosition)position;
@end
