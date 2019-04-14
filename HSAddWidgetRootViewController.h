#import "HSAddNewWidgetView.h"
#import "HSAdditionalOptionsViewController.h"

@protocol HSAddWidgetSelectionDelegate
@required
-(void)addWidgetOfClass:(Class)widgetClass forAvailableSpace:(HSWidgetAvailableSpace)availableSpace withOptions:(NSDictionary *)options;
-(void)_cancelAddWidgetWithCompletion;
-(NSMutableArray *)updatedAvailableClassesForController:(id)controller;
@end

@interface HSAddWidgetRootViewController : UITableViewController <HSAddWidgetAdditionalOptionsDelegate>
@property (nonatomic, assign, setter=_setAvailableSpace:) HSWidgetAvailableSpace availableSpace;
@property (nonatomic, retain) NSMutableArray *availableWidgetClasses;
@property (nonatomic, retain) id<HSAddWidgetSelectionDelegate> addWidgetSelectionDelegate;
@property (nonatomic, retain) NSDictionary *widgetsToExclude;
-(void)_dismissAddWidget;
-(void)_addWidgetForClass:(Class)widgetClass withAdditionalOptionsViewContorller:(id)additionalOptionsViewController;
-(void)updateAvailableWidgetsForExclusions;
@end