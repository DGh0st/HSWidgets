// Widget grid position
typedef struct HSWidgetPosition {
	NSUInteger row;
	NSUInteger col;
} HSWidgetPosition;

extern const HSWidgetPosition HSWidgetPositionZero;

static inline HSWidgetPosition HSWidgetPositionMake(NSUInteger row, NSUInteger col) {
	HSWidgetPosition widgetPosition;
	widgetPosition.row = row;
	widgetPosition.col = col;
	return widgetPosition;
}

static inline BOOL HSWidgetPositionEqualsPosition(HSWidgetPosition first, HSWidgetPosition second) {
	return first.row == second.row && first.col == second.col;
}

static inline HSWidgetPosition HSWidgetPositionAdd(HSWidgetPosition position, NSInteger rows, NSInteger cols) {
	HSWidgetPosition widgetPosition;
	widgetPosition.row = position.row + rows;
	widgetPosition.col = position.col + cols;
	return widgetPosition;
}

static inline BOOL HSWidgetPositionIsValid(HSWidgetPosition position, NSUInteger maxRows, NSUInteger maxCols) {
	return position.row > 0 && position.row <= maxRows && position.col > 0 && position.col <= maxCols;
}

// Widget direction from position
typedef NS_OPTIONS(NSUInteger, HSWidgetDirection) {
	HSWidgetDirectionNone = 0,
	HSWidgetDirectionLeft = 1 << 0,
	HSWidgetDirectionUp = 1 << 1,
	HSWidgetDirectionRight = 1 << 2,
	HSWidgetDirectionDown = 1 << 3
};

static inline BOOL HSWidgetPositionIsAdjacent(HSWidgetPosition first, HSWidgetDirection direction, HSWidgetPosition second) {
	if ((direction & HSWidgetDirectionLeft) > 0) {
		return first.row == second.row && first.col - 1 == second.col;
	} else if ((direction & HSWidgetDirectionUp) > 0) {
		return first.row - 1 == second.row && first.col == second.col;
	} else if ((direction & HSWidgetDirectionRight) > 0) {
		return first.row == second.row && first.col + 1 == second.col;
	} else if ((direction & HSWidgetDirectionDown) > 0) {
		return first.row + 1 == second.row && first.col == second.col;
	}
	return NO;
}

static inline HSWidgetPosition HSWidgetPositionInDirection(HSWidgetPosition position, HSWidgetDirection direction) {
	HSWidgetPosition widgetPosition = position;
	if ((direction & HSWidgetDirectionLeft) > 0) {
		widgetPosition.col = position.col - 1;
	}
	if ((direction & HSWidgetDirectionRight) > 0) {
		widgetPosition.col = position.col + 1;
	}
	if ((direction & HSWidgetDirectionUp) > 0) {
		widgetPosition.row = position.row - 1;
	}
	if ((direction & HSWidgetDirectionDown) > 0) {
		widgetPosition.row = position.row + 1;
	}
	return widgetPosition;
}

static inline HSWidgetDirection HSWidgetReverseDirection(HSWidgetDirection direction) {
	HSWidgetDirection widgetDirection = HSWidgetDirectionNone;
	if ((direction & HSWidgetDirectionLeft) > 0) {
		widgetDirection |= HSWidgetDirectionRight;
	}
	if ((direction & HSWidgetDirectionRight) > 0) {
		widgetDirection |= HSWidgetDirectionLeft;
	}
	if ((direction & HSWidgetDirectionUp) > 0) {
		widgetDirection |= HSWidgetDirectionDown;
	}
	if ((direction & HSWidgetDirectionDown) > 0) {
		widgetDirection |= HSWidgetDirectionUp;
	}
	return widgetDirection;
}

// Widget size
typedef struct HSWidgetSize {
	NSUInteger numRows;
	NSUInteger numCols;
} HSWidgetSize;

extern const HSWidgetSize HSWidgetSizeZero;

static inline HSWidgetSize HSWidgetSizeMake(NSUInteger numRows, NSUInteger numCols) {
	HSWidgetSize widgetSize;
	widgetSize.numRows = numRows;
	widgetSize.numCols = numCols;
	return widgetSize;
}

static inline BOOL HSWidgetSizeEqualsSize(HSWidgetSize first, HSWidgetSize second) {
	return first.numRows == second.numRows && first.numCols == second.numCols;
}

static inline HSWidgetSize HSWidgetSizeAdd(HSWidgetSize size, NSInteger numRows, NSInteger numCols) {
	HSWidgetSize widgetSize;
	widgetSize.numRows = size.numRows + numRows;
	widgetSize.numCols = size.numCols + numCols;
	return widgetSize;
}

static inline NSUInteger SpacesForWidgetSize(HSWidgetSize size) {
	return size.numRows * size.numCols;
}

// Widget frame (grid position/size)
typedef struct HSWidgetFrame {
	HSWidgetPosition origin;
	HSWidgetSize size;
} HSWidgetFrame;

extern const HSWidgetFrame HSWidgetFrameZero;

static inline HSWidgetFrame HSWidgetFrameMake(NSUInteger row, NSUInteger col, NSUInteger numRows, NSUInteger numCols) {
	HSWidgetFrame widgetFrame;
	widgetFrame.origin.row = row;
	widgetFrame.origin.col = col;
	widgetFrame.size.numRows = numRows;
	widgetFrame.size.numCols = numCols;
	return widgetFrame;
}

#ifdef __cplusplus
static inline HSWidgetFrame HSWidgetFrameMake(HSWidgetPosition origin, HSWidgetSize size) {
	HSWidgetFrame widgetFrame;
	widgetFrame.origin = origin;
	widgetFrame.size = size;
	return widgetFrame;
}
#endif

static inline BOOL HSWidgetFrameContainsPosition(HSWidgetFrame frame, HSWidgetPosition position) {
	BOOL isRowInFrame = position.row >= frame.origin.row && position.row < frame.origin.row + frame.size.numRows;
	BOOL isColInFrame = position.col >= frame.origin.col && position.col < frame.origin.col + frame.size.numCols;
	return isRowInFrame && isColInFrame;
}

static inline BOOL HSWidgetFrameEqualsFrame(HSWidgetFrame first, HSWidgetFrame second) {
	return HSWidgetPositionEqualsPosition(first.origin, second.origin) && HSWidgetSizeEqualsSize(first.size, second.size);
}
