// manage current page type
typedef NS_ENUM(NSUInteger, PageType) {
	PageTypeNone = 0,
	PageTypeIconsAndWidgetPage
};

@interface SBIconListModel : NSObject // iOS 4 - 13
@property (nonatomic, assign) PageType pageLayoutType; // PageType enum
@property (nonatomic, retain) NSMutableArray *widgetViewControllers;
-(NSArray *)icons; // iOS 4 - 13
-(NSUInteger)maxNumberOfIcons; // iOS 7 - 13
-(id)folder; // iOS 4 - 13
@end

@interface SBHIconModel : NSObject // iOS 13
-(NSUInteger)maxRowCountForListInRootFolderWithInterfaceOrientation:(UIInterfaceOrientation)arg1;
-(NSUInteger)maxColumnCountForListInRootFolderWithInterfaceOrientation:(UIInterfaceOrientation)arg1;
@end
