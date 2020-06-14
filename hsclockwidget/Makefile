include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = HSClockWidget
HSClockWidget_FILES = HSClockWidgetViewController.xm HSClockWidgetPreferencesViewController.mm
HSClockWidget_FRAMEWORKS = UIKit
HSClockWidget_EXTRA_FRAMEWORKS = CydiaSubstrate HSWidgets
HSClockWidget_PRIVATE_FRAMEWORKS = Preferences
HSClockWidget_INSTALL_PATH = /Library/HSWidgets
HSClockWidget_CFLAGS = -Iprivate_headers

include $(THEOS_MAKE_PATH)/bundle.mk
