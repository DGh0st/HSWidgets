#import "SBRootSettings.h"

@interface SBPrototypeController : NSObject // iOS 7 - 13
+(id)sharedInstance; // iOS 7 - 13
-(SBRootSettings *)rootSettings; // iOS 7 - 13
@end
