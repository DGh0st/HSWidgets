#import "HSAddNewWidgetView.h"

#define kAnimationDuration 0.3

#define kBundlePath @"/Library/Application Support/HSWidgets/Assets.bundle"

@interface SBCloseBoxView : UIButton // iOS 7 - 11
@end

@protocol HSWidgetDelegate
@required
-(BOOL)_canDragWidget:(id)widget;
-(void)_closeTapped:(id)widgetViewController;
-(void)_setDraggingWidget:(id)widget;
-(void)_widgetDraggedToPoint:(CGPoint)point;
-(void)_updatePageForExpandOrShrinkOfWidget:(id)widgetViewController fromRows:(NSUInteger)rows;
@end

@interface HSWidgetViewController : UIViewController {
	BOOL _isEditing;
	UIView *_editingView;
	SBCloseBoxView *_closeBoxView;
	SBCloseBoxView *_expandBoxView;
	SBCloseBoxView *_shrinkBoxView;
	id<HSWidgetDelegate> _delegate;
	CGPoint _editingWidgetTranslationPoint;
	UIView *_zoomAnimatingView;
	NSMutableDictionary *_options;
	HSWidgetAvailableSpace _availableSpace;
}
@property (nonatomic, assign) NSUInteger originRow;
@property (nonatomic, assign) CGSize requestedSize;
+(BOOL)canAddWidgetForAvailableRows:(NSUInteger)rows;
+(NSString *)displayName;
+(UIImage *)icon;
+(Class)addNewWidgetAdditionalOptionsClass;
+(NSDictionary *)createOptionsFromController:(id)controller;
+(NSInteger)allowedInstancesPerPage;
-(void)_editingStateChanged;
-(NSDictionary *)options;
-(id)initForOriginRow:(NSUInteger)originRow withOptions:(NSDictionary *)options;
-(void)_setDelegate:(id<HSWidgetDelegate>)delegate;
-(NSUInteger)numRows;
-(CGRect)calculatedFrame;
-(void)expandBoxTapped;
-(void)shrinkBoxTapped;
-(void)updateForExpandOrShrinkFromRows:(NSUInteger)rows;
-(UIView *)zoomAnimatingView;
-(void)clearZoomAnimatingView;
-(BOOL)canExpandWidget;
-(BOOL)canShrinkWidget;
-(BOOL)shouldUseCustomViewForAnimation;
-(NSUInteger)availableRows;
-(NSUInteger)availableStartRow;
-(void)_updateAvailableSpace:(HSWidgetAvailableSpace)space;
@end