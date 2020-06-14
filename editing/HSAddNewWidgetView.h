#import "HSAddNewWidgetPositionView.h"
#import "HSAddNewWidgetDelegate.h"

__attribute__((visibility("hidden")))
@interface HSAddNewWidgetView : UIView <HSAddNewWidgetPositionViewDelegate> {
@private
	id<HSAddNewWidgetDelegate> _delegate;
}
-(instancetype)initWithFrame:(CGRect)frame;
-(void)updateAvailableSpaces:(NSArray<HSWidgetPositionObject *> *)availableSpaces withAnimationDuration:(CGFloat)animationDuration;
-(void)setDelegate:(id<HSAddNewWidgetDelegate>)delegate;
@end
