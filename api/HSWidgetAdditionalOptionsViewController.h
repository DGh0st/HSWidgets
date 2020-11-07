#import "HSWidgetAdditionalOptions.h"
#import "HSWidgetAddNewAdditionalOptionsDelegate.h"
#import "HSWidgetAvailablePositionObject.h"

@interface HSWidgetAdditionalOptionsViewController : UITableViewController <HSWidgetAdditionalOptions>
@property (nonatomic, retain) Class widgetClass;
@property (nonatomic, retain) NSMutableDictionary *widgetOptions;
@property (nonatomic, assign) HSWidgetSize requestWidgetSize;
@property (nonatomic, retain) NSArray<HSWidgetAvailablePositionObject *> *availablePositions;
@property (nonatomic, assign) id<HSWidgetAddNewAdditionalOptionsDelegate> delegate;
-(instancetype)initWithWidgetsOptionsToExclude:(NSArray *)optionsToExclude withDelegate:(id<HSWidgetAddNewAdditionalOptionsDelegate>)delegate availablePositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions;
-(void)cancelAdditionalOptions;
-(void)addWidget;
-(BOOL)containsSpaceForGridPositions:(NSArray<HSWidgetPositionObject *> *)positions;
-(BOOL)containsSpaceForWidgetSize:(HSWidgetSize)size;
@end