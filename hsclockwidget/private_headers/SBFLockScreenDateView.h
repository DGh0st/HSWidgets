@interface SBFLockScreenDateView : UIView // iOS 7 - 13
// +(CGFloat)defaultHeight; // iOS 7 - 13
-(instancetype)initWithFrame:(CGRect)arg1; // iOS 7 - 13
-(void)updateFormat; // iOS 7 - 13
-(void)setTimeLegibilityStrength:(CGFloat)arg1; // iOS 10 - 13
-(void)setSubtitleLegibilityStrength:(CGFloat)arg1; // iOS 10 - 13
-(void)setLegibilitySettings:(id)arg1; // iOS 7 - 13
-(void)setDate:(NSDate *)arg1; // iOS 7 - 13
-(void)setAlignmentPercent:(CGFloat)arg1; // iOS 10 - 13
@end
