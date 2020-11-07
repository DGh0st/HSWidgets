#import "HSTodayWidgetController.h"
#import "NSExtension.h"
#import "WGWidgetDiscoveryController.h"
#import "WGWidgetHostingViewController.h"
#import "WGWidgetHostingViewControllerDelegate.h"
#import "WGWidgetHostingViewControllerHost.h"
#import "WGWidgetInfo.h"

#define WIDGET_REQUESTER_ID @"HSTodayWidgetRequesterID"

@interface NSObject ()
-(id)safeValueForKey:(NSString *)key;
@end

@implementation HSTodayWidgetController
+(instancetype)sharedInstance {
	static HSTodayWidgetController *_sharedController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedController = [[HSTodayWidgetController alloc] init];
	});
	return _sharedController;
}

-(instancetype)init {
	self = [super init];
	if (self != nil) {
		self.widgetDiscoveryController = [[%c(WGWidgetDiscoveryController) alloc] init];
		[self.widgetDiscoveryController beginDiscovery];
		[self.widgetDiscoveryController addDiscoveryObserver:self];

		self.cancelTouchesAssertionsByWidgetID = [NSMutableDictionary dictionary];
	}
	return self;
}

-(NSUInteger)availableWidgetsCount {
	return [[self availableWidgetIdentifiersToWidgetInfos] allKeys].count;
}

-(NSDictionary *)availableWidgetIdentifiersToWidgetInfos {
	[self.widgetDiscoveryController beginDiscovery];

	NSMutableDictionary *_identifiersToWidgetInfos = [NSMutableDictionary dictionaryWithDictionary:[self.widgetDiscoveryController valueForKey:@"_identifiersToWidgetInfos"]];
	for (NSString *widgetIdentifier in [self _enabledWidgetIdsToWidgets]) {
		[_identifiersToWidgetInfos removeObjectForKey:widgetIdentifier];
	}
	return [NSDictionary dictionaryWithDictionary:_identifiersToWidgetInfos];
}

-(void)removeWidgetWithIdentifier:(NSString *)widgetIdentifier {
	[[self _enabledWidgetIdsToWidgets] removeObjectForKey:widgetIdentifier];
}

-(WGWidgetHostingViewController *)widgetWithIdentifier:(NSString *)identifier delegate:(id<WGWidgetHostingViewControllerDelegate>)delegate host:(id<WGWidgetHostingViewControllerHost>)host {
	[self.widgetDiscoveryController beginDiscovery];

	WGWidgetHostingViewController *widgetHostingViewController = [self.widgetDiscoveryController widgetWithIdentifier:identifier delegate:delegate forRequesterWithIdentifier:WIDGET_REQUESTER_ID];
	if (widgetHostingViewController == nil) {
		NSExtension *widgetExtension = [%c(NSExtension) extensionWithIdentifier:identifier error:nil];
		WGWidgetInfo *widgetInfo = [%c(WGWidgetInfo) widgetInfoWithExtension:widgetExtension];
		if ([%c(WGCalendarWidgetInfo) isCalendarExtension:widgetExtension] && [widgetInfo respondsToSelector:@selector(_setDate:)]) {
			[(WGCalendarWidgetInfo *)widgetInfo _setDate:[NSDate date]];
		}
		widgetHostingViewController = [[%c(WGWidgetHostingViewController) alloc] initWithWidgetInfo:widgetInfo delegate:delegate host:host];

		[[self _enabledWidgetIdsToWidgets] setObject:widgetHostingViewController forKey:identifier];
		return [widgetHostingViewController autorelease];
	} else {
		widgetHostingViewController.host = host;
		return widgetHostingViewController;
	}
}

-(void)enumerateWidgetsWithBlock:(void(^)(HSTodayWidgetController *, WGWidgetHostingViewController *))block {
	NSMutableDictionary *_enabledWidgetIdsToWidgets = [[HSTodayWidgetController sharedInstance] _enabledWidgetIdsToWidgets];
	for (NSString *widgetIdentifier in _enabledWidgetIdsToWidgets) {
		WGWidgetHostingViewController *hostingViewController = _enabledWidgetIdsToWidgets[widgetIdentifier];
		block(self, hostingViewController);
	}
}

-(NSMutableDictionary *)_enabledWidgetIdsToWidgets {
	NSMutableDictionary *widgetIdsToWidgets = nil;
	if ([self.widgetDiscoveryController respondsToSelector:@selector(_widgetIDsToWidgets)]) {
		widgetIdsToWidgets = [self.widgetDiscoveryController _widgetIDsToWidgets];
	} else if ([self.widgetDiscoveryController safeValueForKey:@"_widgetIDsToWidgets"]){ 
		widgetIdsToWidgets = [self.widgetDiscoveryController safeValueForKey:@"_widgetIDsToWidgets"];
	} else if ([self.widgetDiscoveryController safeValueForKey:@"_requesterIDsToWidgetIDsToWidgets"]) {
		widgetIdsToWidgets = ((NSMutableDictionary *)[self.widgetDiscoveryController safeValueForKey:@"_requesterIDsToWidgetIDsToWidgets"])[WIDGET_REQUESTER_ID];
	}
	return widgetIdsToWidgets;
}

-(void)dealloc {
	[self.widgetDiscoveryController removeDiscoveryObserver:self];
	[self.widgetDiscoveryController release];
	self.widgetDiscoveryController = nil;

	[super dealloc];
}
@end