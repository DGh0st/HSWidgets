typedef struct CCUILayoutSize {
	NSUInteger width;
	NSUInteger height;
} CCUILayoutSize;

static inline CCUILayoutSize CCUILayoutSizeMake(NSUInteger width, NSUInteger height) {
	CCUILayoutSize layoutSize;
	layoutSize.width = width;
	layoutSize.height = height;
	return layoutSize;
}
