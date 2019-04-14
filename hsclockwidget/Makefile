include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HSClockWidget
HSClockWidget_FILES = HSClockWidgetViewController.xm
HSClockWidget_FRAMEWORKS = UIKit
HSClockWidget_LIBRARIES = HSWidgets
HSClockWidget_INSTALL_PATH = /Library/HSWidgets/HSClockWidget

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
