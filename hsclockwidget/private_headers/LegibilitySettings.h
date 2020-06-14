@interface LegibilitySettings : NSObject // SBLegibilitySettings (iOS 7 - 12) and SBFLegibilitySettings (iOS 13)
-(void)addKeyObserverIfPrototyping:(id)arg1; // iOS 10 - 12 (inherited from SBUISettings)
-(void)addKeyObserver:(id)arg1; // iOS 12 - 13 (inherited from PTSettings)
-(void)removeKeyObserver:(id)arg1; // iOS 10 - 13
-(CGFloat)timeStrengthForStyle:(NSInteger)arg1; // iOS 7 - 13
-(CGFloat)dateStrengthForStyle:(NSInteger)arg1; // iOS 7 - 13
@end
