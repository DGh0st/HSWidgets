@protocol WGWidgetHostingViewControllerHost <NSObject> // iOS 10 - 13
@optional
-(NSInteger)userSpecifiedDisplayModeForWidget:(id)arg1; // iOS 10 - 13
-(void)widget:(id)arg1 didChangeUserSpecifiedDisplayMode:(NSInteger)arg2; // iOS 10 - 13
-(NSInteger)largestAvailableDisplayModeForWidget:(id)arg1; // iOS 10 - 13
-(void)widget:(id)arg1 didChangeLargestAvailableDisplayMode:(NSInteger)arg2; // iOS 10 - 13
-(void)widget:(id)arg1 didEncounterProblematicSnapshotAtURL:(id)arg2; // iOS 10 - 13
-(void)widget:(id)arg1 didRemoveSnapshotAtURL:(id)arg2; // iOS 11 - 13
-(BOOL)shouldPurgeArchivedSnapshotsForWidget:(id)arg1; // iOS 10 - 13
-(BOOL)shouldPurgeNonCAMLSnapshotsForWidget:(id)arg1; // iOS 11 - 13
-(BOOL)shouldPurgeNonASTCSnapshotsForWidget:(id)arg1; // iOS 11 - 13
-(BOOL)shouldRemoveSnapshotWhenNotVisibleForWidget:(id)arg1; // iOS 11 - 13
@end
