#import "HSCCModuleController.h"

#import <dlfcn.h>

// CCSupport compatibility
%hook CCUIModuleInstanceManager
-(CCUIModuleInstance *)instanceForModuleIdentifier:(NSString*)identifier {
	CCUIModuleInstance *moduleInstance = %orig(identifier);
	if (moduleInstance == nil/*|| ![[%c(SBCoverSheetPresentationManager) sharedInstance] isPresented]*/) {
		HSCCModuleController *moduleController = [HSCCModuleController sharedInstance];
		moduleInstance = moduleController.moduleInstanceByIdentifiers[identifier] ?: moduleController.dynamicSizedModuleInstanceByIdentifiers[identifier];

		// if our module controller doesn't have it then we are either requesting the widget settings of dynamic widget for first time or we are about to crash
		/*if (moduleInstance == nil) {
			NSString *reason = [NSString stringWithFormat:@"Failed to load module with %@, CCSupport 1.2.3+ is required if using along side HSWidgets", identifier];
			@throw [NSException exceptionWithName:@"HSCCModuleUnableToLoadModuleException" reason:reason userInfo:@{ @"Identifier" : identifier }];
		}*/
	}
	return moduleInstance;
}
%end

%ctor {
	if (dlopen("/Library/MobileSubstrate/DynamicLibraries/CCSupport.dylib", RTLD_NOW) != NULL) {
		%init();
	}
}