#import "HSWidgets-structs.h"
#import "HSWidgets-core.h"
#import "HSWidgetAdditionalOptions.h"
#import "HSWidgetDelegate.h"
#import "HSWidgetUnclippedView.h"

NS_ASSUME_NONNULL_BEGIN

// animation durations
extern const CGFloat HSWidgetAnimationDuration;
extern const CGFloat HSWidgetQuickAnimationDuration;

// keys in dictionary or user info used in notificaitons and methods
extern NSString *const HSWidgetDisplayCreatorKey;
extern NSString *const HSWidgetDisplayIconKey;
extern NSString *const HSWidgetDisplayNameKey;
extern NSString *const HSWidgetEditingStateKey;

// various notifications posted for different events
extern const NSNotificationName HSWidgetAllWidgetsConfiguredNotification;
extern const NSNotificationName HSWidgetAvailableSpaceDidChangeNotification;
extern const NSNotificationName HSWidgetEditingStateChangedNotification;

// manage zoom animation view style
typedef NS_ENUM(NSUInteger, ZoomAnimationViewStyle) {
	ZoomAnimationViewStyleDefault = 0,
	ZoomAnimationViewStyleImageCopy,
	ZoomAnimationViewStyleCustom
};

// manage accessory types
typedef NS_ENUM(NSUInteger, AccessoryType) {
	AccessoryTypeNone = 0,
	AccessoryTypeExpand,
	AccessoryTypeShrink,
	AccessoryTypeSettings
};

@interface HSWidgetViewController : UIViewController {
@protected
	NSMutableDictionary *widgetOptions;
	id<HSWidgetDelegate> _delegate;
}
@property (nonatomic, assign) HSWidgetFrame widgetFrame;
@property (nonatomic, assign) CGSize requestedSize;
@property (nonatomic, retain) NSArray<HSWidgetPositionObject *> * _gridPositions;
@property (nonatomic, assign) CGFloat cornerRadius;
+(NSBundle *)bundle;
+(BOOL)isAvailable;
+(BOOL)canAddWidgetForAvailableGridPositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions;
+(HSWidgetSize)minimumSize;
+(NSDictionary *)widgetDisplayInfo;
+(nullable Class<HSWidgetAdditionalOptions>)addNewWidgetAdditionalOptionsControllerClass;
+(nullable Class)preferencesOptionsControllerClass;
+(nullable NSDictionary *)createOptionsFromController:(nullable id<HSWidgetAdditionalOptions>)controller withAvailableGridPosition:(NSArray<HSWidgetAvailablePositionObject *> *)positions;
+(HSWidgetSize)widgetSizeFromController:(nullable id<HSWidgetAdditionalOptions>)controller withAvailableGridPosition:(NSArray<HSWidgetAvailablePositionObject *> *)positions;
+(NSInteger)allowedInstancesPerPage;
-(instancetype)initForWidgetFrame:(HSWidgetFrame)frame withOptions:(nullable NSDictionary *)options NS_REQUIRES_SUPER;
-(nullable NSDictionary *)options;
-(void)setWidgetOptionValue:(nullable id<NSCoding>)object forKey:(NSString *)key;
-(void)_setDelegate:(nullable id<HSWidgetDelegate>)delegate NS_REQUIRES_SUPER;
-(CGRect)calculatedFrame;
-(BOOL)isAccessoryTypeEnabled:(AccessoryType)accessory;
-(void)accessoryTypeTapped:(AccessoryType)accessory;
-(BOOL)containsSpaceToExpandOrShrinkToGridPositions:(NSArray<HSWidgetPositionObject *> *)positions;
-(BOOL)containsSpaceToExpandOrShrinkToWidgetSize:(HSWidgetSize)size;
-(void)updateForExpandOrShrinkToGridPositions:(NSArray<HSWidgetPositionObject *> *)positions;
-(void)updateForExpandOrShrinkToWidgetSize:(HSWidgetSize)size;
-(ZoomAnimationViewStyle)viewStyleForZoomAnimaton;
-(nullable UIView *)zoomAnimatingView;
-(void)clearZoomAnimatingView;
@end

NS_ASSUME_NONNULL_END
