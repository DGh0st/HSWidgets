@class WFTemperature;

@interface WFTemperatureFormatter : NSFormatter // iOS 10 - 13
-(void)setOutputUnit:(int)unit; // iOS 10 - 13
-(void)setIncludeDegreeSymbol:(BOOL)symbolIncluded; // iOS 11 - 13
-(NSString *)stringForObjectValue:(id)value; // iOS 10 - 13
@end
