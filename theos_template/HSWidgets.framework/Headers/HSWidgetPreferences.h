@class HSWidgetAvailablePositionObject, HSWidgetViewController;

@protocol HSWidgetPreferences <NSObject>
@required
@property (nonatomic, retain) HSWidgetViewController *widgetViewController;
@property (nonatomic, retain) NSArray<HSWidgetAvailablePositionObject *> *availablePositions;
-(instancetype)initWithWidgetViewController:(HSWidgetViewController *)widgetViewController availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions;
@end
