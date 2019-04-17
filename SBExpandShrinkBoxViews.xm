#define kBundlePath @"/Library/Application Support/HSWidgets/Assets.bundle"

%group iOS11Plus
%subclass SBExpandBoxView : SBXCloseBoxView
+(id)defaultContentImage {
	return [UIImage imageNamed:@"HSExpand" inBundle:[NSBundle bundleWithPath:kBundlePath] compatibleWithTraitCollection:nil];
}
%end

%subclass SBShrinkBoxView : SBXCloseBoxView
+(id)defaultContentImage {
	return [UIImage imageNamed:@"HSShrink" inBundle:[NSBundle bundleWithPath:kBundlePath] compatibleWithTraitCollection:nil];
}
%end
%end

%ctor {
	if (%c(SBXCloseBoxView))
		%init(iOS11Plus);
}