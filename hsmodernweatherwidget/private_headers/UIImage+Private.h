@interface UIImage (Private)
+(instancetype)_applicationIconImageForBundleIdentifier:(NSString *)identifier format:(int)format scale:(CGFloat)scale; // iOS 5 - 13
@end