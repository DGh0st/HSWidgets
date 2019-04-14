include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HSSpacerWidget
HSSpacerWidget_FILES = HSSpacerWidgetViewController.xm
HSSpacerWidget_FRAMEWORKS = UIKit
HSSpacerWidget_LIBRARIES = HSWidgets
HSSpacerWidget_INSTALL_PATH = /Library/HSWidgets/HSSpacerWidget

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
