#import "HSModernWeatherDailyForecastView.h"
#import "HSWeatherController.h"

#define FONT_SIZE 14
#define MAX_TEMPERATURE_WIDTH 48
#define IMAGE_SIZE 40

@implementation HSModernWeatherDailyForecastView
-(instancetype)init {
	self = [super init];
	if (self != nil) {
		self.weekDayLabel = [[UILabel alloc] init];
		self.weekDayLabel.text = @"";
		self.weekDayLabel.font = [UIFont systemFontOfSize:FONT_SIZE weight:UIFontWeightMedium];
		self.weekDayLabel.numberOfLines = 1;
		self.weekDayLabel.textAlignment = NSTextAlignmentLeft;
		self.weekDayLabel.textColor = [UIColor whiteColor];
		self.weekDayLabel.backgroundColor = [UIColor clearColor];
		self.weekDayLabel.adjustsFontSizeToFitWidth = YES;
		[self addSubview:self.weekDayLabel];

		self.imageView = [[UIImageView alloc] init];
		self.imageView.image = nil;
		self.imageView.contentMode = UIViewContentModeCenter;
		self.imageView.backgroundColor = [UIColor clearColor];
		[self addSubview:self.imageView];

		self.highTemperatureLabel = [[UILabel alloc] init];
		self.highTemperatureLabel.text = HSWeatherFakeTemperature;
		self.highTemperatureLabel.font = [UIFont systemFontOfSize:FONT_SIZE weight:UIFontWeightMedium];
		self.highTemperatureLabel.numberOfLines = 1;
		self.highTemperatureLabel.textAlignment = NSTextAlignmentRight;
		self.highTemperatureLabel.textColor = [UIColor whiteColor];
		self.highTemperatureLabel.backgroundColor = [UIColor clearColor];
		self.highTemperatureLabel.adjustsFontSizeToFitWidth = YES;
		[self addSubview:self.highTemperatureLabel];

		self.lowTemperatureLabel = [[UILabel alloc] init];
		self.lowTemperatureLabel.text = HSWeatherFakeTemperature;
		self.lowTemperatureLabel.font = [UIFont systemFontOfSize:FONT_SIZE weight:UIFontWeightMedium];
		self.lowTemperatureLabel.numberOfLines = 1;
		self.lowTemperatureLabel.textAlignment = NSTextAlignmentRight;
		self.lowTemperatureLabel.textColor = [UIColor whiteColor];
		self.lowTemperatureLabel.backgroundColor = [UIColor clearColor];
		self.lowTemperatureLabel.adjustsFontSizeToFitWidth = YES;
		[self addSubview:self.lowTemperatureLabel];

		self.weekDayLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.weekDayLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
		[self.weekDayLabel.trailingAnchor constraintEqualToAnchor:self.imageView.leadingAnchor].active = YES;
		[self.weekDayLabel.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
		[self.weekDayLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;

		self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.imageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:-4].active = YES;
		[self.imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:4].active = YES;
		[self.imageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
		[self.imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
		[self.imageView.widthAnchor constraintEqualToConstant:IMAGE_SIZE].active = YES;
		[self.imageView.heightAnchor constraintEqualToConstant:IMAGE_SIZE].active = YES;

		self.highTemperatureLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.highTemperatureLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.imageView.trailingAnchor].active = YES;
		[self.highTemperatureLabel.widthAnchor constraintEqualToConstant:MAX_TEMPERATURE_WIDTH].active = YES;
		[self.highTemperatureLabel.trailingAnchor constraintEqualToAnchor:self.lowTemperatureLabel.leadingAnchor constant:8].active = YES;
		[self.highTemperatureLabel.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
		[self.highTemperatureLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;

		self.lowTemperatureLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.lowTemperatureLabel.widthAnchor constraintEqualToConstant:MAX_TEMPERATURE_WIDTH].active = YES;
		[self.lowTemperatureLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
		[self.lowTemperatureLabel.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
		[self.lowTemperatureLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
	}
	return self;
}
@end
