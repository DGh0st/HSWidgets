#import "SBIconCoordinate.h"

@class HSWidgetPageController;

@interface SBIconView : UIView // iOS 5 - 13
+(CGSize)defaultIconViewSize; // iOS 13
+(CGSize)defaultIconViewSizeForIconImageSize:(CGSize)arg1 configurationOptions:(NSUInteger)arg2; // iOS 13
@end

@interface SBIconListView : UIView // iOS 4 - 13
@property (nonatomic, retain) HSWidgetPageController *widgetPageController;
@property (nonatomic, assign) UIInterfaceOrientation orientation; // iOS 7 - 13
+(NSUInteger)iconRowsForInterfaceOrientation:(UIInterfaceOrientation)arg1; // iOS 4 - 12
+(NSUInteger)iconColumnsForInterfaceOrientation:(UIInterfaceOrientation)arg1; // iOS 4 - 12
+(NSUInteger)defaultIconViewConfigurationOptions; // iOS 13
-(Class)baseIconViewClass; // iOS 7 - 13
// +(NSUInteger)maxIcons; // iOS 4 - 12
// +(NSUInteger)maxVisibleIconRowsInterfaceOrientation:(UIInterfaceOrientation)arg1; // iOS 5 - 12
-(NSUInteger)iconColumnsForCurrentOrientation; // iOS 4 - 13
-(NSUInteger)iconRowsForCurrentOrientation; // iOS 4 - 13
// -(SBIconCoordinate)coordinateForIcon:(id)arg1; // iOS 7 - 13
-(CGPoint)originForIconAtCoordinate:(SBIconCoordinate)arg1; // iOS 7 - 13
// -(SBIconCoordinate)coordinateForIconAtIndex:(NSUInteger)arg1; // iOS 7 - 13
-(NSUInteger)indexForCoordinate:(SBIconCoordinate)arg1 forOrientation:(UIInterfaceOrientation)arg2; // iOS 7 - 13
-(SBIconCoordinate)iconCoordinateForIndex:(NSUInteger)arg1 forOrientation:(UIInterfaceOrientation)arg2; // iOS 7 - 13
-(CGPoint)originForIconAtIndex:(NSUInteger)arg1; // iOS 7 - 13
-(SBIconListModel *)model; // iOS 4 - 13
-(CGFloat)horizontalIconPadding; // iOS 4 - 13
-(CGSize)defaultIconSize; // iOS 5 - 12
// -(CGSize)alignmentIconViewSize; // iOS 13
-(CGSize)alignmentIconSize; // iOS 11 - 13
-(CGFloat)verticalIconPadding; // iOS 4 - 13
-(void)layoutIconsNow; // iOS 4 - 13
-(NSUInteger)rowAtPoint:(CGPoint)arg1; // iOS 4 - 13
-(NSUInteger)columnAtPoint:(CGPoint)arg1; // iOS 4 - 13
-(id)icons; // iOS 4 - 13
-(BOOL)isEditing; // iOS 7 - 13
@end

@interface SBRootIconListView : SBIconListView // iOS 7 - 12
@end
