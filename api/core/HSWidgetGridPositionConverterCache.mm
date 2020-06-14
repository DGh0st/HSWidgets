#import "HSWidgetGridPositionConverterCache.h"
#import "HSWidgets-structs.h"
#import "HSWidgetFrameObject.h"
#import "HSWidgetSizeObject.h"
#import <vector>

typedef NSMutableDictionary<HSWidgetSizeObject *, HSWidgetPositionObject *> HSWidgetSizeToPositionDictionary;
typedef NSMutableDictionary<NSValue *, HSWidgetPositionObject *> HSWidgetPointToPositionDictionary;

#define CACHE_PURGE_SIZE 15

@interface HSWidgetGridPositionConverterCache ()
@property (nonatomic, retain) NSMutableDictionary<HSWidgetFrameObject *, NSMutableArray<HSWidgetPositionObject *> *> *_widgetFramesToGridPositionsCache;
@property (nonatomic, retain) NSMutableDictionary<NSString *, HSWidgetSizeToPositionDictionary *> *_positionsToWidgetSizesCache;
@end

static void Create2DGrid(std::vector<std::vector<NSUInteger>> &availablePositions, NSArray<HSWidgetPositionObject *> *positions) {
	// though this theoretically should work for non sorted positions array this was written with
	// assumption that positions are ordered from top -> bottom for row and left -> right for columns
	NSUInteger maxColumns = 0, maxRows = 0;
	for (NSUInteger index = 0; index < positions.count; ++index) {
		HSWidgetPositionObject *position = positions[index];
		maxColumns = MAX(maxColumns, position.col);
		maxRows = MAX(maxRows, position.row);
		if (availablePositions.size() < maxRows)
			availablePositions.resize(maxRows);
		if (availablePositions[position.row - 1].size() < maxColumns)
			availablePositions[position.row - 1].resize(maxColumns, 0);
		availablePositions[position.row - 1][position.col - 1] = 1;
	}

	// resize all the columns to be the same size
	for (std::vector<NSUInteger> &row : availablePositions) {
		if (row.size() < maxColumns)
			row.resize(maxColumns, 0);
	}
}

static void UpdateConsecutiveRows(std::vector<std::vector<NSUInteger>> &availablePositions) {
	// update with number of consecutive rows
	// skip last row since it can only be 0 or 1 and we already did that when creating vector
	for (NSInteger row = availablePositions.size() - 2; row >= 0; --row) {
		for (NSInteger col = 0; col < availablePositions[row].size(); ++col) {
			if (availablePositions[row][col] == 0)
				continue;

			// number of rows available for current is rows available in next row + 1
			availablePositions[row][col] += availablePositions[row + 1][col];
		}
	}
}

static HSWidgetPosition OriginForWidgetSize(const std::vector<std::vector<NSUInteger>> &availablePositions, HSWidgetSize size, NSUInteger row, NSUInteger col) {
	for (NSInteger sizeCol = 0; sizeCol < size.numCols; ++sizeCol) {
		if (availablePositions[row][col + sizeCol] < size.numRows)
			return HSWidgetPositionZero;
	}
	return HSWidgetPositionMake(row + 1, col + 1);
}

static HSWidgetPosition OriginForWidgetSize(const std::vector<std::vector<NSUInteger>> &availablePositions, HSWidgetSize size) {
	NSInteger numRows = availablePositions.size() - size.numRows;
	for (NSInteger row = 0; row <= numRows; ++row) {
		NSInteger numCols = availablePositions[row].size() - size.numCols;
		for (NSInteger col = 0; col <= numCols; ++col) {
			if (!HSWidgetPositionEqualsPosition(OriginForWidgetSize(availablePositions, size, row, col), HSWidgetPositionZero))
				return HSWidgetPositionMake(row + 1, col + 1);
		}
	}
	return HSWidgetPositionZero;
}

