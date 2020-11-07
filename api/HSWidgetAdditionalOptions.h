@protocol HSWidgetAddNewAdditionalOptionsDelegate;
@class HSWidgetAvailablePositionObject;

struct HSWidgetSize;

@protocol HSWidgetAdditionalOptions <NSObject>
@required
@property (nonatomic, retain) Class widgetClass;
@property (nonatomic, retain) NSMutableDictionary *widgetOptions;
@property (nonatomic, assign) HSWidgetSize requestWidgetSize;
@property (nonatomic, assign) id<HSWidgetAddNewAdditionalOptionsDelegate> delegate;
@optional
-(instancetype)initWithWidgetsOptionsToExclude:(NSArray *)optionsToExclude withDelegate:(id<HSWidgetAddNewAdditionalOptionsDelegate>)delegate availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions;
@end
