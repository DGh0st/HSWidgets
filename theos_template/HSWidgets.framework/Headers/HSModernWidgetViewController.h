#import "HSWidgetViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HSModernWidgetViewController : HSWidgetViewController
@property (nonatomic, retain, nullable) UIVisualEffectView *blurView;
@property (nonatomic, retain, nullable) UILabel *titleLabel;
@property (nonatomic, readonly, nullable) UIView *contentView;
@property (nonatomic, assign) BOOL isExpanded;
+(HSWidgetSize)minimumSize;
+(NSInteger)allowedInstancesPerPage;
-(instancetype)initForWidgetFrame:(HSWidgetFrame)frame withOptions:(nullable NSDictionary *)options NS_REQUIRES_SUPER;
-(CGRect)calculatedFrame;
-(void)setCornerRadius:(CGFloat)cornerRadius;
-(BOOL)isAccessoryTypeEnabled:(AccessoryType)accessory;
-(void)accessoryTypeTapped:(AccessoryType)accessory;
-(void)expandWidget;
-(void)shrinkWidget;
@end

NS_ASSUME_NONNULL_END
