#import "HSWidgets-core.h"
#import "HSAddNewWidgetPositionViewDelegate.h"
#import "HSWidgetResources.h"

__attribute__((visibility("hidden")))
@interface HSAddNewWidgetPositionView : UIView {
@private
	id<HSAddNewWidgetPositionViewDelegate> _delegate;
}
@property (nonatomic, retain) HSWidgetPositionObject *position;
@property (nonatomic, assign) HSWidgetBezierShape bezierShape;
-(instancetype)initWithWidgetPosition:(HSWidgetPositionObject *)position;
-(void)setDelegate:(id<HSAddNewWidgetPositionViewDelegate>)delegate;
@end
