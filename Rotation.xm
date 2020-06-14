#import "HSWidgets-structs.h"
#import "SBIconController.h"
#import "SBIconListModel.h"
#import "SBIconListView.h"
#import "SBRootFolderController.h"

static inline BOOL IsIconLayoutOrientationIndependent() {
	if ([%c(SBIconListView) respondsToSelector:@selector(iconRowsForInterfaceOrientation:)]&& [%c(SBIconListView) respondsToSelector:@selector(iconColumnsForInterfaceOrientation:)]) {
		NSUInteger maxRowsForPortrait = [%c(SBIconListView) iconRowsForInterfaceOrientation:UIInterfaceOrientationPortrait];
		NSUInteger maxRowsForLandscape = [%c(SBIconListView) iconRowsForInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
		NSUInteger maxColsForPortrait = [%c(SBIconListView) iconColumnsForInterfaceOrientation:UIInterfaceOrientationPortrait];
		NSUInteger maxColsForLandscape = [%c(SBIconListView) iconColumnsForInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
		if (maxRowsForPortrait == maxRowsForLandscape && maxColsForPortrait == maxColsForLandscape) {
			return YES;
		}
	} else {
		SBIconController *iconController = [%c(SBIconController) sharedInstance];
		SBRootFolderController *rootFolderController = [iconController _rootFolderController];
		if ([rootFolderController respondsToSelector:@selector(iconModel)]) {
			SBHIconModel *iconModel = [rootFolderController iconModel];
			NSUInteger maxRowsForPortrait = [iconModel maxRowCountForListInRootFolderWithInterfaceOrientation:UIInterfaceOrientationPortrait];
			NSUInteger maxRowsForLandscape = [iconModel maxRowCountForListInRootFolderWithInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
			NSUInteger maxColsForPortrait = [iconModel maxColumnCountForListInRootFolderWithInterfaceOrientation:UIInterfaceOrientationPortrait];
			NSUInteger maxColsForLandscape = [iconModel maxColumnCountForListInRootFolderWithInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
			if (maxRowsForPortrait == maxRowsForLandscape && maxColsForPortrait == maxColsForLandscape) {
				return YES;
			}
		}
	}
	return NO;
}

// disable homescreen rotation if needed
%hook SpringBoard
-(BOOL)homeScreenSupportsRotation { // iOS 8 - 13
	UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
	if (userInterfaceIdiom == UIUserInterfaceIdiomPhone && !IsIconLayoutOrientationIndependent()) {
		return NO;
	}
	return %orig();
}

-(NSInteger)homeScreenRotationStyle { // iOS 8 - 13
	UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
	if (userInterfaceIdiom == UIUserInterfaceIdiomPhone && !IsIconLayoutOrientationIndependent()) {
		return 0;
	}
	return %orig();
}
%end