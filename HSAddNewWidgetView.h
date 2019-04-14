// available row space
typedef struct HSWidgetAvailableSpace {
	NSUInteger startRow;
	NSUInteger numRows;
} HSWidgetAvailableSpace;

@protocol HSAddNewWidgetDelegate
@required
-(void)_addNewWidgetTappedWithAvailableSpace:(HSWidgetAvailableSpace)availableSpace;
@end

@interface HSAddNewWidgetView : UIView {
	id<HSAddNewWidgetDelegate> _addNewWidgetDelegate;
	HSWidgetAvailableSpace _availableSpace;
}
@property (nonatomic, assign) BOOL isTouchDown;
@property (nonatomic, retain) UIColor *fillColor;
-(id)initWithFrame:(CGRect)frame withAvailableSpace:(HSWidgetAvailableSpace)availableSpace;
-(void)setAddNewWidgetDelegate:(id<HSAddNewWidgetDelegate>)addNewWidgetDelegate;
-(void)setAvailableSpace:(HSWidgetAvailableSpace)availableSpace;
@end