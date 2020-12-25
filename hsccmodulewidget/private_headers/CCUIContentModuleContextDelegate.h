@protocol CCUIContentModuleContextDelegate <NSObject>
@required
-(void)contentModuleContext:(id)context enqueueStatusUpdate:(id)status;
-(void)requestExpandModuleForContentModuleContext:(id)context;
-(void)dismissExpandedViewForContentModuleContext:(id)context;
@end
