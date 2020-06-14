@class SBIconController, SBHIconManager, SBRootFolderController;

@interface SBIconDragManager : NSObject // iOS 11 - 13
-(BOOL)isIconDragging; // iOS 11 - 13
-(SBIconController *)iconController; // iOS 11 - 12
-(SBHIconManager *)iconManager; // iOS 13
@end

@interface SBFloatingDockViewController : UIViewController // iOS 13
@property (nonatomic, assign) CGFloat dockOffscreenProgress; // iOS 13
@end

@interface SBHIconManager : NSObject // iOS 13
@property (nonatomic, retain) SBFloatingDockViewController *floatingDockViewController; // iOS 13
@property (nonatomic, retain) NSTimer *editingEndTimer; // iOS 13
@property (getter=isScrolling, nonatomic, readonly) BOOL scrolling; // iOS 13
-(void)_restartEditingEndTimer; // iOS 13
-(SBRootFolderController *)rootFolderController; // iOS 13
@end

@interface SBIconController : UIViewController // iOS 3 - 13
@property (nonatomic, readonly) SBHIconManager *iconManager; // iOS 13
@property (nonatomic, retain) NSTimer *editingEndTimer; // iOS 11 - 13
@property (nonatomic, assign) BOOL isDraggingWidget;
+(instancetype)sharedInstance; // iOS 3 - 13
-(UIInterfaceOrientation)orientation; // iOS 3 - 13
// -(NSUInteger)maxColCountForListInRootFolderWithInterfaceOrientation:(NSInteger)arg1; // iOS 7 - 12
-(id)grabbedIcon; // // iOS 3 - 10
-(SBIconDragManager *)iconDragManager; // iOS 11 - 13
-(SBRootFolderController *)_rootFolderController; // iOS 7 - 13
-(void)_restartEditingEndTimer; // iOS 11 - 12
-(void)bs_beginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated;
-(void)bs_endAppearanceTransition;
@end
