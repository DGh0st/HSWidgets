@protocol CCUIContentModuleContextDelegate;

@interface CCUIContentModuleContext : NSObject
@property (assign, nonatomic, weak) id<CCUIContentModuleContextDelegate> delegate;
-(instancetype)initWithModuleIdentifier:(id)identifier;
@end
