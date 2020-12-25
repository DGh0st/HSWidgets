@protocol CCUIContentModule, CCUIContentModuleContainerViewControllerDelegate;
@class CCUIContentModuleBackgroundView, CCUIContentModulePresentationContext;

@interface CCUIContentModuleContainerViewController : UIViewController // iOS 11 - 13
@property (nonatomic, assign, weak) id<CCUIContentModuleContainerViewControllerDelegate> delegate; // iOS 11 - 13
@property (nonatomic, retain) CCUIContentModuleBackgroundView *backgroundView; // iOS 11 - 13
@property (nonatomic, assign, getter=isExpanded) BOOL expanded; // iOS 11 - 13
@property (nonatomic, retain) id<CCUIContentModule> contentModule; // iOS 11 - 13
@property (nonatomic, retain) UIView *contentView; // iOS 11 - 13
-(instancetype)initWithModuleIdentifier:(NSString *)identifier contentModule:(id<CCUIContentModule>)module presentationContext:(CCUIContentModulePresentationContext *)context; // iOS 13
-(instancetype)initWithModuleIdentifier:(NSString *)identifier contentModule:(id<CCUIContentModule>)module; // iOS 11 - 12
-(void)expandModule; // iOS 11 - 13
-(void)dismissPresentedContentAnimated:(BOOL)animated; // iOS 11 - 13
-(void)setMaterialGroupName:(NSString *)groupName; // iOS 12 - 13
-(void)willBecomeActive; // iOS 11 - 13
-(void)willResignActive; // iOS 11 - 13
-(void)displayWillTurnOff; // iOS 13
@end
