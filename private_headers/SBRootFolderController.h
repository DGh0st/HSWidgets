@class SBIconListView, SBHIconModel;

@interface SBFolderController : UIViewController // iOS 7 - 13
@property (nonatomic, copy, readonly) NSArray *iconListViews; // iOS 7 - 13
@property (nonatomic, readonly) NSUInteger iconListViewCount; // iOS 7 - 13
-(SBIconListView *)currentIconListView; // iOS 7 - 13
-(BOOL)isEditing; // iOS 7 - 13
-(SBIconListView *)iconListViewAtIndex:(NSUInteger)arg1; // iOS 7 - 13
-(SBHIconModel *)iconModel; // iOS 13
@end

@interface SBRootFolderController : SBFolderController // iOS 7 - 13
@property (nonatomic, retain) NSMutableDictionary *allPagesWidgetLayouts;
@end
