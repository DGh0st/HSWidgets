#import <HSWidgets/HSWidgetViewController.h>

@interface SBFLockScreenDateView : UIView // iOS 7 - 12
+(CGFloat)defaultHeight; // iOS 7 - 12
-(id)initWithFrame:(CGRect)arg1; // iOS 7 - 12
-(void)updateFormat; // iOS 7 - 12
-(void)setTimeLegibilityStrength:(CGFloat)arg1; // iOS 10 - 12
-(void)setSubtitleLegibilityStrength:(CGFloat)arg1; // iOS 10 - 12
-(void)setLegibilitySettings:(id)arg1; // iOS 7 - 12
-(void)setDate:(NSDate *)arg1; // iOS 7 - 12
-(void)setAlignmentPercent:(CGFloat)arg1; // iOS 10 - 12
@end

@interface SBLockScreenDateViewController : UIViewController // iOS 7 - 12
-(id)initWithNibName:(id)arg1 bundle:(id)arg2; // iOS 7 - 12
-(SBFLockScreenDateView *)dateView; // iOS 7 - 12
@end

@protocol SBDateTimeOverrideObserver <NSObject> // iOS 9 - 12
@required
-(void)controller:(id)arg1 didChangeOverrideDateFromDate:(id)arg2; // iOS 9 - 12
@end

@protocol _UISettingsKeyObserver <NSObject> // iOS 7 - 12
@required
-(void)settings:(id)arg1 changedValueForKey:(id)arg2; // iOS 7 - 12
@end

@interface SBLegibilitySettings : NSObject // iOS 7 - 12
-(void)addKeyObserverIfPrototyping:(id)arg1; // iOS 10 - 12
-(void)removeKeyObserver:(id)arg1; // iOS 10 - 12
-(CGFloat)timeStrengthForStyle:(NSInteger)arg1; // iOS 7 - 12
-(CGFloat)dateStrengthForStyle:(NSInteger)arg1; // iOS 7 - 12
@end

@interface SBRootSettings : NSObject // iOS 7 - 12
-(SBLegibilitySettings *)legibilitySettings; // iOS 7 - 12
@end

@interface SBPrototypeController : NSObject // iOS 7 - 12
+(id)sharedInstance; // iOS 7 - 12
-(SBRootSettings *)rootSettings; // iOS 7 - 12
@end

@interface SBDateTimeController : NSObject // iOS 9 - 12
+(id)sharedInstance; // iOS 9 - 12
-(NSDate *)overrideDate; // iOS 9 - 12
-(void)removeObserver:(id)arg1; // iOS 9 - 12
-(void)addObserver:(id)arg1; // iOS 9 - 12
@end

@interface SBUIPreciseClockTimer : NSObject // iOS 12
+(id)sharedInstance; // iOS 12
+(id)now; // iOS 12
-(NSNumber *)startMinuteUpdatesWithHandler:(id)arg1; // iOS 12
-(void)stopMinuteUpdatesForToken:(NSNumber *)arg1; // iOS 12
@end

@interface SBPreciseClockTimer : NSObject // iOS 9 - 11
+(id)sharedInstance; // iOS 9 - 11
+(id)now; // iOS 9 - 11
-(NSNumber *)startMinuteUpdatesWithHandler:(id)arg1; // iOS 9 - 11
-(void)stopMinuteUpdatesForToken:(NSNumber *)arg1; // iOS 9 - 11
@end

@interface _UILegibilitySettings : NSObject // iOS 7 - 12
-(NSInteger)style; // iOS 7 - 12
@end

@interface HSClockWidgetViewController : HSWidgetViewController <SBDateTimeOverrideObserver, _UISettingsKeyObserver> {
	NSUInteger _numRows;
	_UILegibilitySettings* _legibilitySettings;
	NSNumber *_timerToken;
}
@property (nonatomic, retain) SBFLockScreenDateView *dateView;
-(void)createDateViewIfNeeded;
-(void)controller:(id)arg1 didChangeOverrideDateFromDate:(id)arg2;
-(void)settings:(id)arg1 changedValueForKey:(id)arg2;
-(void)_updateFormat;
-(void)_updateLegibilityStrength;
-(void)updateTimeNow;
@end