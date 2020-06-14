#import "HSWidgets-structs.h"

@protocol HSAddWidgetSelectionDelegate
@required
-(void)cancelAddWidgetAnimated:(BOOL)animated;
-(void)addWidgetOfClass:(Class)widgetClass withWidgetFrame:(HSWidgetFrame)widgetFrame options:(NSDictionary *)options;
-(HSWidgetPosition)widgetOriginForWidgetSize:(HSWidgetSize)size withPreferredOrigin:(HSWidgetPosition)position;
@end
