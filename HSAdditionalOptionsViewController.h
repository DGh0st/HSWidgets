@protocol HSAddWidgetAdditionalOptionsDelegate
-(void)_dismissAddWidget;
-(void)_addWidgetForClass:(Class)widgetClass withAdditionalOptionsViewContorller:(id)additionalOptionsViewController;
@end

@interface HSAdditionalOptionsViewController : UIViewController {
	Class _widgetClass;
}
@property (nonatomic, retain) id<HSAddWidgetAdditionalOptionsDelegate> delegate;
-(id)initWithDelegate:(id<HSAddWidgetAdditionalOptionsDelegate>)delegate withWidgetsOptionsToExclude:(NSArray *)optionsToExclude;
-(void)_setWidgetClass:(Class)widgetClass;
-(void)cancelWidget;
-(void)addWidget;
@end