@class NSExtension;

@interface WGWidgetInfo : NSObject // iOS 10 - 13
@property (nonatomic, readonly) NSExtension *extension; // iOS 10 - 13
@property (setter=_setDisplayName:, nonatomic, copy) NSString *displayName; // iOS 10 - 13
@property (nonatomic, copy, readonly) NSString *widgetIdentifier; // iOS 10 - 13
@property (assign, setter=_setLargestAllowedDisplayMode:, nonatomic) NSInteger largestAllowedDisplayMode; // iOS 10 - 13
+(id)widgetInfoWithExtension:(id)arg1; // iOS 10 - 13
+(CGFloat)maximumContentHeightForCompactDisplayMode; // iOS 10 - 13
-(UIImage *)icon; // iOS 10 - 11
-(id)_icon; // iOS 12 - 13
-(id)_outlineIcon; // iOS 12 - 13
-(void)requestSettingsIconWithHandler:(id)arg1; // iOS 12 - 13
@end

@interface WGCalendarWidgetInfo : WGWidgetInfo // iOS 10 - 13
+(BOOL)isCalendarExtension:(id)arg1; // iOS 10 - 13
-(void)_setDate:(id)arg1; // iOS 11 - 13
@end
