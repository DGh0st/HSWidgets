__attribute__((visibility("hidden")))
@interface HSWidgetLoader : NSObject
+(NSMutableArray<Class> *)availableHSWidgetClasses;
+(void)loadAllWidgets;
+(void)unloadAllWidgets;
@end