static BOOL CanFitPositions(const std::vector<std::vector<NSUInteger>> &availablePositions, NSArray<HSWidgetPositionObject *> *positions) {
	for (HSWidgetPositionObject *position in positions) {
		if (position.row <= 0 || position.col <= 0 || position.row > availablePositions.size() || position.col > availablePositions[0].size()) {
			return NO; // position is invalid
		}

		if (availablePositions[position.row - 1][position.col - 1] == 0) {
			return NO;
		}
	}
	return YES;
}

static NSString *GetKeyForWidgetPositions(NSArray<HSWidgetPositionObject *> *positions) {
	// convert positions to be a string of "-x_y" for each position so and array of
	// [(1, 2), (1, 3), (2, 1), (2, 2), (2, 3)] would be "-1_2-1_3-2_1-2_2-2_3"
	NSMutableString *key = [NSMutableString stringWithCapacity:positions.count * 4];
	for (HSWidgetPositionObject *position in positions) {
		[key appendFormat:@"-%tu_%tu", position.row, position.col];
	}
	return key;
}

@implementation HSWidgetGridPositionConverterCache
+(instancetype)sharedCache {
	static HSWidgetGridPositionConverterCache *_sharedCache = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedCache = [[HSWidgetGridPositionConverterCache alloc] init];
	});
	return _sharedCache;
}

-(instancetype)init {
	self = [super init];
	self._widgetFramesToGridPositionsCache = [NSMutableDictionary dictionaryWithCapacity:4];
	self._positionsToWidgetSizesCache = [NSMutableDictionary dictionaryWithCapacity:4];
	return self;
}

+(NSMutableArray<HSWidgetPositionObject *> *)gridPositionsForWidgetFrame:(HSWidgetFrame)frame {
	// check if size isn't zero
	NSUInteger spaces = SpacesForWidgetSize(frame.size);
	if (spaces == 0) {
		return [NSMutableArray array];
	}

	HSWidgetFrameObject *requestedFrameObject = [HSWidgetFrameObject objectWithWidgetFrame:frame];
	HSWidgetGridPositionConverterCache *sharedGridPositionConverterCache = [self sharedCache];

	// get it from the cache if possible
	NSMutableArray<HSWidgetPositionObject *> *gridPositions = sharedGridPositionConverterCache._widgetFramesToGridPositionsCache[requestedFrameObject];
	if (gridPositions == nil) {
		gridPositions = [NSMutableArray arrayWithCapacity:spaces];
		for (NSUInteger row = 0; row < frame.size.numRows; ++row) {
			for (NSUInteger col = 0; col < frame.size.numCols; ++col) {
				HSWidgetPosition position = HSWidgetPositionMake(row + frame.origin.row, col + frame.origin.col);
				[gridPositions addObject:[HSWidgetPositionObject objectWithWidgetPosition:position]];
			}
		}

		// purge the whole cache if it is getting too big
		if (sharedGridPositionConverterCache._widgetFramesToGridPositionsCache.count >= CACHE_PURGE_SIZE) {
			for (HSWidgetFrameObject *key in sharedGridPositionConverterCache._widgetFramesToGridPositionsCache) {
				[sharedGridPositionConverterCache._widgetFramesToGridPositionsCache[key] removeAllObjects];
			}
			[sharedGridPositionConverterCache._widgetFramesToGridPositionsCache removeAllObjects];
		}

		// cache the results
		sharedGridPositionConverterCache._widgetFramesToGridPositionsCache[requestedFrameObject] = gridPositions;
	}

	// make a deep copy of what is in the cache
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:gridPositions.count];
	for (HSWidgetPositionObject *position in gridPositions) {
		[result addObject:[[position copy] autorelease]];
	}
	return result;
}

