@protocol CCUIContentModuleContainerViewControllerDelegate <NSObject> // iOS 11 - 13
@required
-(CGRect)compactModeFrameForContentModuleContainerViewController:(id)moduleContainerViewController; // iOS 11 - 13
-(BOOL)contentModuleContainerViewController:(id)moduleContainerViewController canBeginInteractionWithModule:(id)module; // iOS 11 - 13
-(void)contentModuleContainerViewController:(id)moduleContainerViewController didBeginInteractionWithModule:(id)module; // iOS 11 - 13
-(void)contentModuleContainerViewController:(id)moduleContainerViewController didFinishInteractionWithModule:(id)module; // iOS 11 - 13
-(void)contentModuleContainerViewController:(id)moduleContainerViewController willOpenExpandedModule:(id)module; // iOS 11 - 13
-(void)contentModuleContainerViewController:(id)moduleContainerViewController didOpenExpandedModule:(id)module; // iOS 11 - 13
-(void)contentModuleContainerViewController:(id)moduleContainerViewController willCloseExpandedModule:(id)module; // iOS 11 - 13
-(void)contentModuleContainerViewController:(id)moduleContainerViewController didCloseExpandedModule:(id)module; // iOS 11 - 13
-(BOOL)shouldApplyBackgroundEffectsForContentModuleContainerViewController:(id)moduleContainerViewController; // iOS 11 - 12
-(id)backgroundViewForContentModuleContainerViewController:(id)moduleContainerViewController; // iOS 11 - 12
-(void)contentModuleContainerViewController:(id)moduleContainerViewController willPresentViewController:(id)viewController; // iOS 13
-(void)contentModuleContainerViewController:(id)moduleContainerViewController willDismissViewController:(id)viewController; // iOS 13
-(void)contentModuleContainerViewControllerDismissPresentedContent:(id)presentedContent; // iOS 13
@end
