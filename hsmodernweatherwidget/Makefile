include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = HSModernWeatherWidget
HSModernWeatherWidget_FILES = HSModernWeatherWidgetViewController.x HSModernWeatherHourlyForecastView.m HSModernWeatherDailyForecastView.m HSWeatherController.mm
HSModernWeatherWidget_FRAMEWORKS = CoreLocation UIKit
HSModernWeatherWidget_EXTRA_FRAMEWORKS = HSWidgets
HSModernWeatherWidget_PRIVATE_FRAMEWORKS = Weather WeatherFoundation WeatherUI
HSModernWeatherWidget_INSTALL_PATH = /Library/HSWidgets
HSModernWeatherWidget_CFLAGS += -Iprivate_headers

include $(THEOS_MAKE_PATH)/bundle.mk
