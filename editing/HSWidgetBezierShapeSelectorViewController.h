@protocol HSWidgetAddNewAdditionalOptionsDelegate;

__attribute__((visibility("hidden")))
@interface HSWidgetBezierShapeSelectorViewController : UITableViewController {
@private
	id<HSWidgetAddNewAdditionalOptionsDelegate> _delegate;
	NSArray *_bezierShapes;
	NSUInteger selectedBezierShapeIndex;
}
-(instancetype)initWithDelegate:(id<HSWidgetAddNewAdditionalOptionsDelegate>)delegate;
@end
