#import <HSWidgets/HSWidgetViewController.h>
#import "CCUIContentModuleContainerViewControllerDelegate.h"
#import "CCUIContentModuleContextDelegate.h"

@class CCUIContentModuleContainerView, CCUIContentModuleContainerViewController, CCUIModuleSettings;

@interface HSCCModuleWidgetViewController : HSWidgetViewController <CCUIContentModuleContainerViewControllerDelegate, CCUIContentModuleContextDelegate>
@property (nonatomic, retain, readonly) NSString *moduleIdentifier;
@property (nonatomic, retain) CCUIContentModuleContainerViewController *moduleContainerViewController;
@property (nonatomic, retain) CCUIContentModuleContainerView *moduleContainerView;
@property (nonatomic, retain) CCUIModuleSettings *moduleSettings;
-(void)dismissExpandedModule;
@end