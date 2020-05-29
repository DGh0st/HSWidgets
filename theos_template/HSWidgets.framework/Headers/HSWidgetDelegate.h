#import "HSWidgets-structs.h"

@class HSWidgetViewController;

@protocol HSWidgetDelegate
@required
-(void)closeTapped:(HSWidgetViewController *)widgetViewController;
-(void)settingsTapped:(HSWidgetViewController *)widgetViewController;
-(void)widgetOptionsChanged:(HSWidgetViewController *)widgetViewController;
-(BOOL)canDragWidget:(HSWidgetViewController *)widgetViewController;
-(void)setDraggingWidget:(HSWidgetViewController *)widgetViewController;
-(void)widgetDragged:(HSWidgetViewController *)widgetViewController toPoint:(CGPoint)point;
-(BOOL)canWidget:(HSWidgetViewController *)widgetViewController expandOrShrinkToGridPositions:(NSArray<HSWidgetPositionObject *> *)positions;
-(void)updatePageForExpandOrShrinkOfWidget:(HSWidgetViewController *)widgetViewController toGridPositions:(NSArray *)positions;
-(HSWidgetPosition)widgetOriginForWidgetSize:(HSWidgetSize)size withPreferredOrigin:(HSWidgetPosition)position;
@end