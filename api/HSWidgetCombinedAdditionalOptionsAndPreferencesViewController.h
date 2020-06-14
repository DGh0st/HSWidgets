#import "HSWidgetAdditionalOptions.h"
#import "HSWidgetAddNewAdditionalOptionsDelegate.h"
#import "HSWidgetPreferencesListController.h"

@interface HSWidgetCombinedAdditionalOptionsAndPreferencesViewController : HSWidgetPreferencesListController <HSWidgetAdditionalOptions>
@property (nonatomic, retain) Class widgetClass;
@property (nonatomic, retain) NSMutableDictionary *widgetOptions;
@property (nonatomic, assign) id<HSWidgetAddNewAdditionalOptionsDelegate> delegate;
-(void)cancelAdditionalOptions;
-(void)addWidget;
@end