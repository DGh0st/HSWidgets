#import <UIKit/UIKit.h>
#import "HSWidgets-core.h"
#import "HSWidgetViewController.h"
#import "HSAddNewWidgetView.h"
#import "HSAddWidgetRootViewController.h"
#import "SBIconCoordinate.h"
#import "SBIconListModel.h"
#import "SBIconListView.h"

typedef NS_ENUM(NSUInteger, HSWidgetAvailableSpaceRule) {
	HSWidgetAvailableSpaceRuleIncludeIconsWithMark = 0,
	HSWidgetAvailableSpaceRuleIncludeIconsWithMarkExceptLast,
	HSWidgetAvailableSpaceRuleExcludeIcons,
	HSWidgetAvailableSpaceRuleExcludeIconsExceptLast
};

__attribute__((visibility("hidden")))
@interface HSWidgetPageController : NSObject <HSWidgetDelegate, HSAddNewWidgetDelegate, HSAddWidgetSelectionDelegate> {
@private
	SBIconListView *_iconListView;
	SBIconListModel *_model;
	BOOL _isRemoving;
}
@property (nonatomic, retain) HSWidgetViewController *draggingWidgetViewController;
@property (nonatomic, assign) HSWidgetPosition newWidgetPositionForDraggingAnimation;
@property (nonatomic, retain) HSAddNewWidgetView *addNewWidgetView;
@property (nonatomic, assign) BOOL requiresSaveToFileForWidgetChanges;
@property (nonatomic, retain) UIViewController *widgetPickerViewController;
@property (nonatomic, retain) UIViewController *widgetPreferenceViewController;
@property (nonatomic, assign) BOOL shouldDisableWidgetLayout;
-(instancetype)initWithIconListView:(SBIconListView *)iconListView;
-(void)configureWidgetsIfNeededWithIndex:(NSInteger)index;
-(void)layoutWidgetPage;
-(void)viewWillTransitionToSize:(CGSize)arg1 withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)arg2;
-(SBIconCoordinate)coordinateForPoint:(CGPoint)arg1 withRow:(NSInteger)row column:(NSInteger)column;
-(void)setEditing:(BOOL)editing;
-(NSArray<HSWidgetAvailablePositionObject *> *)availableSpaceWithRule:(HSWidgetAvailableSpaceRule)rule;
-(NSArray<HSWidgetPositionObject *> *)occupiedWidgetSpaces;
-(void)animateUpdateOfIconChangesExcludingCurrentIcon:(BOOL)excluded completion:(void(^)(void))completion;
-(CGSize)sizeForWidgetSize:(HSWidgetSize)size;
@end
