INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = HSCustomWidget
HSCustomWidget_FILES = HSCustomWidgetViewController.mm HSCustomWidgetPreferencesViewController.mm 
HSCustomWidget_FRAMEWORKS = UIKit
HSCustomWidget_EXTRA_FRAMEWORKS = HSWidgets
HSCustomWidget_PRIVATE_FRAMEWORKS = Preferences
HSCustomWidget_INSTALL_PATH = /Library/HSWidgets
HSCustomWidget_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

