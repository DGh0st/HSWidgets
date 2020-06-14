#import "HSWidgetLoader.h"
#import "HSWidgetViewController.h"

#define WIDGETS_INSTALLATION_PATH @"/Library/HSWidgets"

@interface HSWidgetLoader ()
@property (nonatomic, retain) NSMutableArray<Class> *_availableHSWidgetClasses;
@property (nonatomic, retain) NSMutableArray<NSBundle *> *_availableHSWidgetBundles;
@end

@implementation HSWidgetLoader
+(instancetype)sharedLoader {
	static HSWidgetLoader *_sharedLoader = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedLoader = [[HSWidgetLoader alloc] init];
	});
	return _sharedLoader;
}

-(instancetype)init {
	self = [super init];
	self._availableHSWidgetClasses = nil;
	self._availableHSWidgetBundles = nil;
	return self;
}

+(NSMutableArray<Class> *)availableHSWidgetClasses {
	HSWidgetLoader *_sharedLoader = [self sharedLoader];

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// sort them alphabetically by name
		[_sharedLoader._availableHSWidgetClasses sortUsingComparator:^NSComparisonResult(Class firstClass, Class secondClass) {
			if (firstClass == nil || secondClass == nil) {
				return NSOrderedSame;
			}
			NSString *firstName = [firstClass widgetDisplayInfo][HSWidgetDisplayNameKey];
			NSString *secondName = [secondClass widgetDisplayInfo][HSWidgetDisplayNameKey];
			if (firstName == nil || secondName == nil) {
				return NSOrderedSame;
			}
			return [firstName compare:secondName];
		}];
	});

	return _sharedLoader._availableHSWidgetClasses;
}

+(void)loadAllWidgets {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	NSArray *widgetsDirectories = [fileManager contentsOfDirectoryAtPath:WIDGETS_INSTALLATION_PATH error:&error];
	if (error != nil) {
		return;
	}

	HSWidgetLoader *_sharedLoader = [self sharedLoader];

	_sharedLoader._availableHSWidgetClasses = [NSMutableArray arrayWithCapacity:4];
	_sharedLoader._availableHSWidgetBundles = [NSMutableArray arrayWithCapacity:4];
	for (NSString *widgetDirectoryName in widgetsDirectories) {
		NSString *widgetDirectoryPath = [WIDGETS_INSTALLATION_PATH stringByAppendingPathComponent:widgetDirectoryName];
		NSBundle *widgetBundle = [NSBundle bundleWithPath:widgetDirectoryPath];
		BOOL isWidgetBundleLoaded = [widgetBundle load];

		if (widgetBundle != nil && isWidgetBundleLoaded) {
			Class newWidgetClass = widgetBundle.principalClass;
			if (newWidgetClass != nil) {
				[_sharedLoader._availableHSWidgetClasses addObject:newWidgetClass];
				[_sharedLoader._availableHSWidgetBundles addObject:widgetBundle];
			} else {
				[widgetBundle unload];
			}
		}
	}
}

+(void)unloadAllWidgets {
	HSWidgetLoader *_sharedLoader = [self sharedLoader];
	for (NSBundle *widgetBundle in _sharedLoader._availableHSWidgetBundles) {
		[widgetBundle unload];
	}

	_sharedLoader._availableHSWidgetClasses = nil;
	_sharedLoader._availableHSWidgetBundles = nil;
}

-(void)dealloc {
	self._availableHSWidgetClasses = nil;
	self._availableHSWidgetBundles = nil;

	[super dealloc];
}
@end
