#import "HSModernWeatherHourlyForecastView.h"

#define FONT_SIZE 14
#define IMAGE_SIZE 40

@implementation HSModernWeatherHourlyForecastView
-(instancetype)init {
	self = [super init];
	if (self != nil) {
		self.timeLabel = [[UILabel alloc] init];
		self.timeLabel.text = @"";
		self.timeLabel.font = [UIFont systemFontOfSize:FONT_SIZE weight:UIFontWeightMedium];
		self.timeLabel.numberOfLines = 1;
		self.timeLabel.textAlignment = NSTextAlignmentCenter;
		self.timeLabel.contentMode = UIViewContentModeBottom;
		self.timeLabel.textColor = [UIColor whiteColor];
		self.timeLabel.backgroundColor = [UIColor clearColor];
		self.timeLabel.adjustsFontSizeToFitWidth = YES;
		[self addSubview:self.timeLabel];

		self.imageView = [[UIImageView alloc] init];
		self.imageView.image = nil;
		self.imageView.contentMode = UIViewContentModeCenter;
		self.imageView.backgroundColor = [UIColor clearColor];
		[self addSubview:self.imageView];

		self.temperatureLabel = [[UILabel alloc] init];
		self.temperatureLabel.text = @"";
		self.temperatureLabel.font = [UIFont systemFontOfSize:FONT_SIZE weight:UIFontWeightMedium];
		self.temperatureLabel.numberOfLines = 1;
		self.temperatureLabel.textAlignment = NSTextAlignmentCenter;
		self.temperatureLabel.contentMode = UIViewContentModeTop;
		self.temperatureLabel.textColor = [UIColor whiteColor];
		self.temperatureLabel.backgroundColor = [UIColor clearColor];
		self.temperatureLabel.adjustsFontSizeToFitWidth = YES;
		[self addSubview:self.temperatureLabel];

		self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.timeLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
		[self.timeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
		[self.timeLabel.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
		[self.timeLabel.bottomAnchor constraintEqualToAnchor:self.imageView.topAnchor constant:6].active = YES;

		self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
		[self.imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
		[self.imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
		[self.imageView.heightAnchor constraintEqualToConstant:IMAGE_SIZE].active = YES;

		self.temperatureLabel.translatesAutoresizingMaskIntoConstraints = NO;
		[self.temperatureLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
		[self.temperatureLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
		[self.temperatureLabel.topAnchor constraintEqualToAnchor:self.imageView.bottomAnchor constant:-6].active = YES;
		[self.temperatureLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
	}
	return self;
}
@end
