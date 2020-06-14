#import "HSWidgetUnrotateableViewController.h"
#import "SBIconController.h"

@implementation HSWidgetUnrotateableViewController
-(BOOL)shouldAutorotate {
	return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
	return (UIInterfaceOrientationMask)(1 << [[%c(SBIconController) sharedInstance] orientation]);
}
@end