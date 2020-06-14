#import "HSWidgetResources.h"

__attribute__((visibility("hidden")))
@interface HSWidgetBezierShapeTableViewCell : UITableViewCell
@property (nonatomic, assign, setter=setBezierShape:) HSWidgetBezierShape bezierShape;
@property (nonatomic, retain) UILabel *nameLabel;
@end
