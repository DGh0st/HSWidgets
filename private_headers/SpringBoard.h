@interface SpringBoard : UIApplication
+(instancetype)sharedApplication;
-(void)addDisableActiveInterfaceOrientationChangeAssertion:(id)arg1; // iOS 7 - 13
-(void)removeDisableActiveInterfaceOrientationChangeAssertion:(id)arg1; // iOS 7 - 12
-(void)removeDisableActiveInterfaceOrientationChangeAssertion:(id)arg1 nudgeOrientationIfRemovingLast:(BOOL)arg2; // iOS 13
-(BOOL)isShowingHomescreen; // iOS 9 - 13
@end
