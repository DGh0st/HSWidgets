include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = HSTodayWidget
HSTodayWidget_FILES = $(wildcard *.mm *.x)
HSTodayWidget_FRAMEWORKS = UIKit CoreGraphics
HSTodayWidget_EXTRA_FRAMEWORKS = CydiaSubstrate HSWidgets
HSTodayWidget_PRIVATE_FRAMEWORKS = Preferences
HSTodayWidget_INSTALL_PATH = /Library/HSWidgets
HSTodayWidget_CFLAGS = -Iprivate_headers

include $(THEOS_MAKE_PATH)/bundle.mk
