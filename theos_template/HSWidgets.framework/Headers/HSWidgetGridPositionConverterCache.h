#import "HSWidgetPositionObject.h"
#import "HSWidgetAvailablePositionObject.h"

struct HSWidgetSize;
struct HSWidgetFrame;

@interface HSWidgetGridPositionConverterCache : NSObject
+(NSMutableArray<HSWidgetPositionObject *> *)gridPositionsForWidgetFrame:(HSWidgetFrame)frame;
+(HSWidgetPosition)originForWidgetOfSize:(HSWidgetSize)size inGridPositions:(NSArray<HSWidgetPositionObject *> *)positions;
+(BOOL)canFitWidgetOfSize:(HSWidgetSize)size inGridPositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions;
+(BOOL)canFitWidget:(NSArray<HSWidgetPositionObject *> *)widgetPositions inGridPositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions;
@end
