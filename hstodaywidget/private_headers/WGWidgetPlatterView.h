#import "WGWidgetShortLookView.h"

@interface WGWidgetPlatterView : UIView // iOS 11 - 13
-(instancetype)initWithFrame:(CGRect)arg1 andCornerRadius:(CGFloat)arg2; // iOS 11 - 12
-(instancetype)initWithFrame:(CGRect)arg1; // iOS 13
-(void)_setContinuousCornerRadius:(CGFloat)arg1; // iOS 13
-(void)setWidgetHost:(id)arg1; // iOS 11 - 13
-(WGWidgetHostingViewController *)widgetHost; // iOS 11 - 13
-(void)setShowMoreButtonVisible:(BOOL)arg1; // iOS 11 - 13
-(void)updateWithRecipe:(NSInteger)arg1 options:(NSUInteger)arg2; // iOS 12
-(void)setMaterialGroupNameBase:(NSString *)arg1; // iOS 13
-(void)_configureHeaderViewsIfNecessary; // iOS 13
-(void)_configureBackgroundMaterialViewIfNecessary; // iOS 13
-(void)setContentViewHitTestingDisabled:(BOOL)arg1; // iOS 13
@end
