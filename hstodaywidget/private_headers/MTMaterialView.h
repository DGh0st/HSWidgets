@interface NCMaterialSettings : NSObject // iOS 10
-(void)setDefaultValues; // iOS 10
@end

@interface MTMaterialView : UIView // iOS 11 - 13
+(id)materialViewWithRecipe:(NSInteger)arg1 options:(NSUInteger)arg2; // iOS 11 - 12
// +(id)materialViewWithRecipe:(NSInteger)arg1 configuration:(NSUInteger)arg2; // iOS 13
-(void)_setContinuousCornerRadius:(CGFloat)arg1; // iOS 11 - 12
-(void)setFinalRecipe:(NSInteger)arg1 options:(NSUInteger)arg2 ; // iOS 12
-(void)setRecipe:(NSInteger)arg1; // iOS 13
-(void)setConfiguration:(NSInteger)arg1; // iOS 13
@end
