#import "HSWidgetResources.h"

%group iOS11Plus
%subclass SBExpandBoxView : SBXCloseBoxView
+(id)defaultContentImage {
	return [HSWidgetResources imageNamed:HSWidgetExpandImageName];
}
%end

%subclass SBShrinkBoxView : SBXCloseBoxView
+(id)defaultContentImage {
	return [HSWidgetResources imageNamed:HSWidgetShrinkImageName];
}
%end

%subclass SBSettingsBoxView : SBXCloseBoxView
+(id)defaultContentImage {
	return [HSWidgetResources imageNamed:HSWidgetSettingsImageName];
}
%end
%end

%ctor {
	if (%c(SBXCloseBoxView)) {
		%init(iOS11Plus);
	}
}