@protocol HSWidgetAdditionalOptions;

@protocol HSWidgetAddNewAdditionalOptionsDelegate
-(void)dismissAddWidget;
-(void)additionalOptionsViewController:(id<HSWidgetAdditionalOptions>)additionalOptionsViewController addWidgetForClass:(Class)widgetClass;
@end