+(HSWidgetPosition)originForWidgetOfSize:(HSWidgetSize)size inGridPositions:(NSArray<HSWidgetPositionObject *> *)positions {
	// check if there is even enough spaces available
	if (SpacesForWidgetSize(size) > positions.count) {
		return HSWidgetPositionZero;
	}

	NSString *positionsKey = GetKeyForWidgetPositions(positions);
	HSWidgetSizeObject *widgetSizeObject = [HSWidgetSizeObject objectWithWidgetSize:size];
	HSWidgetGridPositionConverterCache *sharedGridPositionConverterCache = [self sharedCache];

	// get it from the cache if possible
	HSWidgetSizeToPositionDictionary *widgetSizesToPosition = sharedGridPositionConverterCache._positionsToWidgetSizesCache[positionsKey];
	HSWidgetPositionObject *originWidgetPosition = widgetSizesToPosition != nil ? widgetSizesToPosition[widgetSizeObject] : nil;
	if (originWidgetPosition == nil && positions.count > 0) {
		std::vector<std::vector<NSUInteger>> availablePositions;
		Create2DGrid(availablePositions, positions);
		UpdateConsecutiveRows(availablePositions);

		// get the origin position that widget size can fit in
		originWidgetPosition = [HSWidgetPositionObject objectWithWidgetPosition:OriginForWidgetSize(availablePositions, size)];

		// purge the whole cache if it is getting too big
		if (sharedGridPositionConverterCache._positionsToWidgetSizesCache.count >= CACHE_PURGE_SIZE) {
			widgetSizesToPosition = nil;
			for (NSString *key in sharedGridPositionConverterCache._positionsToWidgetSizesCache) {
				[sharedGridPositionConverterCache._positionsToWidgetSizesCache[key] removeAllObjects];
			}
			[sharedGridPositionConverterCache._positionsToWidgetSizesCache removeAllObjects];
		}

		// cache the results
		if (widgetSizesToPosition == nil) {
			sharedGridPositionConverterCache._positionsToWidgetSizesCache[positionsKey] = widgetSizesToPosition = [NSMutableDictionary dictionaryWithCapacity:4];
		} else if (widgetSizesToPosition.count >= CACHE_PURGE_SIZE) {
			[widgetSizesToPosition removeAllObjects];
		}
		widgetSizesToPosition[widgetSizeObject] = originWidgetPosition;
	}
	return originWidgetPosition.position;
}

+(BOOL)canFitWidgetOfSize:(HSWidgetSize)size inGridPositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	NSPredicate *nonIconPositionsPredicate = [NSPredicate predicateWithFormat:@"containsIcon == NO"];
	NSArray *nonIconAvailablePositions = [positions filteredArrayUsingPredicate:nonIconPositionsPredicate];
	
	// check if has enough available positions
	if (SpacesForWidgetSize(size) > nonIconAvailablePositions.count) {
		return NO;
	}

	// check if it can fit without moving icons
	HSWidgetPosition originForNonIconPositions = [self originForWidgetOfSize:size inGridPositions:positions];
	if (!HSWidgetPositionEqualsPosition(originForNonIconPositions, HSWidgetPositionZero)) {
		return YES;
	}

	// check if it can fit with moving icons
	return !HSWidgetPositionEqualsPosition([self originForWidgetOfSize:size inGridPositions:positions], HSWidgetPositionZero);
}

+(BOOL)canFitWidget:(NSArray<HSWidgetPositionObject *> *)widgetPositions inGridPositions:(NSArray<HSWidgetAvailablePositionObject *> *)positions {
	NSPredicate *nonIconPositionsPredicate = [NSPredicate predicateWithFormat:@"containsIcon == NO"];
	NSArray *nonIconAvailablePositions = [positions filteredArrayUsingPredicate:nonIconPositionsPredicate];
	
	// check if there is enough space to add widgetPositions
	if (widgetPositions.count > nonIconAvailablePositions.count) {
		return NO;
	}

	std::vector<std::vector<NSUInteger>> availablePositions;
	Create2DGrid(availablePositions, positions);
	return CanFitPositions(availablePositions, widgetPositions);
}

-(void)dealloc {
	[self._widgetFramesToGridPositionsCache release];
	self._widgetFramesToGridPositionsCache = nil;

	[self._positionsToWidgetSizesCache release];
	self._positionsToWidgetSizesCache = nil;

	[super dealloc];
}
@end
