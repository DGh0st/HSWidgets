struct HSWidgetPosition;

// One of SpringBoard structs (iOS 7 - 13)
typedef struct SBIconCoordinate {
	NSInteger row;
	NSInteger col;
} SBIconCoordinate;

#define SBIconCoordinateInvalid -1

static inline SBIconCoordinate SBIconCoordinateMake(NSInteger row, NSInteger col) {
	SBIconCoordinate iconCoordinate;
	iconCoordinate.row = row;
	iconCoordinate.col = col;
	return iconCoordinate;
}

#ifdef __cplusplus
static inline SBIconCoordinate SBIconCoordinateMake(HSWidgetPosition position) {
	SBIconCoordinate iconCoordinate;
	iconCoordinate.row = position.row;
	iconCoordinate.col = position.col;
	return iconCoordinate;
}

static inline HSWidgetPosition HSWidgetPositionMake(SBIconCoordinate iconCoordinate) {
	HSWidgetPosition position;
	position.row = iconCoordinate.row;
	position.col = iconCoordinate.col;
	return position;
}
#endif
