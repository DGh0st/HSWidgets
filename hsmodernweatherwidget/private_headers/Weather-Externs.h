@class WACurrentForecast, WFAirQualityConditions;

FOUNDATION_EXPORT NSString *const kCityNotificationNameDidUpdate; // iOS 10 - 13

FOUNDATION_EXPORT BOOL WAIsChinaSKUAndSimplifiedChinese(); // iOS 11 - 13
FOUNDATION_EXPORT NSString *WAConditionsLineStringFromCurrentForecasts(WACurrentForecast *currentForecast); // iOS 10 - 13
FOUNDATION_EXPORT UIImage *WAImageForLegacyConditionCode(int conditionCode); // iOS 10 - 13
